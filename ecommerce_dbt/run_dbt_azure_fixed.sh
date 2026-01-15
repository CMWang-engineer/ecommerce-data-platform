#!/bin/bash
set -e

STORAGE_NAME="lemondata1766854279"
CONTAINER_NAME="silver"
LOCAL_DIR="./temp_silver_data"

echo "========================================="
echo "Starting dbt run on Azure (FIXED VERSION)"
echo "========================================="

echo "Step 1: Download Silver layer with directory creation"

# 清理并创建本地目录结构
rm -rf "$LOCAL_DIR"
mkdir -p "$LOCAL_DIR"/{customers,orders,order_items,products}

# 下载函数
download_table() {
    local table=$1
    local dest_dir="$LOCAL_DIR/$table"
    
    echo "  → downloading $table"
    
    # 确保目标目录存在
    mkdir -p "$dest_dir"
    
    
    # 方案B: 分区结构
    az storage blob download-batch \
        --account-name "$STORAGE_NAME" \
        --source "$CONTAINER_NAME" \
        --destination "$dest_dir" \
        --pattern "${table}/*.parquet" \
        --auth-mode login 2>/dev/null || true
   
    
    file_count=$(find "$dest_dir" -name "*.parquet" | wc -l)
    if [ "$file_count" -gt 0 ]; then
        echo "  ✅ $table: $file_count parquet files downloaded"
    else
        echo "  ⚠️  $table: no files found"
    fi
}

# 下载所有表
download_table "customers"
download_table "orders"
download_table "order_items"
download_table "products"

echo ""
echo "Step 2: Configure dbt to use downloaded data"

# 关键修正：确保内部的 EOF 前后没有空格
mkdir -p ~/.dbt
cat > ~/.dbt/profiles_temp.yml << INNER_EOF
ecommerce_dbt:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: './target/dbt_local.duckdb'
      threads: 4
      extensions:
        - parquet
INNER_EOF

echo "Step 3: Run dbt with fixed model"

# 逻辑：如果当前就在 ecommerce_dbt 文件夹里，就直接跑；
# 如果不在，但看到有这个文件夹，就进去再跑。
if [[ "$PWD" == */ecommerce_dbt ]]; then
    echo "  → Already in ecommerce_dbt directory."
elif [ -d "ecommerce_dbt" ]; then
    echo "  → Moving into ecommerce_dbt directory..."
    cd ecommerce_dbt
fi

dbt run --profiles-dir ~/.dbt --profile ecommerce_dbt --target dev

echo ""
echo "Step 4: Run tests"
dbt test --profiles-dir ~/.dbt --profile ecommerce_dbt --target dev

echo ""
echo "========================================="
echo "✅ dbt run completed successfully!"
echo "========================================="
