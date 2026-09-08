
with source_sellers as (

    select *
    from {{ ref('bronze_sellers') }}

),

cleaned_sellers as (

    select
        seller_id,
        LPAD(seller_zip_code_prefix::VARCHAR, 5, '0') AS seller_zip_code_prefix,
        trim(lower(seller_city)) as seller_city,
        trim(upper(seller_state)) as seller_state

    from source_sellers

)

select *
from cleaned_sellers