

-- customer_adapted_rfm_segmentation.sql
-- Analysis #4: Customer Retention + Adapted RFM Segmentation
--
-- Business questions:
--
-- 1. What types of customers make up the marketplace?
-- 2. Which customers represent the strongest retention opportunities?
-- 3. How common is genuine repeat purchasing?
-- 4. When do returning customers typically make their second purchase?
--
--
-- Key methodology:
--
-- 96.95% of customers placed only one order.
--
-- Because frequency is extremely concentrated at one order,
-- traditional 1-5 RFM frequency scoring would be misleading.
--
-- Instead:
--
-- Recency:
--   Based on observed quartiles of recency_days.
--
-- Monetary:
--   Based on observed GMV percentiles.
--
-- Frequency:
--   Behavioral groups:
--       1 order  = One-time Customer
--       2 orders = Repeat Customer
--       3+       = Frequent Customer


WITH customers AS (

    SELECT *
    FROM {{ ref('dim_customer') }}

),

order_items AS (

    SELECT *
    FROM {{ ref('fact_order_items') }}

),

dates AS (

    SELECT *
    FROM {{ ref('dim_date') }}

),


-- ============================================================
-- PART 1: CUSTOMER-LEVEL RFM BASE
-- ============================================================

customer_aggregated AS (

    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT oi.order_id) AS order_count,

        MAX(order_dates.date) AS last_order_date,

        SUM(oi.item_price) AS total_gmv

    FROM customers c

    JOIN order_items oi
        ON c.customer_key = oi.customer_key

    JOIN dates order_dates
        ON order_dates.date_key = oi.order_date_key

    GROUP BY 1

),

max_order_date AS (

    -- Use the latest actual transaction date,
    -- not the maximum date from dim_date.

    SELECT
        MAX(order_dates.date) AS max_order_date

    FROM order_items oi

    JOIN dates order_dates
        ON order_dates.date_key = oi.order_date_key

),

rfm_base AS (

    SELECT
        a.*,

        m.max_order_date,

        DATEDIFF(
            DAY,
            a.last_order_date,
            m.max_order_date
        ) AS recency_days

    FROM customer_aggregated a

    CROSS JOIN max_order_date m

),

scored AS (

    SELECT
        *,

        -- Recency thresholds from observed distribution:
        -- P25    = 119 days
        -- Median = 224 days
        -- P75    = 353 days

        CASE
            WHEN recency_days <= 119 THEN 4
            WHEN recency_days <= 224 THEN 3
            WHEN recency_days <= 353 THEN 2
            ELSE 1
        END AS recency_score,


        -- Monetary thresholds from observed distribution:
        -- P25    = 47.90
        -- Median = 89.90
        -- P75    = 155.00
        -- P90    = 284.00

        CASE
            WHEN total_gmv >= 284 THEN 5
            WHEN total_gmv >= 155 THEN 4
            WHEN total_gmv >= 89.9 THEN 3
            WHEN total_gmv >= 47.9 THEN 2
            ELSE 1
        END AS monetary_score,


        -- Frequency is grouped behaviorally because
        -- 96.95% of customers placed only one order.

        CASE
            WHEN order_count = 1
                THEN 'One-time Customer'

            WHEN order_count = 2
                THEN 'Repeat Customer'

            ELSE 'Frequent Customer'

        END AS purchase_frequency_segment

    FROM rfm_base

),

segmented AS (

    SELECT
        *,

        CASE

            WHEN purchase_frequency_segment = 'One-time Customer'
                AND recency_score >= 3
                AND monetary_score >= 4
                THEN 'Recent High-Value One-Time'


            WHEN purchase_frequency_segment IN (
                    'Repeat Customer',
                    'Frequent Customer'
                 )
                AND recency_score >= 3
                THEN 'Recent Repeat'


            WHEN purchase_frequency_segment IN (
                    'Repeat Customer',
                    'Frequent Customer'
                 )
                AND recency_score <= 2
                AND monetary_score >= 4
                THEN 'Lapsed High-Value Repeat'


            WHEN purchase_frequency_segment = 'One-time Customer'
                AND recency_score >= 3
                AND monetary_score <= 3
                THEN 'Recent Lower-Value One-Time'


            WHEN purchase_frequency_segment = 'One-time Customer'
                AND recency_score <= 2
                AND monetary_score >= 4
                THEN 'Older High-Value One-Time'


            ELSE 'Low-Priority Lapsed'

        END AS customer_segment

    FROM scored

),

segment_summary AS (

    SELECT
        customer_segment,

        COUNT(*) AS customers,

        ROUND(
            COUNT(*) * 100.0
            / SUM(COUNT(*)) OVER (),
            2
        ) AS customer_pct,

        ROUND(
            SUM(total_gmv),
            2
        ) AS segment_gmv,

        ROUND(
            SUM(total_gmv) * 100.0
            / SUM(SUM(total_gmv)) OVER (),
            2
        ) AS gmv_share,

        ROUND(
            AVG(total_gmv),
            2
        ) AS avg_customer_gmv,

        ROUND(
            AVG(order_count),
            2
        ) AS avg_orders

    FROM segmented

    GROUP BY 1

),


-- ============================================================
-- PART 2: FIRST TO SECOND PURCHASE
-- ============================================================

customer_orders AS (

    -- fact_order_items is item-grain,
    -- so DISTINCT prevents one order from appearing multiple times.

    SELECT DISTINCT
        c.customer_unique_id,
        oi.order_id,
        oi.order_date_key

    FROM order_items oi

    JOIN customers c
        ON oi.customer_key = c.customer_key

),

ranked_orders AS (

    SELECT
        customer_unique_id,
        order_id,
        order_date_key,

        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_date_key, order_id
        ) AS order_rn

    FROM customer_orders

),

first_second_orders AS (

    SELECT
        customer_unique_id,

        MAX(
            CASE
                WHEN order_rn = 1
                THEN order_date_key
            END
        ) AS first_order_date_key,

        MAX(
            CASE
                WHEN order_rn = 2
                THEN order_date_key
            END
        ) AS second_order_date_key

    FROM ranked_orders

    GROUP BY 1

),

days_to_second AS (

    SELECT
        fso.customer_unique_id,

        first_order_date.date AS first_order_date,

        second_order_date.date AS second_order_date,

        DATEDIFF(
            DAY,
            first_order_date.date,
            second_order_date.date
        ) AS days_to_second_order

    FROM first_second_orders fso

    JOIN dates first_order_date
        ON first_order_date.date_key =
           fso.first_order_date_key

    JOIN dates second_order_date
        ON second_order_date.date_key =
           fso.second_order_date_key

    WHERE fso.second_order_date_key IS NOT NULL

),


-- ============================================================
-- PART 3: HEADLINE CUSTOMER METRICS
-- ============================================================

headline_summary AS (

    SELECT

        COUNT(*) AS total_customers,

        COUNT_IF(order_count = 1)
            AS one_time_customers,

        ROUND(
            COUNT_IF(order_count = 1) * 100.0
            / COUNT(*),
            2
        ) AS one_time_customer_pct,


        COUNT_IF(
            customer_segment IN (
                'Recent High-Value One-Time',
                'Older High-Value One-Time'
            )
        ) AS high_value_one_time_customers,


        ROUND(
            COUNT_IF(
                customer_segment IN (
                    'Recent High-Value One-Time',
                    'Older High-Value One-Time'
                )
            ) * 100.0
            / COUNT(*),
            2
        ) AS high_value_one_time_customer_pct,


        ROUND(
            SUM(
                CASE
                    WHEN customer_segment IN (
                        'Recent High-Value One-Time',
                        'Older High-Value One-Time'
                    )
                    THEN total_gmv
                    ELSE 0
                END
            ),
            2
        ) AS high_value_one_time_gmv,


        ROUND(
            SUM(
                CASE
                    WHEN customer_segment IN (
                        'Recent High-Value One-Time',
                        'Older High-Value One-Time'
                    )
                    THEN total_gmv
                    ELSE 0
                END
            ) * 100.0
            / SUM(total_gmv),
            2
        ) AS high_value_one_time_gmv_share

    FROM segmented

),


-- ============================================================
-- PART 4: RETENTION TIMING METRICS
-- ============================================================

retention_summary AS (

    SELECT

        COUNT(*) AS repeat_customers,

        COUNT_IF(
            days_to_second_order = 0
        ) AS same_day_second_orders,

        COUNT_IF(
            days_to_second_order > 0
        ) AS returning_customers,

        ROUND(
            COUNT_IF(days_to_second_order = 0) * 100.0
            / COUNT(*),
            2
        ) AS same_day_pct,

        ROUND(
            COUNT_IF(days_to_second_order > 0) * 100.0
            / COUNT(*),
            2
        ) AS later_day_pct,


        MIN(
            CASE
                WHEN days_to_second_order > 0
                THEN days_to_second_order
            END
        ) AS min_days_to_second,


        PERCENTILE_CONT(0.25)
            WITHIN GROUP (
                ORDER BY CASE
                    WHEN days_to_second_order > 0
                    THEN days_to_second_order
                END
            ) AS p25_days_to_second,


        MEDIAN(
            CASE
                WHEN days_to_second_order > 0
                THEN days_to_second_order
            END
        ) AS median_days_to_second,


        PERCENTILE_CONT(0.75)
            WITHIN GROUP (
                ORDER BY CASE
                    WHEN days_to_second_order > 0
                    THEN days_to_second_order
                END
            ) AS p75_days_to_second,


        PERCENTILE_CONT(0.90)
            WITHIN GROUP (
                ORDER BY CASE
                    WHEN days_to_second_order > 0
                    THEN days_to_second_order
                END
            ) AS p90_days_to_second,


        MAX(
            CASE
                WHEN days_to_second_order > 0
                THEN days_to_second_order
            END
        ) AS max_days_to_second

    FROM days_to_second

),


-- ============================================================
-- PART 5: FINAL SEGMENT OUTPUT
-- ============================================================

final_output AS (

    SELECT
        s.customer_segment,

        s.customers,
        s.customer_pct,

        s.segment_gmv,
        s.gmv_share,

        s.avg_customer_gmv,
        s.avg_orders,

        h.total_customers,
        h.one_time_customers,
        h.one_time_customer_pct,

        h.high_value_one_time_customers,
        h.high_value_one_time_customer_pct,
        h.high_value_one_time_gmv,
        h.high_value_one_time_gmv_share,

        r.repeat_customers,
        r.same_day_second_orders,
        r.returning_customers,

        r.same_day_pct,
        r.later_day_pct,

        r.min_days_to_second,
        r.p25_days_to_second,
        r.median_days_to_second,
        r.p75_days_to_second,
        r.p90_days_to_second,
        r.max_days_to_second

    FROM segment_summary s

    CROSS JOIN headline_summary h

    CROSS JOIN retention_summary r

)


SELECT
    *

FROM final_output

ORDER BY segment_gmv DESC


-- ============================================================
-- FINAL FINDINGS
-- ============================================================
--
-- 1. ONE-TIME PURCHASE DOMINANCE
--
-- 96.95% of customers placed only one order.
--
-- Traditional frequency quintiles are therefore inappropriate
-- for this dataset.
--
--
-- 2. HIGH-VALUE ONE-TIME CUSTOMERS
--
-- Recent High-Value One-Time:
--     11.51% of customers
--     28.71% of marketplace GMV
--
-- Older High-Value One-Time:
--     11.73% of customers
--     29.23% of marketplace GMV
--
-- Combined:
--     ~23.2% of customers
--     ~57.9% of marketplace GMV
--
-- A relatively small group of one-time customers therefore
-- accounts for the majority of marketplace GMV.
--
--
-- 3. REPEAT PURCHASE QUALITY
--
-- 2,913 customers placed at least two distinct orders.
--
-- 875 second orders, or 30.04%, occurred on the same calendar date.
--
-- These may represent split transactions rather than genuine
-- retention behavior.
--
-- 2,038 customers, or 69.96% of repeat customers,
-- returned on a later calendar date.
--
--
-- 4. RETURN TIMING
--
-- Among later-returning customers:
--
--     25% returned within 23 days
--     50% returned within 74.5 days
--     75% returned within 177 days
--     90% returned within 291.3 days
--
--
-- KEY BUSINESS INSIGHT
--
-- Olist's customer base is overwhelmingly driven by one-time buyers,
-- but high-value one-time customers contribute a disproportionate
-- share of marketplace GMV.
--
-- The strongest retention opportunity is therefore to convert
-- recent high-value first-time customers into second-time buyers.
--
--
-- BUSINESS RECOMMENDATION
--
-- Prioritise second-purchase campaigns for
-- Recent High-Value One-Time customers,
-- especially within the first 2 to 3 months after purchase.
--
-- Use Older High-Value One-Time customers as a separate
-- reactivation / win-back audience.