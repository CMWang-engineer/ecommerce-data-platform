#!/bin/bash
# Azure成本检查脚本
# 用途：查询ecommerce-data-platform项目的日常成本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量（从环境变量或手动设置）
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-ecommerce-data-platform}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"

echo -e "${BLUE}=== Azure成本检查工具 ===${NC}"
echo "Resource Group: $RESOURCE_GROUP"
echo "Subscription: $SUBSCRIPTION_ID"
echo ""

# 检查az cli是否已登录
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ 错误：未登录Azure CLI${NC}"
    echo "请先运行: az login"
    exit 1
fi

# 方法1：使用Cost Management查询（最准确，但可能有延迟）
echo -e "${YELLOW}=== 方法1: Cost Management API（最近30天）===${NC}"

# 获取日期范围
END_DATE=$(date -u +"%Y-%m-%dT23:59:59Z")
START_DATE=$(date -u -d "30 days ago" +"%Y-%m-%dT00:00:00Z" 2>/dev/null || date -u -v-30d +"%Y-%m-%dT00:00:00Z")

echo "查询时间范围: $START_DATE 到 $END_DATE"
echo ""

# 查询成本（按Resource Group过滤）
COST_QUERY=$(cat <<EOF
{
  "type": "ActualCost",
  "timeframe": "Custom",
  "timePeriod": {
    "from": "$START_DATE",
    "to": "$END_DATE"
  },
  "dataset": {
    "granularity": "Daily",
    "aggregation": {
      "totalCost": {
        "name": "Cost",
        "function": "Sum"
      }
    },
    "grouping": [
      {
        "type": "Dimension",
        "name": "ResourceGroup"
      }
    ],
    "filter": {
      "dimensions": {
        "name": "ResourceGroup",
        "operator": "In",
        "values": ["$RESOURCE_GROUP"]
      }
    }
  }
}
EOF
)

# 执行查询
echo "正在查询成本数据..."
COST_RESULT=$(az costmanagement query \
  --type "ActualCost" \
  --dataset-aggregation totalCost='{"name":"Cost","function":"Sum"}' \
  --dataset-grouping name="ResourceGroup" type="Dimension" \
  --timeframe "Custom" \
  --time-period from="$START_DATE" to="$END_DATE" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" 2>/dev/null || echo "")

if [ -n "$COST_RESULT" ]; then
  echo -e "${GREEN}✅ 查询成功${NC}"
  echo "$COST_RESULT" | jq -r '.rows[] | @tsv' | while IFS=$'\t' read -r cost date name; do
    echo "  $date | $name | $${cost}"
  done
  
  # 计算总成本
  TOTAL_COST=$(echo "$COST_RESULT" | jq '[.rows[][0]] | add')
  echo ""
  echo -e "${GREEN}总成本（最近30天）: \$${TOTAL_COST}${NC}"
else
  echo -e "${YELLOW}⚠️  Cost Management API暂时无法查询（数据可能还在处理）${NC}"
fi

echo ""
echo "---"
echo ""

# 方法2：查看Resource Group的所有资源（估算）
echo -e "${YELLOW}=== 方法2: 按资源类型统计 ===${NC}"
echo ""

# 列出所有资源
RESOURCES=$(az resource list \
  --resource-group $RESOURCE_GROUP \
  --query "[].{name:name, type:type, location:location}" \
  --output json)

echo "当前资源清单："
echo "$RESOURCES" | jq -r '.[] | "\(.type) | \(.name)"'

echo ""
echo "资源类型统计："
echo "$RESOURCES" | jq -r '.[].type' | sort | uniq -c | sort -rn

echo ""
echo "---"
echo ""

# 方法3：估算每日成本（基于已知定价）
echo -e "${YELLOW}=== 方法3: 成本估算 ===${NC}"
echo ""

# Storage Account
STORAGE_COUNT=$(echo "$RESOURCES" | jq '[.[] | select(.type=="Microsoft.Storage/storageAccounts")] | length')
if [ $STORAGE_COUNT -gt 0 ]; then
  echo -e "${BLUE}Storage Accounts: $STORAGE_COUNT${NC}"
  
  # 获取存储总量
  for storage in $(az storage account list -g $RESOURCE_GROUP --query "[].name" -o tsv); do
    echo "  Storage: $storage"
    
    # 查询各容器的存储量
    TOTAL_SIZE=0
    for container in $(az storage container list --account-name $storage --auth-mode login --query "[].name" -o tsv 2>/dev/null || echo ""); do
      if [ -n "$container" ]; then
        SIZE=$(az storage blob list \
          --account-name $storage \
          --container-name $container \
          --auth-mode login \
          --query "sum([].properties.contentLength)" \
          --output tsv 2>/dev/null || echo "0")
        
        SIZE_MB=$(echo "scale=2; $SIZE / 1024 / 1024" | bc)
        echo "    - $container: ${SIZE_MB} MB"
        TOTAL_SIZE=$(echo "$TOTAL_SIZE + $SIZE" | bc)
      fi
    done
    
    TOTAL_GB=$(echo "scale=2; $TOTAL_SIZE / 1024 / 1024 / 1024" | bc)
    echo "  总存储: ${TOTAL_GB} GB"
    
    # LRS Hot tier: $0.0184 per GB/month = ~$0.0006 per GB/day
    STORAGE_COST=$(echo "scale=4; $TOTAL_GB * 0.0006" | bc)
    echo -e "  ${GREEN}估算成本: ~\$${STORAGE_COST}/天${NC}"
  done
fi

echo ""

# Data Factory
ADF_COUNT=$(echo "$RESOURCES" | jq '[.[] | select(.type=="Microsoft.DataFactory/factories")] | length')
if [ $ADF_COUNT -gt 0 ]; then
  echo -e "${BLUE}Data Factory: $ADF_COUNT${NC}"
  
  # 查询最近的Pipeline运行
  for adf in $(az resource list -g $RESOURCE_GROUP --resource-type "Microsoft.DataFactory/factories" --query "[].name" -o tsv); do
    echo "  ADF: $adf"
    
    # 最近7天的运行次数
    RUNS=$(az datafactory pipeline-run query-by-factory \
      --factory-name $adf \
      --resource-group $RESOURCE_GROUP \
      --last-updated-after "$(date -u -d '7 days ago' +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-7d +"%Y-%m-%dT%H:%M:%SZ")" \
      --query "length(value[?status=='Succeeded'])" \
      --output tsv 2>/dev/null || echo "0")
    
    echo "    - 最近7天成功运行: $RUNS 次"
    
    # 估算成本（非常粗略）
    # Orchestration: $1 per 1000 runs
    # Data Flow (假设每次10分钟，4 cores): ~$0.25 per run
    ORCH_COST=$(echo "scale=4; $RUNS * 0.001" | bc)
    DATAFLOW_COST=$(echo "scale=4; $RUNS * 0.25" | bc)
    TOTAL_ADF=$(echo "$ORCH_COST + $DATAFLOW_COST" | bc)
    
    echo -e "    ${GREEN}估算成本（7天）: ~\$${TOTAL_ADF}${NC}"
    
    DAILY_ADF=$(echo "scale=4; $TOTAL_ADF / 7" | bc)
    echo -e "    ${GREEN}日均成本: ~\$${DAILY_ADF}${NC}"
  done
fi

echo ""

# Event Hubs
EVENTHUB_COUNT=$(echo "$RESOURCES" | jq '[.[] | select(.type=="Microsoft.EventHub/namespaces")] | length')
if [ $EVENTHUB_COUNT -gt 0 ]; then
  echo -e "${BLUE}Event Hubs: $EVENTHUB_COUNT${NC}"
  
  for eh in $(az resource list -g $RESOURCE_GROUP --resource-type "Microsoft.EventHub/namespaces" --query "[].name" -o tsv); do
    SKU=$(az eventhubs namespace show -n $eh -g $RESOURCE_GROUP --query "sku.name" -o tsv)
    echo "  Event Hub: $eh (SKU: $SKU)"
    
    # Basic: $0.015/hour = $0.36/day
    if [ "$SKU" = "Basic" ]; then
      echo -e "    ${GREEN}估算成本: ~\$0.36/天${NC}"
    fi
  done
fi

echo ""

# SQL Database（如果有）
SQL_COUNT=$(echo "$RESOURCES" | jq '[.[] | select(.type=="Microsoft.Sql/servers")] | length')
if [ $SQL_COUNT -gt 0 ]; then
  echo -e "${BLUE}SQL Databases: $SQL_COUNT${NC}"
  echo "  （暂未创建，Day 12-13才会创建）"
fi

echo ""
echo "---"
echo ""

# 方法4：Azure Advisor成本建议
echo -e "${YELLOW}=== 方法4: Azure Advisor成本优化建议 ===${NC}"
echo ""

RECOMMENDATIONS=$(az advisor recommendation list \
  --category Cost \
  --query "[?resourceGroup=='$RESOURCE_GROUP'].{impact:impact, problem:shortDescription.problem, solution:shortDescription.solution}" \
  --output json 2>/dev/null || echo "[]")

RECO_COUNT=$(echo "$RECOMMENDATIONS" | jq 'length')

if [ "$RECO_COUNT" -gt 0 ]; then
  echo -e "${YELLOW}发现 $RECO_COUNT 个成本优化建议：${NC}"
  echo "$RECOMMENDATIONS" | jq -r '.[] | "  • [\(.impact)] \(.problem)\n    → \(.solution)\n"'
else
  echo -e "${GREEN}✅ 没有成本优化建议（配置良好）${NC}"
fi

echo ""
echo "---"
echo ""

# 总结
echo -e "${BLUE}=== 成本总结 ===${NC}"
echo ""
echo "💡 提示："
echo "  - Cost Management数据通常有24-48小时延迟"
echo "  - 准确成本请查看Azure Portal → Cost Management"
echo "  - 估算成本仅供参考"
echo ""
echo "🔗 查看详细成本："
echo "  https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/overview"
echo ""
echo "📊 Cost Analysis（按资源）："
echo "  https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/costanalysis"
echo ""

# 如果有jq和bc，计算预算状态
BUDGET_LIMIT=100  # 假设$100预算
echo -e "${YELLOW}预算警告阈值: \$${BUDGET_LIMIT}${NC}"
echo ""

echo -e "${GREEN}✅ 成本检查完成${NC}"
