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

LOAD DATA LOCAL INFILE
'C:/Users/smebh/Desktop/olist-ecommerce-sales-analytics/data/olist_order_payments_dataset.csv'
INTO TABLE olist_payments_staging
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
);
SELECT COUNT(*) AS total_records
FROM olist_payments_staging;

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders
FROM olist_payments_staging;

SELECT
    COUNT(*) AS total_records,

    SUM(order_id IS NULL OR TRIM(order_id) = '') AS missing_order_id,

    SUM(payment_sequential IS NULL OR TRIM(payment_sequential) = '') AS missing_sequential,

    SUM(payment_type IS NULL OR TRIM(payment_type) = '') AS missing_payment_type,

    SUM(payment_installments IS NULL OR TRIM(payment_installments) = '') AS missing_installments,

    SUM(payment_value IS NULL OR TRIM(payment_value) = '') AS missing_payment_value

FROM olist_payments_staging;

SELECT
    payment_type,
    COUNT(*) AS transaction_count,
    ROUND(SUM(CAST(payment_value AS DECIMAL(10,2))), 2) AS total_payment,
    ROUND(AVG(CAST(payment_value AS DECIMAL(10,2))), 2) AS average_payment
FROM olist_payments_staging
GROUP BY payment_type
ORDER BY total_payment DESC;
CREATE TABLE olist_payments AS
SELECT
    order_id,
    CAST(payment_sequential AS UNSIGNED) AS payment_sequential,
    payment_type,
    CAST(payment_installments AS UNSIGNED) AS payment_installments,
    CAST(payment_value AS DECIMAL(10,2)) AS payment_value
FROM olist_payments_staging;

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(payment_value), 2) AS average_payment_value
FROM olist_payments;

USE olist_analytics;

CREATE TABLE olist_order_items_staging (
    order_id VARCHAR(100),
    order_item_id VARCHAR(20),
    product_id VARCHAR(100),
    seller_id VARCHAR(100),
    shipping_limit_date VARCHAR(50),
    price VARCHAR(30),
    freight_value VARCHAR(30)
);

LOAD DATA LOCAL INFILE
'C:/Users/smebh/Desktop/olist-ecommerce-sales-analytics/data/olist_order_items_dataset.csv'
INTO TABLE olist_order_items_staging
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
);

SELECT COUNT(*) AS total_records
FROM olist_order_items_staging;

CREATE TABLE olist_order_items AS
SELECT
    order_id,
    CAST(order_item_id AS UNSIGNED) AS order_item_id,
    product_id,
    seller_id,
    STR_TO_DATE(shipping_limit_date, '%Y-%m-%d %H:%i:%s') AS shipping_limit_date,
    CAST(price AS DECIMAL(10,2)) AS price,
    CAST(freight_value AS DECIMAL(10,2)) AS freight_value
FROM olist_order_items_staging;

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(DISTINCT seller_id) AS unique_sellers,
    ROUND(SUM(price), 2) AS total_sales,
    ROUND(SUM(freight_value), 2) AS total_freight
FROM olist_order_items;

SELECT
    product_id,
    COUNT(*) AS units_sold,
    ROUND(SUM(price), 2) AS total_sales
FROM olist_order_items
GROUP BY product_id
ORDER BY total_sales DESC
LIMIT 10;

SELECT
    COUNT(*) AS total_orders,
    ROUND(SUM(order_sales), 2) AS total_revenue,
    ROUND(AVG(order_sales), 2) AS average_order_value
FROM (
    SELECT
        order_id,
        SUM(price) AS order_sales
    FROM olist_order_items
    GROUP BY order_id
) AS order_summary;

CREATE TABLE olist_products_staging (
    product_id VARCHAR(100),
    product_category_name VARCHAR(100),
    product_name_lenght VARCHAR(20),
    product_description_lenght VARCHAR(20),
    product_photos_qty VARCHAR(20),
    product_weight_g VARCHAR(20),
    product_length_cm VARCHAR(20),
    product_height_cm VARCHAR(20),
    product_width_cm VARCHAR(20)
);

LOAD DATA LOCAL INFILE
'C:/Users/smebh/Desktop/olist-ecommerce-sales-analytics/data/olist_products_dataset.csv'
INTO TABLE olist_products_staging
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
);

SELECT COUNT(*) AS total_records
FROM olist_products_staging;

CREATE TABLE olist_products AS
SELECT
    product_id,
    NULLIF(TRIM(product_category_name), '') AS product_category_name,
    CAST(NULLIF(product_name_lenght, '') AS UNSIGNED) AS product_name_length,
    CAST(NULLIF(product_description_lenght, '') AS UNSIGNED) AS product_description_length,
    CAST(NULLIF(product_photos_qty, '') AS UNSIGNED) AS product_photos_qty,
    CAST(NULLIF(product_weight_g, '') AS UNSIGNED) AS product_weight_g,
    CAST(NULLIF(product_length_cm, '') AS UNSIGNED) AS product_length_cm,
    CAST(NULLIF(product_height_cm, '') AS UNSIGNED) AS product_height_cm,
    CAST(NULLIF(product_width_cm, '') AS UNSIGNED) AS product_width_cm
FROM olist_products_staging;

SELECT
    p.product_category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(oi.order_item_id) AS units_sold,
    ROUND(SUM(oi.price), 2) AS total_sales
FROM olist_products p
JOIN olist_order_items oi
    ON p.product_id = oi.product_id
WHERE p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
ORDER BY total_sales DESC
LIMIT 10;

SELECT
    COUNT(*) AS total_products,
    SUM(product_category_name IS NULL) AS missing_categories,
    COUNT(DISTINCT product_category_name) AS total_categories
FROM olist_products;