WITH order_items AS (

    SELECT 
        * 
    FROM {{ ref('stg_order_items') }}
),

orders AS (

    SELECT 
        * 
    FROM {{ ref('stg_orders') }}
),

products AS (

    SELECT 
        * 
    FROM {{ ref('dim_product') }}
),

sellers AS (

    SELECT 
        * 
    FROM {{ ref('dim_seller') }}
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

)

SELECT
    oi.order_id,
    oi.order_item_id,

    o.order_status,
    
    c2.customer_key,
    p.product_key,
    s.seller_key,
    d.date_key AS order_date_key,

    1 AS quantity,
    price_amount AS item_price,
    freight_value_amount AS freight_amount,
    price_amount + freight_value_amount AS gross_amount
from order_items oi

LEFT JOIN orders o 
    ON oi.order_id = o.order_id

LEFT JOIN customer_mapping c1 
    ON o.customer_id = c1.customer_id

LEFT JOIN customers c2 
    ON c2.customer_unique_id = c1.customer_unique_id

LEFT JOIN products p 
    ON p.product_id = oi.product_id

LEFT JOIN sellers s 
    ON oi.seller_id = s.seller_id

LEFT JOIN dates d
    ON o.order_purchase_date = d.date
