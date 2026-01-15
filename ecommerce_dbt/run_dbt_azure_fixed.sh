#!/bin/bash
set -e 

echo "========================================="
echo "🚀 启动云端 dbt 自动化流水线"
echo "========================================="

# 1. 环境准备
mkdir -p temp_silver_data
mkdir -p target

# 2. 下载数据
echo "Step 1: Downloading Silver data..."
az storage blob download-batch \
    --account-name "$STORAGE_NAME" \
    --source "silver" \
    --destination "./temp_silver_data" \
    --connection-string "$AZURE_STORAGE_CONNECTION_STRING" \
    --pattern "*.parquet" \
    --overwrite true

# 3. 配置 Profile
echo "Step 2: Configuring dbt Profile..."
mkdir -p ~/.dbt
cat > ~/.dbt/profiles.yml << EOF
ecommerce_dbt:
  outputs:
    dev:
      type: duckdb
      path: target/dbt_local.duckdb
      threads: 1
  target: dev
EOF

# 4. 运行 dbt
echo "Step 3: Running dbt..."
dbt run


# 5. 导出为 Gold 格式
echo "Step 4: Exporting to Parquet..."
python3 -c "
import duckdb
con = duckdb.connect('target/dbt_local.duckdb')
# 确保加上 main_marts 前缀，这对应你 dbt 运行出的 schema
con.execute(\"COPY (SELECT * FROM main_marts.customer_summary) TO 'target/customer_summary_gold.parquet' (FORMAT PARQUET);\")
con.execute(\"COPY (SELECT * FROM main_marts.customer_rfm_segments) TO 'target/customer_rfm_segments_gold.parquet' (FORMAT PARQUET);\")
con.execute(\"COPY (SELECT * FROM main_marts.product_performance) TO 'target/product_performance_gold.parquet' (FORMAT PARQUET);\")
"

# 6. 上传回 Azure
echo "Step 5: Uploading to Gold Layer..."
TODAY=$(date +%Y%m%d)
# 注意：在脚本里使用变量名时，GitHub Actions 环境下建议显式引用
az storage blob upload-batch \
    --account-name "$STORAGE_NAME" \
    --destination "gold/$TODAY" \
    --source "target" \
    --pattern "*_gold.parquet" \
    --connection-string "$AZURE_STORAGE_CONNECTION_STRING" \
    --overwrite true

echo "========================================="
echo "✅ 自动化任务全部完成！"
echo "========================================="
