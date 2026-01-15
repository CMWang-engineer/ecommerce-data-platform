{{
  config(
    materialized='view'
  )
}}

SELECT
    order_id,
    customer_id,
    CAST(order_date AS DATE) AS order_date,
    order_status
FROM read_parquet(
    '{{ var("silver_data_path") }}/orders/*'
)
