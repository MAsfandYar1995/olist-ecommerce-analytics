WITH base_products AS (
    
    SELECT 
        * 
    FROM {{ ref('int_products_enriched') }}

),

final_products AS (

    SELECT 
        {{ dbt_utils.generate_surrogate_key(['product_id']) }} AS product_key,
        product_id,
        product_category_name_br,
        product_category_name_en,
        PRODUCT_NAME_LENGTH,
        PRODUCT_DESCRIPTION_LENGTH,
        PRODUCT_PHOTOS_COUNT,
        PRODUCT_WEIGHT_G,
        PRODUCT_LENGTH_CM,
        PRODUCT_HEIGHT_CM,
        PRODUCT_WIDTH_CM
    FROM base_products
)

SELECT * FROM final_products