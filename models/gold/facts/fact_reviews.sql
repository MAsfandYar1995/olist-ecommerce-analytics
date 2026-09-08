WITH reviews AS (

    SELECT 
        * 
    FROM {{ ref('stg_reviews') }}

),

orders AS (

    SELECT 
        * 
    FROM {{ ref('stg_orders') }}

),

customer_mapping AS (

    SELECT
        customer_id,
        customer_unique_id
    FROM {{ ref('int_customers_enriched') }}

),

customers AS (

    SELECT 
        * 
    FROM {{ ref('dim_customer') }}

),

review_dates AS (

    SELECT 
        *
    FROM {{ ref('dim_date') }}

),

answer_dates AS (

    SELECT 
        *
    FROM {{ ref('dim_date') }}

)

SELECT 
    r.review_id,
    r.order_id,

    c.customer_key,
    rd.date_key AS review_creation_date_key,
    ad.date_key AS review_answer_date_key,

    r.review_score,
    r.review_comment_title,
    r.review_comment_message,

    CASE 
        WHEN r.review_comment_title IS NOT NULL
          OR r.review_comment_message IS NOT NULL
        THEN 1
        ELSE 0 
    END AS has_comment_flag

FROM reviews r 

LEFT JOIN orders o 
    ON r.order_id = o.order_id 

LEFT JOIN customer_mapping cm
    ON o.customer_id = cm.customer_id

LEFT JOIN customers c 
    ON cm.customer_unique_id = c.customer_unique_id

LEFT JOIN review_dates rd 
    ON rd.date = r.review_created_date

LEFT JOIN answer_dates ad 
    ON ad.date = r.review_answer_date