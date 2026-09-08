


with source_order_items as (

    select *
    from {{ ref('bronze_order_items') }}

),

cleaned_order_items as (

    select
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date AS shipping_limit_at,
        price AS price_amount,
        freight_value AS freight_value_amount
    from source_order_items

)

select *
from cleaned_order_items