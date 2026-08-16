USE sql_sales_analysis;

-- ============================================
-- FR4: Revenue by month
-- ============================================
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS year_months,
    SUM(od.sales) AS total_revenue
FROM Orders o
JOIN OrderDetails od ON o.order_id = od.order_id
GROUP BY year_months
ORDER BY year_months;

-- ============================================
-- FR4: Revenue by quarter
-- ============================================
SELECT
    YEAR(o.order_date) AS order_year,
    QUARTER(o.order_date) AS order_quarter,
    SUM(od.sales) AS total_revenue
FROM Orders o
JOIN OrderDetails od ON o.order_id = od.order_id
GROUP BY order_year, order_quarter
ORDER BY order_year, order_quarter;

-- ============================================
-- FR5: Top 5 products by revenue
-- ============================================
SELECT
    p.product_name,
    SUM(od.sales) AS total_revenue
FROM OrderDetails od
JOIN Products p ON od.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 5;

-- ============================================
-- FR5: Top 5 customers by total spend
-- ============================================
SELECT
    c.customer_name,
    SUM(od.sales) AS total_spend
FROM OrderDetails od
JOIN Orders o ON od.order_id = o.order_id
JOIN Customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spend DESC
LIMIT 5;

SELECT
    o.region,
    SUM(od.sales) AS total_revenue
FROM Orders o
JOIN OrderDetails od ON o.order_id = od.order_id
GROUP BY o.region
ORDER BY total_revenue DESC;

SELECT
    p.category,
    SUM(od.sales) AS total_revenue
FROM OrderDetails od
JOIN Products p ON od.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

WITH monthly_revenue AS (
    SELECT
        YEAR(o.order_date) AS order_year,
        MONTH(o.order_date) AS order_month,
        SUM(od.sales) AS total_revenue
    FROM Orders o
    JOIN OrderDetails od ON o.order_id = od.order_id
    GROUP BY order_year, order_month
)
SELECT
    order_year,
    order_month,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY order_year, order_month) AS prev_month_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY order_year, order_month))
        / LAG(total_revenue) OVER (ORDER BY order_year, order_month) * 100,
        2
    ) AS mom_growth_pct
FROM monthly_revenue
ORDER BY order_year, order_month;

WITH monthly_revenue AS (
    SELECT
        YEAR(o.order_date) AS order_year,
        MONTH(o.order_date) AS order_month,
        SUM(od.sales) AS total_revenue
    FROM Orders o
    JOIN OrderDetails od ON o.order_id = od.order_id
    GROUP BY order_year, order_month
)
SELECT
    order_year,
    order_month,
    total_revenue,
    SUM(total_revenue) OVER (ORDER BY order_year, order_month) AS running_total
FROM monthly_revenue
ORDER BY order_year, order_month;

SELECT
    p.category,
    p.product_name,
    SUM(od.sales) AS total_revenue,
    RANK() OVER (PARTITION BY p.category ORDER BY SUM(od.sales) DESC) AS revenue_rank
FROM OrderDetails od
JOIN Products p ON od.product_id = p.product_id
GROUP BY p.category, p.product_name
ORDER BY p.category, revenue_rank;