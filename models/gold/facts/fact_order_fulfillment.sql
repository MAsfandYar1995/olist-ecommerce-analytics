WITH orders AS (

    SELECT 
        * 
    FROM {{ ref('stg_orders') }}

),

customer_mapping AS (

    SELECT
        customer_id,
        customer_unique_id
    FROM {{ ref('int_customers_enriched') }}

),

customers AS (

    SELECT 
        * 
    FROM {{ ref('dim_customer') }}

),

dates AS (
    
    SELECT 
        * 
    FROM {{ ref('dim_date') }}

),

order_max_shipping_dates AS (

    SELECT 
        order_id,
        MAX(shipping_limit_at::DATE) AS shipping_limit_date
    FROM {{ ref('stg_order_items') }}
    GROUP BY 1

)

SELECT 
    o.order_id,
    o.order_status,

    c.customer_key,

    order_purchase_dates.date_key AS order_purchase_date_key,
    order_approved_dates.date_key AS order_approved_date_key,
    order_delivered_carrier_dates.date_key AS order_delivered_carrier_date_key,
    order_delivered_customer_dates.date_key AS order_delivered_customer_date_key,
    order_estimated_delivery_dates.date_key AS order_estimated_delivery_date_key,
    order_shipping_dates.date_key AS order_latest_shipping_limit_date_key, 

    o.order_approved_date - o.order_purchase_date AS approval_days,
    o.order_delivered_carrier_date - o.order_approved_date AS handoff_days,
    o.order_delivered_carrier_date - order_max_shipping_dates.shipping_limit_date AS shipping_delay_days,
    o.order_delivered_customer_date - o.order_delivered_carrier_date AS delivery_days,
    o.order_delivered_customer_date - o.order_purchase_date AS total_fulfillment_days,
    o.order_delivered_customer_date - o.order_estimated_delivery_date AS delivery_delay_days,

    CASE 
        WHEN o.order_delivered_customer_date IS NULL THEN NULL
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 
        ELSE 0
    END AS on_time_delivery_flag,

    CASE
        WHEN o.order_approved_date - o.order_purchase_date < 0
            OR o.order_delivered_carrier_date - o.order_approved_date < 0
            OR o.order_delivered_customer_date - o.order_delivered_carrier_date < 0
            OR o.order_delivered_customer_date - o.order_purchase_date < 0
            THEN 1
        ELSE 0
    END AS fulfillment_sequence_anomaly_flag

FROM orders o

LEFT JOIN customer_mapping cm
    ON o.customer_id = cm.customer_id

LEFT JOIN customers c
    ON cm.customer_unique_id = c.customer_unique_id

LEFT JOIN dates order_purchase_dates 
    ON order_purchase_dates.date = o.order_purchase_date 

LEFT JOIN dates order_approved_dates 
    ON order_approved_dates.date = o.order_approved_date 

LEFT JOIN dates order_delivered_carrier_dates 
    ON order_delivered_carrier_dates.date = o.order_delivered_carrier_date

LEFT JOIN dates order_delivered_customer_dates 
    ON order_delivered_customer_dates.date = o.order_delivered_customer_date

LEFT JOIN dates order_estimated_delivery_dates 
    ON order_estimated_delivery_dates.date = o.order_estimated_delivery_date

LEFT JOIN order_max_shipping_dates 
    ON order_max_shipping_dates.order_id = o.order_id 

LEFT JOIN dates order_shipping_dates
    ON order_shipping_dates.date = order_max_shipping_dates.shipping_limit_date