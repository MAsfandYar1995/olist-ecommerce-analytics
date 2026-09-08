
with source_payments as (

    select *
    from {{ ref('bronze_payments') }}

),

cleaned_payments as (

    select

        order_id,
        payment_sequential,
        lower(trim(payment_type)) as payment_type,
        payment_installments,
        payment_value AS payment_amount

    from source_payments

)

select *
from cleaned_payments


