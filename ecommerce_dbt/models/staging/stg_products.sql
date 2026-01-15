{{
  config(
    materialized='view'
  )
}}

SELECT
    product_id,
    product_name,
    category,
    CAST(price AS DECIMAL(10,2)) AS price,
    stock_quantity
FROM read_parquet(
    '{{ var("silver_data_path") }}/products/*'
)
