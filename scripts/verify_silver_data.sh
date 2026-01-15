#!/bin/bash
set -e

echo "=============================================="
echo "验证 Silver 层分区数据结构"
echo "=============================================="

echo ""
echo "1. 查找任意一个 Silver 数据文件..."

SAMPLE_FILE=$(az storage blob list \
  --account-name $STORAGE_NAME \
  --container-name silver \
  --prefix customers_partitioned/ \
  --auth-mode login \
  --query "[?properties.contentLength > \`0\`].name | [0]" \
  --output tsv)

if [ -z "$SAMPLE_FILE" ]; then
    echo "   ❌ 未找到任何 Silver 数据文件（contentLength > 0）"
    exit 1
fi

echo "   ✅ 找到样本文件: $SAMPLE_FILE"

echo ""
echo "2. 下载样本数据文件..."

az storage blob download \
  --account-name $STORAGE_NAME \
  --container-name silver \
  --name "$SAMPLE_FILE" \
  --file /tmp/test_customer.parquet \
  --auth-mode login \
  --output none

echo ""
echo "3. 验证数据文件可被 DuckDB 正确读取..."

python3 << 'PYTHON'
import duckdb

con = duckdb.connect()
try:
    con.execute("""
        SELECT *
        FROM read_parquet('/tmp/test_customer.parquet')
        LIMIT 1
    """)
    print("   ✅ 数据文件可被 DuckDB 正确读取")
except Exception as e:
    raise SystemExit(f"❌ DuckDB 无法读取数据文件: {e}")
PYTHON


echo ""
echo "=============================================="
echo "✅ Day 10 Silver 分区数据验证全部通过"
echo "=============================================="
EOF

