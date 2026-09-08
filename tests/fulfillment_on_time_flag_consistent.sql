SELECT *
FROM {{ ref('fact_order_fulfillment') }}
WHERE
    (
        delivery_delay_days <= 0
        AND on_time_delivery_flag <> 1
    )
    OR
    (
        delivery_delay_days > 0
        AND on_time_delivery_flag <> 0
    )