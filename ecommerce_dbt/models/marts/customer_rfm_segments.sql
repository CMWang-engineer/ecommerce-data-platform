{{
  config(
    materialized='table'
  )
}}

WITH customer_orders AS (
    SELECT
        customer_id,
        MAX(order_date) AS last_order_date,
        COUNT(DISTINCT order_id) AS frequency
    FROM {{ ref('stg_orders') }}
    GROUP BY customer_id
),

customer_spending AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS monetary
    FROM {{ ref('stg_orders') }} o
    JOIN {{ ref('stg_order_items') }} oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),

customer_metrics AS (
    SELECT
        co.customer_id,
        co.last_order_date,
        co.frequency,
        COALESCE(cs.monetary, 0) AS monetary
    FROM customer_orders co
    LEFT JOIN customer_spending cs
        ON co.customer_id = cs.customer_id
),

rfm_scores AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY last_order_date DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency ASC)       AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary ASC)        AS monetary_score
    FROM customer_metrics
),

rfm_segments AS (
    SELECT
        *,
        recency_score + frequency_score + monetary_score AS rfm_total_score,

        CASE
            WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
            WHEN recency_score >= 4 AND frequency_score <= 2 AND monetary_score >= 3 THEN 'Big Spenders'
            WHEN recency_score >= 4 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'New Customers'
            WHEN recency_score >= 3 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'Promising'
            WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'At Risk'
            WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score >= 3 THEN 'Cant Lose Them'
            WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score <= 2 THEN 'Hibernating'
            ELSE 'Lost Customers'
        END AS rfm_segment
    FROM rfm_scores
)

SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    c.city,
    c.country,

    rfm.recency_score,
    rfm.frequency_score,
    rfm.monetary_score,
    rfm.rfm_total_score,
    rfm.rfm_segment,

    rfm.last_order_date,
    rfm.frequency AS total_orders,
    rfm.monetary AS total_spent,

    CURRENT_TIMESTAMP AS dbt_updated_at

FROM {{ ref('stg_customers') }} c
JOIN rfm_segments rfm
    ON c.customer_id = rfm.customer_id

