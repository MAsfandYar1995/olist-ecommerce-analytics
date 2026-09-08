
WITH order_items AS (

    SELECT 
        * 
    FROM {{ ref('fact_order_items') }}
),

products AS (

    SELECT 
        * 
    FROM {{ ref('dim_product') }}
),

base_order_items AS (

    SELECT DISTINCT
        oi.order_id,
        p.product_category_name_en
    FROM order_items oi
    JOIN products p 
        ON oi.product_key = p.product_key
        AND p.product_category_name_en IS NOT NULL
        AND p.product_category_name_en != 'Unknown'

),

category_pairs AS (


    SELECT 
        b1.product_category_name_en AS category_a,
        b2.product_category_name_en AS category_b,
        COUNT(*) AS orders_together
    FROM base_order_items b1 
    JOIN base_order_items b2 
        ON b1.order_id = b2.order_id 
        AND b1.product_category_name_en < b2.product_category_name_en
    GROUP BY 1, 2
    
),

category_orders AS (


    SELECT 
        product_category_name_en,
        COUNT(*) AS orders
    FROM base_order_items
    GROUP BY 1

),

total_orders AS (

    SELECT
    COUNT(DISTINCT order_id) AS distinct_orders
    FROM base_order_items
),

merged AS (


    SELECT 
        cp.category_a,
        cp.category_b,
        cp.orders_together,
        cao.orders AS category_a_orders,
        cbo.orders AS category_b_orders,
        t.distinct_orders AS total_orders,

        ROUND(cp.orders_together * 100.0 / t.distinct_orders, 2) AS support_pct, 

        ROUND(cp.orders_together * 100.0 / cao.orders, 2) AS confidence_a_to_b_pct,
        ROUND(cp.orders_together * 100.0 / cbo.orders, 2) AS confidence_b_to_a_pct

    FROM category_pairs cp
    JOIN category_orders cao 
        ON cp.category_a = cao.product_category_name_en 
    JOIN category_orders cbo 
        ON cp.category_b = cbo.product_category_name_en 
    CROSS JOIN total_orders t

),

final AS (

    SELECT 
        *,
        ROUND(orders_together * 1.0 * total_orders / (category_a_orders * category_b_orders), 2) AS lift
    FROM merged 
    WHERE orders_together >= 5

)

SELECT 
    COUNT(*) AS total_pairs,
    COUNT(CASE WHEN lift > 1 THEN 1 END) AS positive_affinity_pairs
FROM final 