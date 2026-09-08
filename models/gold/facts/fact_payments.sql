WITH payments AS (

    SELECT 
        *
    FROM {{ ref('stg_payments') }}

),

orders AS (

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

)

SELECT
    p.order_id,
    p.payment_sequential,
    p.payment_type,
    p.payment_installments,
    p.payment_amount,

    d.date_key AS order_date_key,
    c.customer_key

FROM payments p 

LEFT JOIN orders o 
    ON o.order_id = p.order_id 

LEFT JOIN customer_mapping cm
    ON o.customer_id = cm.customer_id

LEFT JOIN customers c 
    ON cm.customer_unique_id = c.customer_unique_id

LEFT JOIN dates d 
    ON d.date = o.order_purchase_date