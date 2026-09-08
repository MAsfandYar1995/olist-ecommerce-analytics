WITH base_customers AS (

    SELECT
        c.customer_id,
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        c.customer_latitude,
        c.customer_longitude,
        o.order_purchased_at

    FROM {{ ref('int_customers_enriched') }} AS c

    LEFT JOIN {{ ref('stg_orders') }} AS o -- only joined for purchase date to be used to row_number function
        ON c.customer_id = o.customer_id

),

final_customers AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key(['customer_unique_id']) }} AS customer_key,
        customer_unique_id,
        customer_id AS latest_customer_id,
        customer_zip_code_prefix AS latest_customer_zip_code_prefix,
        customer_city AS latest_customer_city,
        customer_state AS latest_customer_state,
        customer_latitude AS latest_latitude,
        customer_longitude AS latest_longitude

    FROM base_customers

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY customer_unique_id
        ORDER BY order_purchased_at DESC NULLS LAST, -- could also be handled by adding the not null condition to above left join.
            customer_id DESC -- tie-breaker
    ) = 1

)

SELECT *
FROM final_customers