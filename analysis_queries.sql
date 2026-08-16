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

-- FR6: Revenue by region
SELECT
    o.region,
    SUM(od.sales) AS total_revenue
FROM Orders o
JOIN OrderDetails od ON o.order_id = od.order_id
GROUP BY o.region
ORDER BY total_revenue DESC;

-- FR6: Revenue by category
SELECT
    p.category,
    SUM(od.sales) AS total_revenue
FROM OrderDetails od
JOIN Products p ON od.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

-- FR7: Month-over-month growth rate using LAG()
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

-- FR8: Running total of revenue using SUM() OVER
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

-- FR11: Product ranking within each category by revenue using RANK()
SELECT
    p.category,
    p.product_name,
    SUM(od.sales) AS total_revenue,
    RANK() OVER (PARTITION BY p.category ORDER BY SUM(od.sales) DESC) AS revenue_rank
FROM OrderDetails od
JOIN Products p ON od.product_id = p.product_id
GROUP BY p.category, p.product_name
ORDER BY p.category, revenue_rank;

-- FR9: Churn-style query — customers active in one year but not the next
WITH customer_years AS (
    SELECT DISTINCT
        o.customer_id,
        YEAR(o.order_date) AS order_year
    FROM Orders o
)
SELECT
    cy_prev.customer_id,
    cy_prev.order_year AS active_year,
    cy_prev.order_year + 1 AS churned_in_year
FROM customer_years cy_prev
LEFT JOIN customer_years cy_next
    ON cy_prev.customer_id = cy_next.customer_id
    AND cy_next.order_year = cy_prev.order_year + 1
WHERE cy_next.customer_id IS NULL
ORDER BY cy_prev.order_year, cy_prev.customer_id;

-- FR10: Average order value trend over time
WITH order_totals AS (
    SELECT
        o.order_id,
        YEAR(o.order_date) AS order_year,
        MONTH(o.order_date) AS order_month,
        SUM(od.sales) AS order_value
    FROM Orders o
    JOIN OrderDetails od ON o.order_id = od.order_id
    GROUP BY o.order_id, order_year, order_month
)
SELECT
    order_year,
    order_month,
    ROUND(AVG(order_value), 2) AS avg_order_value
FROM order_totals
GROUP BY order_year, order_month
ORDER BY order_year, order_month;

-- ============================================
-- FR12: Self-authored question —
-- Which sub-category has the highest average discount,
-- and does heavy discounting correlate with lower profit?
-- Justification: discounting drives sales volume but can silently erode
-- margin — a stakeholder deciding discount policy needs to see this tradeoff
-- directly, not just revenue in isolation.
-- ============================================
SELECT
    p.sub_category,
    ROUND(AVG(od.discount), 3) AS avg_discount,
    ROUND(SUM(od.profit), 2) AS total_profit,
    ROUND(SUM(od.sales), 2) AS total_revenue,
    ROUND(SUM(od.profit) / SUM(od.sales) * 100, 2) AS profit_margin_pct
FROM OrderDetails od
JOIN Products p ON od.product_id = p.product_id
GROUP BY p.sub_category
ORDER BY avg_discount DESC;