{{
  config(
    materialized='view'
  )
}}

SELECT
    customer_id,
    first_name,
    last_name,
    email,
    city,
    country,
    CAST(registration_date AS DATE) AS registration_date
FROM read_parquet(
    '{{ var("silver_data_path") }}/customers/*'
)
