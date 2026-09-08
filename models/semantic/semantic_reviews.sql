{{ config(materialized='semantic_view') }}

TABLES (
    reviews AS {{ ref('fact_reviews') }}
        PRIMARY KEY (review_id, order_id)
)

FACTS (
    reviews.review_score AS review_score
        COMMENT = 'Customer review score ranging from 1 to 5.'
)

DIMENSIONS (
    reviews.review_id AS review_id
        COMMENT = 'Identifier assigned to the customer review.',

    reviews.order_id AS order_id
        COMMENT = 'Order associated with the review.',

    reviews.customer_key AS customer_key
        COMMENT = 'Surrogate key identifying the customer.',

    reviews.review_creation_date_key AS review_creation_date_key
        COMMENT = 'Date key representing when the review was created.',

    reviews.review_answer_date_key AS review_answer_date_key
        COMMENT = 'Date key representing when the review was answered.',

    reviews.has_comment_flag AS has_comment_flag
        COMMENT = '1 when the review contains written feedback and 0 otherwise.'
)

METRICS (
    reviews.review_count AS COUNT(*)
        COMMENT = 'Number of review records.',

    reviews.order_count AS COUNT(DISTINCT reviews.order_id)
        COMMENT = 'Number of distinct orders represented by reviews.',

    reviews.average_review_score AS AVG(reviews.review_score)
        COMMENT = 'Average customer review score.',

    reviews.reviews_with_comments AS SUM(reviews.has_comment_flag)
        COMMENT = 'Number of reviews containing written feedback.',

    reviews.comment_rate AS AVG(reviews.has_comment_flag)
        COMMENT = 'Share of reviews that contain written feedback.'
)

COMMENT = 'Olist customer review semantic view.'