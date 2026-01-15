{{
  config(
    materialized='table'
  )
}}

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS total_orders,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date
    FROM {{ ref('stg_orders') }}
    GROUP BY customer_id
),

customer_spending AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS total_spent,
        COUNT(oi.order_item_id) AS total_items_purchased,
        COUNT(DISTINCT oi.product_id) AS unique_products_purchased
    FROM {{ ref('stg_orders') }} o
    JOIN {{ ref('stg_order_items') }} oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
)

SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    c.city,
    c.country,
    c.registration_date,

    COALESCE(co.total_orders, 0) AS total_orders,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COALESCE(cs.total_spent / NULLIF(co.total_orders, 0), 0) AS avg_order_value,

    COALESCE(cs.total_items_purchased, 0) AS total_items_purchased,
    COALESCE(cs.unique_products_purchased, 0) AS unique_products_purchased,

    co.first_order_date,
    co.last_order_date,
    DATE_DIFF('day', co.last_order_date, CURRENT_DATE) AS days_since_last_order,
    DATE_DIFF('day', co.first_order_date, co.last_order_date) AS customer_lifetime_days,

    CASE
        WHEN co.total_orders IS NULL THEN 'Never Ordered'
        WHEN DATE_DIFF('day', co.last_order_date, CURRENT_DATE) > 180 THEN 'Churned'
        WHEN DATE_DIFF('day', co.last_order_date, CURRENT_DATE) > 90 THEN 'At Risk'
        WHEN co.total_orders >= 10 THEN 'VIP'
        WHEN co.total_orders >= 5 THEN 'Loyal'
        ELSE 'Active'
    END AS customer_status,

    CURRENT_TIMESTAMP AS dbt_updated_at

FROM {{ ref('stg_customers') }} c
LEFT JOIN customer_orders co ON c.customer_id = co.customer_id
LEFT JOIN customer_spending cs ON c.customer_id = cs.customer_id




