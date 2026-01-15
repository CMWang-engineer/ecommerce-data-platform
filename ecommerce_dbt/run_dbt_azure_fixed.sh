#!/bin/bash

echo "========================================="
echo "Starting dbt run on Azure (CLOUD SAFE)"
echo "========================================="

# 1. 准备本地数据目录
mkdir -p temp_silver_data

# 2. 从 Azure 下载数据
# 注意：我们直接下载整个 silver 容器下的所有 parquet
echo "Step 1: Downloading data from Azure..."
az storage blob download-batch \
    --account-name "$STORAGE_NAME" \
    --source "silver" \
    --destination "./temp_silver_data" \
    --connection-string "$AZURE_STORAGE_CONNECTION_STRING" \
    --pattern "*.parquet" \
    --overwrite true

# 3. 动态生成 profiles.yml (解决找不到 profile 的问题)
# 这一步是云端运行的关键！
echo "Step 2: Generating temporary dbt profile..."
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
# 确保在当前目录下运行，不再 cd
dbt run
