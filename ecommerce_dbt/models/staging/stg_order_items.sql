{{
  config(
    materialized='view'
  )
}}

SELECT
    order_item_id,
    order_id,
    product_id,
    quantity,
    CAST(unit_price AS DECIMAL(10,2)) AS unit_price
FROM read_parquet(
    '{{ var("silver_data_path") }}/order_items/*'
)
