
with source_prod_cat_translations as (

    select *
    from {{ ref('bronze_product_category_translation') }}

),

cleaned_prod_cat_translations as (

    select
        lower(trim(product_category_name)) as product_category_name,
        trim(lower(product_category_name_english)) as product_category_name_english
    from source_prod_cat_translations

)

select *
from cleaned_prod_cat_translations