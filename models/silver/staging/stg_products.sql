

with source_products as (

    select *
    from {{ ref('bronze_products') }}

),

cleaned_products as (

    select
        product_id,
        lower(trim(product_category_name)) AS product_category_name,
        product_name_lenght AS product_name_length,
        product_description_lenght AS product_description_length,
        product_photos_qty AS product_photos_count,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm

    from source_products

)

select *
from cleaned_products
