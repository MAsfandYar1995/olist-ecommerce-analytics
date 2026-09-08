SELECT 
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    current_timestamp() AS _bronze_loaded_at
FROM {{ source('olist_ecommerce', 'order_reviews') }}