

-- delivery_delay_impact_on_reviews.sql 

-- Does customer satisfaction get progressively worse as the delay gets longer?

With dedup_reviews AS (
    
    SELECT 
        order_id,
        AVG(review_score) AS final_review_score
    FROM {{ ref('fact_reviews') }}
    GROUP BY 1  
),

order_fulfillment AS (
    
    SELECT 
        * 
    FROM {{ ref('fact_order_fulfillment') }}
),

dates AS (
    SELECT 
        * 
    FROM {{ ref('dim_date') }}
)


SELECT 

    CASE

        WHEN customer_delivery_date.date <= estimated_delivery_date.date THEN 'On Time'

        WHEN customer_delivery_date.date <= estimated_delivery_date.date + INTERVAL '3 DAYS' THEN '1 to 3 days late'

        WHEN customer_delivery_date.date <= estimated_delivery_date.date + INTERVAL '7 DAYS' THEN '4 to 7 days late'

        WHEN customer_delivery_date.date <= estimated_delivery_date.date + INTERVAL '14 DAYS' THEN '8 to 14 days late'

        ELSE '15+ days late'
    
    END AS delivery_segment,

    COUNT(*) AS eligible_orders,
    COUNT(r.order_id) AS reviewed_orders,
    ROUND(AVG(r.final_review_score), 2) AS avg_review_score,
    ROUND(
        COUNT(CASE WHEN r.final_review_score <= 2 THEN 1 END) * 100.0 / 
        NULLIF(COUNT(r.order_id), 0)
    , 2) AS poor_review_pct
FROM order_fulfillment f 
LEFT JOIN dedup_reviews r
    ON f.order_id = r.order_id
LEFT JOIN dates customer_delivery_date
    ON f.order_delivered_customer_date_key = customer_delivery_date.date_key 
LEFT JOIN dates estimated_delivery_date
    ON f.order_estimated_delivery_date_key = estimated_delivery_date.date_key
WHERE 
    f.fulfillment_sequence_anomaly_flag = 0 AND 
    customer_delivery_date.date IS NOT NULL AND 
    estimated_delivery_date.date IS NOT NULL
GROUP BY 1


-- Insight: Satisfaction falls sharply as delivery delays increase. 
-- On-time orders average 4.29 stars, while 1 to 3 days late drops to 3.29, 4 to 7 days late falls to 2.11, 
-- and delays beyond one week are associated with roughly 80% poor reviews.


