
-- product_category_performance_and_concentration.sql 

-- You have now covered:

-- delivery impact on reviews
-- seller fulfillment risk
-- seller GMV concentration
-- customer retention / adapted RFM

-- The big missing angle is what is being sold.

-- I would ask:

-- Which product categories drive the most GMV,
-- and which categories combine high commercial importance with weak customer experience or fulfillment performance?

-- GMV and order volume by product category
-- Pareto concentration across categories

-- average review score / poor-review rate by category
-- late or severe-delay rate by category
-- identify categories that are both commercially important and operationally weak

WITH category_sales AS (

    SELECT 
        p.product_category_name_en,
        SUM(COALESCE(oi.item_price, 0)) AS gmv,
        COUNT(DISTINCT oi.order_id) AS order_volume
    FROM {{ ref('dim_product') }} p
    JOIN {{ ref('fact_order_items') }} oi
        ON p.product_key = oi.product_key
    GROUP BY 1
),
-- total categories: 72

category_pareto_base AS (

    SELECT
        *,

        ROW_NUMBER() OVER (
            ORDER BY gmv DESC
        ) AS category_rank,

        SUM(gmv) OVER (
            ORDER BY gmv DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_gmv,

        ROUND(
            SUM(gmv) OVER (
                ORDER BY gmv DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) * 100.0
            / SUM(gmv) OVER (),
            2
        ) AS cumulative_gmv_pct

    FROM category_sales
),

category_pareto_flagged AS (

    SELECT
        *,

        CASE
            WHEN COALESCE(     -- this will andle the edge case where you have the first category to be more than 80.0 pct to total
                    LAG(cumulative_gmv_pct) OVER (
                        ORDER BY category_rank
                    ),
                    0
                 ) < 80
                AND cumulative_gmv_pct >= 80
            THEN 1
            ELSE 0
        END AS is_80_pct_mark

    FROM category_pareto_base
),

category_pareto_range_final AS (

    SELECT
        *,

        MAX(is_80_pct_mark) OVER (
            ORDER BY category_rank
            ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
        ) AS is_pareto

    FROM category_pareto_flagged

),

pareto_categories AS (

    SELECT
        product_category_name_en AS category,
        category_rank,
        gmv,
        order_volume,
        cumulative_gmv,
        cumulative_gmv_pct

    FROM category_pareto_range_final

    WHERE is_pareto = 1

),
-- pareto categories: 18


-- average review score / poor-review rate by category

reviews AS (

    SELECT 
        order_id,
        AVG(review_score) AS order_review_score

    FROM {{ ref('fact_reviews') }}

    GROUP BY 1

),

order_category AS (

    SELECT DISTINCT
        oi.order_id,
        p.product_category_name_en

    FROM {{ ref('fact_order_items') }} oi

    JOIN {{ ref('dim_product') }} p
        ON oi.product_key = p.product_key

),

category_reviews AS (

    SELECT
        oc.product_category_name_en AS category,

        COUNT(r.order_id) AS reviewed_orders,

        ROUND(
            AVG(r.order_review_score),
            2
        ) AS average_review_score,

        ROUND(
            COUNT(
                CASE
                    WHEN r.order_review_score <= 2
                    THEN 1
                END
            ) * 100.0
            / NULLIF(COUNT(r.order_id), 0),
            2
        ) AS poor_review_rate

    FROM order_category oc

    JOIN reviews r
        ON oc.order_id = r.order_id

    GROUP BY 1

),

-- late or severe-delay rate by category

order_fulfillment AS (

    SELECT 
        * 
    FROM {{ ref('fact_order_fulfillment') }}
),

dates AS (

    SELECT 
        * 
    FROM {{ ref('dim_date') }}
),

category_fulfillment AS (

    SELECT 
        c.product_category_name_en AS category,
        ROUND(
            COUNT(CASE WHEN f.on_time_delivery_flag = 0 THEN 1 END) * 100.0 
                / NULLIF(COUNT(*), 0) 
        , 2) AS late_delivery_rate,
        ROUND(
            COUNT(CASE WHEN order_customer_delivery.date > order_estimated_delivery.date + INTERVAL '3 DAYS' THEN 1 END) * 100.0 
                / NULLIF(COUNT(*), 0) 
        , 2) AS severe_delay_rate
    FROM order_category c 

    JOIN order_fulfillment f 
        ON c.order_id = f.order_id

    JOIN dates order_estimated_delivery
        ON order_estimated_delivery.date_key = f.order_estimated_delivery_date_key

    JOIN dates order_customer_delivery
        ON order_customer_delivery.date_key = f.order_delivered_customer_date_key

    WHERE f.fulfillment_sequence_anomaly_flag = 0
    GROUP BY 1

),
-- identify categories that are both commercially important and operationally weak

-- join pareto categories, category reviews, and category_fulfillment

combined AS (

    SELECT
        pc.category,
        pc.category_rank,
        pc.gmv,
        pc.order_volume,
        pc.cumulative_gmv_pct,

        cr.reviewed_orders,
        cr.average_review_score,
        cr.poor_review_rate,

        cf.late_delivery_rate,
        cf.severe_delay_rate

    FROM pareto_categories pc

    LEFT JOIN category_reviews cr
        ON pc.category = cr.category

    LEFT JOIN category_fulfillment cf
        ON pc.category = cf.category

),

-- define thresholds: What define operationally weak category? 
-- 1) Those with worse than 75-percentile of poor review rate 
-- 2) Those with worse than 75-percentile of sever delay rate

thresholds AS (

    SELECT 
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY poor_review_rate) AS p75_poor_review_rate,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY severe_delay_rate) AS p75_severe_delay_rate
    FROM combined
)

SELECT
    c.*,

    CASE
        WHEN c.poor_review_rate >= t.p75_poor_review_rate
            AND c.severe_delay_rate >= t.p75_severe_delay_rate
            THEN 'Priority Category'

        WHEN c.poor_review_rate >= t.p75_poor_review_rate
            THEN 'Customer Experience Risk'

        WHEN c.severe_delay_rate >= t.p75_severe_delay_rate
            THEN 'Fulfillment Risk'

        ELSE 'Relatively Healthy'

    END AS category_segment

FROM combined c

CROSS JOIN thresholds t

ORDER BY c.category_rank

