CREATE DATABASE olist_analytics;
USE olist_analytics;

USE olist_analytics;

DROP TABLE IF EXISTS olist_orders_staging;

CREATE TABLE olist_orders_staging (
    order_id VARCHAR(100),
    customer_id VARCHAR(100),
    order_status VARCHAR(100),
    order_purchase_timestamp VARCHAR(100),
    order_approved_at VARCHAR(100),
    order_delivered_carrier_date VARCHAR(100),
    order_delivered_customer_date VARCHAR(100),
    order_estimated_delivery_date VARCHAR(100)
);
SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;


SHOW GLOBAL VARIABLES LIKE 'local_infile';


USE olist_analytics;

LOAD DATA LOCAL INFILE
'C:/Users/smebh/Desktop/olist-ecommerce-sales-analytics/data/olist_orders_sql.csv'
INTO TABLE olist_orders_staging
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;
SELECT COUNT(*) AS total_orders
FROM olist_orders_staging;

SELECT *
FROM olist_orders_staging
LIMIT 10;
DESCRIBE olist_orders_staging;

SELECT
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM olist_orders_staging
LIMIT 5;

SELECT
    order_purchase_timestamp AS original_date,
    STR_TO_DATE(order_purchase_timestamp, '%c/%e/%Y %H:%i') AS converted_date
FROM olist_orders_staging
LIMIT 10;

SELECT
    COUNT(*) AS total_orders,

    SUM(order_purchase_timestamp IS NULL
        OR STR_TO_DATE(order_purchase_timestamp, '%c/%e/%Y %H:%i') IS NULL)
        AS invalid_purchase_dates,

    SUM(order_approved_at IS NOT NULL
        AND STR_TO_DATE(order_approved_at, '%c/%e/%Y %H:%i') IS NULL)
        AS invalid_approval_dates,

    SUM(order_delivered_carrier_date IS NOT NULL
        AND STR_TO_DATE(order_delivered_carrier_date, '%c/%e/%Y %H:%i') IS NULL)
        AS invalid_carrier_dates,

    SUM(order_delivered_customer_date IS NOT NULL
        AND STR_TO_DATE(order_delivered_customer_date, '%c/%e/%Y %H:%i') IS NULL)
        AS invalid_delivery_dates,

    SUM(order_estimated_delivery_date IS NULL
        OR STR_TO_DATE(order_estimated_delivery_date, '%c/%e/%Y %H:%i') IS NULL)
        AS invalid_estimated_dates

FROM olist_orders_staging;


SELECT
    COUNT(*) AS total_orders,

    SUM(TRIM(order_purchase_timestamp) = '') AS missing_purchase_dates,
    SUM(TRIM(order_approved_at) = '') AS missing_approval_dates,
    SUM(TRIM(order_delivered_carrier_date) = '') AS missing_carrier_dates,
    SUM(TRIM(order_delivered_customer_date) = '') AS missing_delivery_dates,
    SUM(TRIM(order_estimated_delivery_date) = '') AS missing_estimated_dates

FROM olist_orders_staging;

SELECT
    SUM(TRIM(order_purchase_timestamp) <> ''
        AND STR_TO_DATE(order_purchase_timestamp, '%c/%e/%Y %H:%i') IS NULL)
        AS bad_purchase_dates,

    SUM(TRIM(order_approved_at) <> ''
        AND STR_TO_DATE(order_approved_at, '%c/%e/%Y %H:%i') IS NULL)
        AS bad_approval_dates,

    SUM(TRIM(order_delivered_carrier_date) <> ''
        AND STR_TO_DATE(order_delivered_carrier_date, '%c/%e/%Y %H:%i') IS NULL)
        AS bad_carrier_dates,

    SUM(TRIM(order_delivered_customer_date) <> ''
        AND STR_TO_DATE(order_delivered_customer_date, '%c/%e/%Y %H:%i') IS NULL)
        AS bad_delivery_dates,

    SUM(TRIM(order_estimated_delivery_date) <> ''
        AND STR_TO_DATE(order_estimated_delivery_date, '%c/%e/%Y %H:%i') IS NULL)
        AS bad_estimated_dates

FROM olist_orders_staging;

CREATE TABLE olist_orders AS
SELECT
    order_id,
    customer_id,
    order_status,
    STR_TO_DATE(order_purchase_timestamp, '%c/%e/%Y %H:%i')
        AS order_purchase_timestamp,
    STR_TO_DATE(NULLIF(TRIM(order_approved_at), ''), '%c/%e/%Y %H:%i')
        AS order_approved_at,
    STR_TO_DATE(NULLIF(TRIM(order_delivered_carrier_date), ''), '%c/%e/%Y %H:%i')
        AS order_delivered_carrier_date,
    STR_TO_DATE(NULLIF(TRIM(order_delivered_customer_date), ''), '%c/%e/%Y %H:%i')
        AS order_delivered_customer_date,
    STR_TO_DATE(order_estimated_delivery_date, '%c/%e/%Y %H:%i')
        AS order_estimated_delivery_date
FROM olist_orders_staging;

SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT order_id) AS unique_orders,
    MIN(order_purchase_timestamp) AS first_order_date,
    MAX(order_purchase_timestamp) AS last_order_date
FROM olist_orders;

SELECT
    COUNT(*) AS total_orders,
    SUM(order_approved_at IS NULL) AS missing_approval_dates,
    SUM(order_delivered_carrier_date IS NULL) AS missing_carrier_dates,
    SUM(order_delivered_customer_date IS NULL) AS missing_delivery_dates,
    SUM(order_estimated_delivery_date IS NULL) AS missing_estimated_dates
FROM olist_orders;

SELECT
    order_status,
    COUNT(*) AS orders_without_delivery_date
FROM olist_orders
WHERE order_delivered_customer_date IS NULL
GROUP BY order_status
ORDER BY orders_without_delivery_date DESC;

SELECT
    COUNT(*) AS total_delivered_orders,
    SUM(order_delivered_customer_date IS NOT NULL) AS delivered_with_date,
    SUM(order_delivered_customer_date IS NULL) AS delivered_without_date
FROM olist_orders
WHERE order_status = 'delivered';

SELECT
    COUNT(*) AS total_valid_deliveries,

    SUM(
        order_delivered_customer_date <= order_estimated_delivery_date
    ) AS on_time_deliveries,

    SUM(
        order_delivered_customer_date > order_estimated_delivery_date
    ) AS late_deliveries,

    ROUND(
        SUM(
            order_delivered_customer_date <= order_estimated_delivery_date
        ) * 100.0 / COUNT(*),
        2
    ) AS on_time_delivery_rate

FROM olist_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
  
  SELECT
    ROUND(
        AVG(
            DATEDIFF(
                order_delivered_customer_date,
                order_purchase_timestamp
            )
        ),
        2
    ) AS avg_delivery_days,

    MIN(
        DATEDIFF(
            order_delivered_customer_date,
            order_purchase_timestamp
        )
    ) AS fastest_delivery_days,

    MAX(
        DATEDIFF(
            order_delivered_customer_date,
            order_purchase_timestamp
        )
    ) AS slowest_delivery_days

FROM olist_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
  
  SELECT
    CASE
        WHEN order_delivered_customer_date
             <= order_estimated_delivery_date
        THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,

    COUNT(*) AS total_orders,

    ROUND(
        AVG(
            DATEDIFF(
                order_delivered_customer_date,
                order_purchase_timestamp
            )
        ),
        2
    ) AS avg_delivery_days

FROM olist_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL

GROUP BY delivery_status;

SELECT
    COUNT(*) AS late_orders,

    ROUND(
        AVG(
            DATEDIFF(
                order_delivered_customer_date,
                order_estimated_delivery_date
            )
        ),
        2
    ) AS avg_delay_days,

    MAX(
        DATEDIFF(
            order_delivered_customer_date,
            order_estimated_delivery_date
        )
    ) AS maximum_delay_days

FROM olist_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date > order_estimated_delivery_date;
  
  SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
        AS order_month,

    COUNT(*) AS total_delivered_orders,

    SUM(
        order_delivered_customer_date
        > order_estimated_delivery_date
    ) AS late_orders,

    ROUND(
        100.0 * SUM(
            order_delivered_customer_date
            > order_estimated_delivery_date
        ) / COUNT(*),
        2
    ) AS late_delivery_rate

FROM olist_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL

GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY order_month;

SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
        AS order_month,

    COUNT(*) AS late_orders,

    ROUND(
        AVG(
            DATEDIFF(
                order_delivered_customer_date,
                order_estimated_delivery_date
            )
        ),
        2
    ) AS avg_delay_days,

    MAX(
        DATEDIFF(
            order_delivered_customer_date,
            order_estimated_delivery_date
        )
    ) AS max_delay_days

FROM olist_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date > order_estimated_delivery_date

GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY order_month;

SELECT
    CASE
        WHEN DATEDIFF(
            order_delivered_customer_date,
            order_estimated_delivery_date
        ) <= 3 THEN '1. Slight (1-3 days)'

        WHEN DATEDIFF(
            order_delivered_customer_date,
            order_estimated_delivery_date
        ) <= 7 THEN '2. Moderate (4-7 days)'

        WHEN DATEDIFF(
            order_delivered_customer_date,
            order_estimated_delivery_date
        ) <= 14 THEN '3. Significant (8-14 days)'

        ELSE '4. Severe (15+ days)'
    END AS delay_category,

    COUNT(*) AS total_orders,

    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*)
         FROM olist_orders
         WHERE order_status = 'delivered'
           AND order_delivered_customer_date
               > order_estimated_delivery_date),
        2
    ) AS percentage

FROM olist_orders

WHERE order_status = 'delivered'
  AND order_delivered_customer_date
      > order_estimated_delivery_date

GROUP BY delay_category
ORDER BY delay_category;

SELECT
    order_id,
    order_purchase_timestamp,
    order_estimated_delivery_date,
    order_delivered_customer_date,

    DATEDIFF(
        order_delivered_customer_date,
        order_estimated_delivery_date
    ) AS delay_days

FROM olist_orders

WHERE order_status = 'delivered'
  AND order_delivered_customer_date
      > order_estimated_delivery_date

ORDER BY delay_days DESC
LIMIT 10;

SELECT
    CASE
        WHEN order_delivered_customer_date
             < order_estimated_delivery_date
            THEN 'Early'

        WHEN order_delivered_customer_date
             = order_estimated_delivery_date
            THEN 'Exactly On Time'

        ELSE 'Late'
    END AS delivery_status,

    COUNT(*) AS total_orders,

    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*)
         FROM olist_orders
         WHERE order_status = 'delivered'
           AND order_delivered_customer_date IS NOT NULL),
        2
    ) AS percentage

FROM olist_orders

WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL

GROUP BY delivery_status
ORDER BY total_orders DESC;

SELECT
    ROUND(
        AVG(
            DATEDIFF(
                order_estimated_delivery_date,
                order_purchase_timestamp
            )
        ), 2
    ) AS avg_promised_days,

    ROUND(
        AVG(
            DATEDIFF(
                order_delivered_customer_date,
                order_purchase_timestamp
            )
        ), 2
    ) AS avg_actual_days,

    ROUND(
        AVG(
            DATEDIFF(
                order_estimated_delivery_date,
                order_delivered_customer_date
            )
        ), 2
    ) AS avg_days_ahead_of_estimate

FROM olist_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
  
  SELECT
    COUNT(*) AS total_customers,

    SUM(order_count = 1) AS one_time_customers,

    SUM(order_count > 1) AS repeat_customers,

    ROUND(
        SUM(order_count > 1) * 100.0 / COUNT(*),
        2
    ) AS repeat_customer_percentage

FROM (
    SELECT
        customer_id,
        COUNT(order_id) AS order_count
    FROM olist_orders
    GROUP BY customer_id
) AS customer_orders;

USE olist_analytics;

CREATE TABLE olist_customers_staging (
    customer_id VARCHAR(100),
    customer_unique_id VARCHAR(100),
    customer_zip_code_prefix VARCHAR(20),
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

LOAD DATA LOCAL INFILE
'C:/Users/smebh/Desktop/olist-ecommerce-sales-analytics/data/olist_customers_dataset.csv'
INTO TABLE olist_customers_staging
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
);

SELECT COUNT(*) AS total_customers
FROM olist_customers_staging;

LOAD DATA LOCAL INFILE
'C:/Users/smebh/Desktop/olist-ecommerce-sales-analytics/data/olist_customers_dataset.csv'
INTO TABLE olist_customers_staging
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
);

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM olist_customers_staging;

SELECT
    c.customer_unique_id,
    COUNT(o.order_id) AS total_orders
FROM olist_orders AS o
JOIN olist_customers_staging AS c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_unique_id
ORDER BY total_orders DESC;

SELECT
    COUNT(*) AS total_unique_customers,

    SUM(order_count = 1) AS one_time_customers,

    SUM(order_count > 1) AS repeat_customers,

    ROUND(
        SUM(order_count > 1) * 100.0 / COUNT(*),
        2
    ) AS repeat_customer_percentage

FROM (
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS order_count

    FROM olist_orders AS o

    JOIN olist_customers_staging AS c
        ON o.customer_id = c.customer_id

    GROUP BY c.customer_unique_id
) AS customer_summary;

SELECT
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS total_customers
FROM olist_customers_staging
GROUP BY customer_state
ORDER BY total_customers DESC;

SELECT
    c.customer_state,
    COUNT(o.order_id) AS total_orders,

    SUM(
        CASE
            WHEN o.order_status = 'delivered'
            AND o.order_delivered_customer_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS delivered_orders,

    SUM(
        CASE
            WHEN o.order_status = 'delivered'
            AND o.order_delivered_customer_date IS NOT NULL
            AND o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 1 ELSE 0
        END
    ) AS late_deliveries,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN o.order_status = 'delivered'
                AND o.order_delivered_customer_date IS NOT NULL
                AND o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1 ELSE 0
            END
        ) /
        NULLIF(SUM(
            CASE
                WHEN o.order_status = 'delivered'
                AND o.order_delivered_customer_date IS NOT NULL
                THEN 1 ELSE 0
            END
        ), 0),
        2
    ) AS late_delivery_rate

FROM olist_orders o
JOIN olist_customers_staging c
    ON o.customer_id = c.customer_id

GROUP BY c.customer_state
ORDER BY late_delivery_rate DESC;

USE olist_analytics;

CREATE TABLE olist_payments_staging (
    order_id VARCHAR(100),
    payment_sequential VARCHAR(20),
    payment_type VARCHAR(50),
    payment_installments VARCHAR(20),
    payment_value VARCHAR(30)
);