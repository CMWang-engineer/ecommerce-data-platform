#!/bin/bash
set -e

echo "========================================="
echo "Starting dbt run on Azure (SCHEME A - NO PARTITIONS)"
echo "========================================="

WORK_DIR="/tmp/dbt_work"
SILVER_DIR="$WORK_DIR/data/silver"

rm -rf "$WORK_DIR"
mkdir -p "$SILVER_DIR"

echo "Step 1: Download Silver layer (directory-based)"

for table in customers orders order_items products; do
  echo "  → downloading $table"
  az storage blob download-batch \
    --account-name "$AZURE_STORAGE_ACCOUNT" \
    --source silver \
    --destination "$SILVER_DIR/$table" \
    --pattern "$table/*" \
    --auth-mode login \
    --no-progress || echo "  ⚠️ $table download incomplete (allowed)"
done

echo ""
echo "Downloaded structure:"
find "$SILVER_DIR" -maxdepth 2 -type f

echo ""
echo "Step 2: Run dbt"

cd ~/ecommerce-data-platform/ecommerce_dbt

export SILVER_LOCAL_PATH="$SILVER_DIR"

dbt run
dbt test

echo ""
echo "Step 3: Export marts to parquet (ONLY HERE we use parquet)"

duckdb ecommerce_dev.duckdb << SQL
COPY main_marts.customer_summary TO 'target/customer_summary.parquet' (FORMAT PARQUET);
COPY main_marts.customer_rfm_segments TO 'target/customer_rfm_segments.parquet' (FORMAT PARQUET);
COPY main_marts.product_performance TO 'target/product_performance.parquet' (FORMAT PARQUET);
SQL

echo ""
echo "Done."


