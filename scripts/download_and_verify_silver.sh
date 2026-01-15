#!/bin/bash
set -e

echo "=============================================="
echo "Day 10–11 Silver 层数据下载与验证（最终版）"
echo "=============================================="

download_one_table () {
  TABLE_NAME=$1
  PARTITION_PREFIX=$2
  LOCAL_DIR=$3

  echo ""
  echo "▶ 处理表: $TABLE_NAME"

  mkdir -p "$LOCAL_DIR"

  # 1️⃣ 查找任意一个真实存在的数据文件（contentLength > 0）
  SAMPLE_FILE=$(az storage blob list \
    --account-name "$STORAGE_NAME" \
    --container-name silver \
    --prefix "$PARTITION_PREFIX" \
    --auth-mode login \
    --query "[?properties.contentLength > \`0\`].name | [0]" \
    --output tsv)

  if [ -z "$SAMPLE_FILE" ]; then
    echo "❌ 未找到 $TABLE_NAME 的任何数据文件"
    exit 1
  fi

  echo "   ✅ 找到样本文件: $SAMPLE_FILE"

  # 2️⃣ 下载该文件
  LOCAL_FILE="$LOCAL_DIR/$(basename "$SAMPLE_FILE")"

  az storage blob download \
    --account-name "$STORAGE_NAME" \
    --container-name silver \
    --name "$SAMPLE_FILE" \
    --file "$LOCAL_FILE" \
    --auth-mode login \
    --output none

  echo "   ✅ 已下载到: $LOCAL_FILE"

  # 3️⃣ 验证 parquet 可读性
  python3 << PYTHON
import pyarrow.parquet as pq
try:
    pq.read_schema("$LOCAL_FILE")
    print("   ✅ Parquet 文件可正常读取")
except Exception as e:
    raise SystemExit(f"❌ Parquet 文件不可读: {e}")
PYTHON
}

# =========================
# 分表执行（注意 year 范围不同是 OK 的）
# =========================

download_one_table \
  "customers" \
  "customers_partitioned/" \
  "data/silver/customers"

download_one_table \
  "products" \
  "products_partitioned/" \
  "data/silver/products"

download_one_table \
  "orders" \
  "orders_partitioned/" \
  "data/silver/orders"

download_one_table \
  "order_items" \
  "order_items_partitioned/" \
  "data/silver/order_items"

echo ""
echo "=============================================="
echo "✅ Day 10–11 Silver 数据下载与验证全部完成"
echo "=============================================="
