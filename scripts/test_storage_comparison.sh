#!/bin/bash
echo "=== 存储空间对比测试 ==="
echo ""
echo "1. 未分区数据"
az storage blob list \
  --account-name lemondata1766854279 \
  --container-name silver \
  --prefix customers/customers.parquet \
  --auth-mode login \
  --query "[].{Name:name, Size:properties.contentLength}" \
  --output table

echo ""

# 分区后的总大小
echo "2. 分区数据"
az storage blob list \
  --account-name lemondata1766854279 \
  --container-name silver \
  --prefix customers_partitioned/ \
  --auth-mode login \
  --query "[].{Name:name, Size:properties.contentLength}" \
  --output table

echo ""

# 计算对比
NON_PART=$(az storage blob list \
  --account-name lemondata1766854279 \
  --container-name silver \
  --prefix customers/customers.parquet \
  --auth-mode login \
  --query "[].properties.contentLength" \
  --output tsv 2>/dev/null | awk '{s+=$1} END {print s}')

PART=$(az storage blob list \
  --account-name lemondata1766854279 \
  --container-name silver \
  --prefix customers_partitioned/ \
  --auth-mode login \
  --query "[].properties.contentLength" \
  --output tsv | awk '{s+=$1} END {print s}')

echo "3. 总大小对比"
echo "未分区: ${NON_PART:-N/A} bytes"
echo "分区后: ${PART} bytes"
