

WITH source_orders as (

    SELECT *
    FROM {{ ref('bronze_orders') }}

),

cleaned_orders as (

    select
        order_id,
        customer_id,
        lower(trim(order_status)) AS order_status,

        order_purchase_timestamp::DATE AS order_purchase_date,
        order_purchase_timestamp AS order_purchased_at,
        
        order_approved_at::DATE AS order_approved_date,
        order_approved_at,

        order_delivered_carrier_date::DATE AS order_delivered_carrier_date,
        order_delivered_carrier_date AS order_delivered_carrier_at,


        order_delivered_customer_date::DATE AS order_delivered_customer_date,
        order_delivered_customer_date AS order_delivered_customer_at, 

        order_estimated_delivery_date::DATE AS order_estimated_delivery_date

    FROM source_orders

)

SELECT *
FROM cleaned_orders