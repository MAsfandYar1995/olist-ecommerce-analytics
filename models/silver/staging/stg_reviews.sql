with source_reviews as (

    select *
    from {{ ref('bronze_reviews') }}

),

cleaned_reviews as (

    select

        review_id,
        order_id,
        review_score,
        trim(review_comment_title) as review_comment_title,
        trim(review_comment_message) as review_comment_message,
        review_creation_date::date as review_created_date,
        review_answer_timestamp::date as review_answer_date,
        review_answer_timestamp as review_answered_at

    from source_reviews

)

select *
from cleaned_reviews