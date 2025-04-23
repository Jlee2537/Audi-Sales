-- Models showing consistent growth in sales
WITH yearly_sales AS (
	SELECT
		model,
		YEAR(sale_date) `year`,
        ROUND(SUM(sale_price)) total_sales
	FROM sales
	WHERE YEAR(sale_date) IN (2022, 2023, 2024)
	GROUP BY model, YEAR(sale_date)
),
sales_summary AS (
	SELECT
		model,
        SUM(CASE WHEN `year` = 2022 THEN total_sales END) 2022_sales,
        SUM(CASE WHEN `year` = 2023 THEN total_sales END) 2023_sales,
        SUM(CASE WHEN `year` = 2024 THEN total_sales END) 2024_sales
	FROM yearly_sales
    GROUP BY model
)
SELECT *
FROM sales_summary
WHERE 2022_sales <= 2023_sales AND 2023_sales <= 2024_sales;

-- Dealerships Total Revenue Compared
SELECT
	dealership_name,
	ROUND(SUM(sale_price)) total_revenue,
	RANK() OVER(ORDER BY (SUM(sale_price)) DESC) ranking
FROM dealerships d
JOIN sales s
	ON d.dealership_id = s.dealership_id
GROUP BY dealership_name
ORDER BY total_revenue DESC;

-- Average sale Price per Model per month
SELECT
	model,
	YEAR(sale_date) `year`,
    MONTH(sale_date) `month`,
    ROUND(AVG(sale_price)) avg_sale_price
FROM sales
GROUP BY model, `year`, `month`
ORDER BY 2 DESC, 3 DESC, 4 DESC;

-- Dealerships Improve/Decline In Performance Over Time
SELECT 
	*,
    CASE
		WHEN sales_change > 0 THEN 'Positive'
        WHEN sales_change < 0 THEN 'Negative'
        WHEN sales_change IS NULL THEN 'Starting Point'
        ELSE 'No Change'
        END sales_change_status
FROM(
	SELECT
		dealership_name,
		YEAR(sale_date) `year`,
		ROUND(SUM(sale_price)) total_sales,
		ROUND(SUM(sale_price)) - LEAD(ROUND(SUM(sale_price))) OVER (PARTITION BY dealership_name ORDER BY YEAR(sale_date) DESC) sales_change
	FROM dealerships d
	JOIN sales s
		ON d.dealership_id = s.dealership_id
		GROUP BY dealership_name, `year`) sales_diffdealerships
   ;

-- Models with Highest Profit Margin
WITH top_models AS (
	SELECT
		model,
		ROUND(SUM(sale_price - production_cost)) profit_margin
FROM sales
GROUP BY model
ORDER BY profit_margin DESC
LIMIT 5
)

SELECT
	s.model,
    YEAR(s.sale_date) `year`,
    ROUND(SUM(s.sale_price - s.production_cost)) yearly_profit
FROM sales s
JOIN top_models tm
	ON s.model = tm.model
GROUP BY s.model, year
ORDER BY s.model, year;
