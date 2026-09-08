
WITH products AS (

    SELECT 
        * 
    FROM {{ ref('stg_products') }}
),

product_category_translations AS (

    SELECT 
        * 
    FROM {{ ref('stg_product_category_translation') }}
)

SELECT 
    p.product_id,
    COALESCE(p.product_category_name, 'unknown') AS product_category_name_br,
    COALESCE(pct.product_category_name_english, 'unknown') AS product_category_name_en,
    p.product_name_length, 
    p.product_description_length,
    p.product_photos_count,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM products p 
LEFT JOIN product_category_translations pct 
    ON p.product_category_name = pct.product_category_name