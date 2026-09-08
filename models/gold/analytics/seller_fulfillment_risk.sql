-- seller_fulfillment_risk.sql

WITH order_fulfillment AS (

    SELECT *
    FROM {{ ref('fact_order_fulfillment') }}

),

sellers AS (

    SELECT *
    FROM {{ ref('dim_seller') }}

),

seller_orders AS (

    SELECT DISTINCT
        seller_key,
        order_id
    FROM {{ ref('fact_order_items') }}

),

dedup_reviews AS (

    SELECT
        order_id,
        AVG(review_score) AS final_review_score
    FROM {{ ref('fact_reviews') }}
    GROUP BY 1

),

dates AS (

    SELECT *
    FROM {{ ref('dim_date') }}

),

aggregated AS (

    SELECT
        s.seller_key,
        s.seller_id,
        s.seller_zip_code_prefix,

        COUNT(f.order_id) AS delivered_orders,

        COUNT(
            CASE
                WHEN f.on_time_delivery_flag = 0
                THEN f.order_id
            END
        ) AS late_orders,

        ROUND(
            COUNT(
                CASE
                    WHEN f.on_time_delivery_flag = 0
                    THEN f.order_id
                END
            ) * 100.0
            / NULLIF(COUNT(f.order_id), 0),
            2
        ) AS late_order_rate,

        COUNT(
            CASE
                WHEN customer_delivery_dates.date
                    > estimated_delivery_dates.date + INTERVAL '3 DAYS'
                THEN f.order_id
            END
        ) AS severe_delay_orders,

        ROUND(
            COUNT(
                CASE
                    WHEN customer_delivery_dates.date
                        > estimated_delivery_dates.date + INTERVAL '3 DAYS'
                    THEN f.order_id
                END
            ) * 100.0
            / NULLIF(COUNT(f.order_id), 0),
            2
        ) AS severe_delay_rate,

        COUNT(r.order_id) AS reviewed_orders,

        ROUND(
            AVG(r.final_review_score),
            2
        ) AS average_review_score,

        COUNT(
            CASE
                WHEN r.final_review_score <= 2
                THEN 1
            END
        ) AS poor_reviews,

        ROUND(
            COUNT(
                CASE
                    WHEN r.final_review_score <= 2
                    THEN 1
                END
            ) * 100.0
            / NULLIF(COUNT(r.order_id), 0),
            2
        ) AS poor_review_rate,

        COUNT(
            CASE
                WHEN customer_delivery_dates.date
                    > estimated_delivery_dates.date + INTERVAL '3 DAYS'
                    AND r.order_id IS NOT NULL
                THEN 1
            END
        ) AS severe_delay_reviewed_orders,

        COUNT(
            CASE
                WHEN customer_delivery_dates.date
                    > estimated_delivery_dates.date + INTERVAL '3 DAYS'
                    AND r.final_review_score <= 2
                THEN 1
            END
        ) AS severe_delay_poor_reviews

    FROM sellers s

    JOIN seller_orders so
        ON s.seller_key = so.seller_key

    JOIN order_fulfillment f
        ON f.order_id = so.order_id

    JOIN dates estimated_delivery_dates
        ON estimated_delivery_dates.date_key =
           f.order_estimated_delivery_date_key

    JOIN dates customer_delivery_dates
        ON customer_delivery_dates.date_key =
           f.order_delivered_customer_date_key

    LEFT JOIN dedup_reviews r
        ON r.order_id = f.order_id

    WHERE f.fulfillment_sequence_anomaly_flag = 0

    GROUP BY 1, 2, 3

    HAVING COUNT(f.order_id) >= 100

),

thresholds AS (

    SELECT
        MEDIAN(delivered_orders) AS median_delivered_orders,

        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY severe_delay_rate)
            AS p75_severe_delay,

        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY poor_review_rate)
            AS p75_poor_review

    FROM aggregated

)

SELECT
    a.*,

    ROUND(
        a.severe_delay_poor_reviews * 100.0
        / NULLIF(a.severe_delay_reviewed_orders, 0),
        2
    ) AS severe_delay_poor_review_rate,

    CASE
        WHEN a.delivered_orders >= t.median_delivered_orders
            AND a.severe_delay_rate >= t.p75_severe_delay
            AND a.poor_review_rate >= t.p75_poor_review
            THEN 'Priority Intervention'

        WHEN a.delivered_orders >= t.median_delivered_orders
            AND a.severe_delay_rate >= t.p75_severe_delay
            THEN 'High Volume Fulfillment Risk'

        WHEN a.delivered_orders >= t.median_delivered_orders
            AND a.severe_delay_rate < t.p75_severe_delay
            THEN 'High Volume Reliable'

        WHEN a.delivered_orders < t.median_delivered_orders
            AND a.severe_delay_rate >= t.p75_severe_delay
            THEN 'Watchlist'

        ELSE 'Lower Priority'
    END AS seller_segment

FROM aggregated a
CROSS JOIN thresholds t