{{
  config(
    materialized='table'
  )
}}

WITH product_sales AS (
    SELECT
        oi.product_id,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        SUM(oi.quantity) AS total_quantity_sold,
        SUM(oi.quantity * oi.unit_price) AS total_revenue,
        AVG(oi.unit_price) AS avg_selling_price,
        MIN(o.order_date) AS first_sale_date,
        MAX(o.order_date) AS last_sale_date
    FROM {{ ref('stg_order_items') }} oi
    JOIN {{ ref('stg_orders') }} o ON oi.order_id = o.order_id
    GROUP BY oi.product_id
),

product_rankings AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        ROW_NUMBER() OVER (ORDER BY total_quantity_sold DESC) AS quantity_rank,
        ROW_NUMBER() OVER (ORDER BY total_orders DESC) AS popularity_rank
    FROM product_sales
)


SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.price AS current_price,
    p.stock_quantity,
    
    COALESCE(ps.total_orders, 0) AS total_orders,
    COALESCE(ps.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(ps.total_revenue, 0) AS total_revenue,
    COALESCE(ps.avg_selling_price, 0) AS avg_selling_price,
    
    ps.first_sale_date,
    ps.last_sale_date,
    
    ps.revenue_rank,
    ps.quantity_rank,
    ps.popularity_rank,
    
    CASE
        WHEN ps.total_orders IS NULL THEN 'Never Sold'
        WHEN ps.last_sale_date IS NULL THEN 'Never Sold' -- 增加容错
        WHEN DATE_DIFF('day', CAST(ps.last_sale_date AS DATE), CURRENT_DATE) > 90 THEN 'Slow Moving'
        WHEN ps.revenue_rank <= 20 THEN 'Top Seller'
        WHEN ps.total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Regular'
    END AS product_status,
    
    CURRENT_TIMESTAMP AS dbt_updated_at
    
FROM (SELECT DISTINCT * FROM {{ ref('stg_products') }}) p  -- 【关键点：去重】
LEFT JOIN product_rankings ps ON p.product_id = ps.product_id
