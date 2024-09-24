/*sellers who have the highest revenue*/

WITH sales_data AS (
    SELECT
        s.sales_person_id,
        SUM(s.quantity * p.price) AS total_revenue,
        COUNT(*) AS transaction_count
    FROM
        sales AS s
    FULL JOIN
        products AS p ON s.product_id = p.product_id
    GROUP BY
        s.sales_person_id
),

employee_names AS (
    SELECT
        employee_id,
        CONCAT(first_name, ' ', last_name) AS seller
    FROM
        employees
)

SELECT
    en.seller,
    sd.transaction_count AS operations,
    ROUND(sd.total_revenue) AS income
FROM
    employee_names AS en
JOIN 
    sales_data sd ON en.employee_id = sd.sales_person_id
ORDER BY
    sd.total_revenue DESC
LIMIT 10;

/*sellers whose revenue is lower than the average revenue of all sellers*/

WITH sales_data AS (
    SELECT
        s.sales_person_id,
        AVG(s.quantity * p.price) AS avg_revenue_per_transaction
    FROM
        sales s
    JOIN
        products AS p ON s.product_id = p.product_id
    GROUP BY
        s.sales_person_id
),

overall_avg AS (
    SELECT AVG(avg_revenue_per_transaction) AS overall_average
    FROM sales_data
)

SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    FLOOR(sd.avg_revenue_per_transaction) AS average_income
FROM
    employees AS e
JOIN
    sales_data sd ON e.employee_id = sd.sales_person_id
WHERE
    sd.avg_revenue_per_transaction < (SELECT overall_average FROM overall_avg)
ORDER BY
    sd.avg_revenue_per_transaction ASC;

/*revenue data for each seller and day of the week*/

WITH daily_sales AS (
    SELECT
        s.sales_person_id,
        EXTRACT(DOW FROM s.sale_date) AS day_of_week,
        SUM(s.quantity * p.price) AS daily_revenue
    FROM
        sales 
    JOIN
        products p ON s.product_id = p.product_id
    GROUP BY
        s.sales_person_id, EXTRACT(DOW FROM s.sale_date)
),

employee_names AS (
    SELECT
        employee_id,
        CONCAT(first_name, ' ', last_name) AS seller
    FROM
        employees
)

SELECT
    en.seller,
    CASE
        WHEN ds.day_of_week = 1 THEN 'monday   '
        WHEN ds.day_of_week = 2 THEN 'tuesday   '
        WHEN ds.day_of_week = 3 THEN 'wednesday   '
        WHEN ds.day_of_week = 4 THEN 'thursday   '
        WHEN ds.day_of_week = 5 THEN 'friday   '
        WHEN ds.day_of_week = 6 THEN 'saturday   '
        ELSE 'sunday   '
    END AS day_name,
    FLOOR(COALESCE(ds.daily_revenue, 0)) AS income
FROM
    employee_names en
LEFT JOIN
    daily_sales ds ON en.employee_id = ds.sales_person_id
GROUP BY
    en.seller, ds.day_of_week, ds.daily_revenue
ORDER BY
    CASE
        WHEN ds.day_of_week = 1 THEN 7
        WHEN ds.day_of_week = 2 THEN 6
        WHEN ds.day_of_week = 3 THEN 5
        WHEN ds.day_of_week = 4 THEN 4
        WHEN ds.day_of_week = 5 THEN 3
        WHEN ds.day_of_week = 6 THEN 2
        ELSE 1
    END DESC, seller ASC;

/*age groups of buyers*/

SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_category,
    COUNT(*) AS age_count
FROM
    customers
GROUP BY
    age_category
ORDER BY
    age_category;

/*number of buyers and revenue by month*/

SELECT
    CONCAT(EXTRACT(YEAR FROM sale_date), '-', TO_CHAR(EXTRACT(MONTH FROM sale_date), 'FM00')) AS selling_month,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    SUM(p.price * s.quantity) AS income
FROM
    sales 
JOIN
    customers c ON s.customer_id = c.customer_id
JOIN
    employees e ON s.sales_person_id = e.employee_id
JOIN
    products p ON s.product_id = p.product_id
GROUP BY
    EXTRACT(YEAR FROM sale_date), EXTRACT(MONTH FROM sale_date)
ORDER BY
    CONCAT(EXTRACT(YEAR FROM sale_date), '-', TO_CHAR(EXTRACT(MONTH FROM sale_date), 'FM00'))

/*buyers whose first purchase occurred during special promotions*/

WITH promotional_products AS (
    SELECT product_id FROM products WHERE price = 0
),
first_sales AS (
    SELECT
        s.customer_id,
        MIN(s.sale_date) AS first_sale_date,
        MIN(s.sales_id) AS first_sale_id
    FROM sales 
    JOIN promotional_products pp ON s.product_id = pp.product_id
    GROUP BY s.customer_id
),

duplicates_removed AS (
    SELECT DISTINCT
        c.first_name || ' ' || c.last_name AS customer,
        fs.first_sale_date AS sale_date,
        e.first_name || ' ' || e.last_name AS seller
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN employees e ON s.sales_person_id = e.employee_id
    JOIN first_sales fs ON s.customer_id = fs.customer_id AND s.sale_date = fs.first_sale_date
    WHERE s.product_id IN (SELECT product_id FROM promotional_products)
)
SELECT *
FROM duplicates_removed
ORDER BY customer;