WITH products AS (

    SELECT 
        * 
    FROM {{ ref('stg_products') }}
),

product_category_translations AS (

    SELECT 
        * 
    FROM {{ ref('stg_product_category_translation') }}
),

category_mapping AS (

    SELECT
        *
    FROM {{ ref('product_category_mapping') }}
),

products_translated AS (

    SELECT 
        p.product_id,
        
        REPLACE(
            COALESCE(p.product_category_name, 'unknown'),
            '_',
            ' '
        ) AS product_category_name_br,

        REPLACE(
            COALESCE(pct.product_category_name_english, 'unknown'),
            '_',
            ' '
        ) AS translated_category_name,

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
)

SELECT 
    p.product_id,
    p.product_category_name_br,

    COALESCE(
        cm.category_name_clean,
        INITCAP(p.translated_category_name)
    ) AS product_category_name_en,

    p.product_name_length, 
    p.product_description_length,
    p.product_photos_count,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm

FROM products_translated p

LEFT JOIN category_mapping cm
    ON p.translated_category_name = cm.category_name_en