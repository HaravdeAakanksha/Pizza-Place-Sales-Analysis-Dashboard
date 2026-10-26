/*
=========================================================
PROJECT: Pizza Place Sales Analysis
=========================================================

DATA SOURCE:
Kaggle - Pizza Place Sales Analysis dataset

TOOLS USED:
Python, Pandas, SQL Server, Power BI

PROJECT OVERVIEW:
This project analyses pizza sales data, including orders,
pizza types, categories, sizes, quantities, and prices.

KEY QUESTIONS:
1. Which pizzas generated the highest and lowest revenue?
2. Which pizza categories and sizes were most popular?
3. Which months had the highest and lowest sales?
4. How did sales change over time?
5. What can the business do to improve sales?

PROJECT GOAL:
To understand sales patterns, identify low-performing
products, and suggest ways to improve business performance.

-----------------------------------------------------------
*/


CREATE DATABASE Pizza_Place_Analysis;

USE Pizza_Place_Analysis;

---------------------------------
-- Data Quality 
---------------------------------
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'orders';

-- CHECK ORDERS
----------------------------------------------
SELECT TOP 10 *
FROM orders;

SELECT COUNT(*) AS Total_Orders
FROM orders;


-- CHECK ORDER DETAILS 
----------------------------------------------
SELECT TOP 10 *
FROM order_details;

SELECT COUNT(*) AS Total_Orders
FROM order_details;

SELECT DISTINCT(quantity)
FROM order_details
ORDER BY quantity;


-- CHECK PIZZA TYPES
----------------------------------------------
SELECT TOP 10 *
FROM pizza_types;

SELECT COUNT(*) AS Total_Orders
FROM pizza_types;

SELECT DISTINCT(category)
FROM pizza_types;

SELECT DISTINCT(name)
FROM pizza_types;


-- CHECK PIZZA
----------------------------------------------
SELECT TOP 10 *
FROM pizzas;

SELECT COUNT(*) AS Total_Orders
FROM pizzas;

SELECT DISTINCT(size)
FROM pizzas;


-- CHECK NULLS
----------------------------------------------
SELECT COUNT(*) AS Missing_Orders
FROM orders
WHERE order_id IS NULL;

SELECT COUNT(*) AS Missing_Order_Detalis
FROM order_details
WHERE order_details_id IS NULL;

SELECT COUNT(*) AS Missing_Pizza_Type
FROM pizza_types
WHERE pizza_type_id IS NULL;

SELECT COUNT(*) AS Missing_Pizza_Ids
FROM pizzas
WHERE pizza_id IS NULL;


-- CHECK ORDER_ID MISSING IN ORDER_DETAILS
----------------------------------------------
SELECT COUNT(*) AS Missing_Order_IDs
FROM order_details as OD
LEFT JOIN orders as O
ON OD.order_id = O.order_id
WHERE O.order_id IS NULL;


-- CHECK PIZZA_ID MISSING IN ORDER_DETAILS
----------------------------------------------
SELECT COUNT(*) AS Missing_Pizza_IDs
FROM order_details AS OD
LEFT JOIN pizzas AS P
ON OD.pizza_id = P.pizza_id
WHERE P.pizza_id IS NULL;


-- CHECK MISSING PIZZA TYPES IN PIZZA
----------------------------------------------
SELECT COUNT(*) AS Missing_Pizza_Types
FROM pizzas AS P
LEFT JOIN pizza_types AS PT
ON P.pizza_type_id = PT.pizza_type_id
WHERE PT.pizza_type_id IS NULL;


-- CHECK MISSING PIZZA NAME IN PIZZA TYPES
----------------------------------------------
SELECT COUNT(*) AS Missing_Pizza_Name
FROM pizzas AS P
LEFT JOIN pizza_types AS PT
ON P.pizza_type_id = PT.pizza_type_id
WHERE PT.name IS NULL;


-- CHECK DUPLICATES FOR ORDERS
----------------------------------------------
SELECT order_id, COUNT(*) AS Duplicate_Order_ID
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1; 


-- CHECK DUPLICATES FOR ORDER DETAILS
----------------------------------------------
SELECT order_details_id, COUNT(*) AS Duplicate_Order_ID 
FROM order_details
GROUP BY order_details_id
HAVING COUNT(*) > 1;


-- CHECK DUPLICATES FOR PIZZA TYPES
----------------------------------------------
SELECT pizza_type_id, COUNT(*) AS Duplicate_Pizza_Types
FROM pizza_types
GROUP BY pizza_type_id
HAVING COUNT(*) > 1;


-- CHECK DUPLICATES FOR PIZZA_ID
----------------------------------------------
SELECT pizza_id, COUNT(*) AS Duplicate_Pizza_IDs
FROM pizzas
GROUP BY pizza_id
HAVING COUNT(*) > 1;


-- TOTAL REVENUE BY CATEGORY
----------------------------------------------
SELECT PT.category,
ROUND(SUM(P.price * OD.quantity),2) AS Revenue
FROM order_details AS OD
JOIN pizzas AS P
ON OD.pizza_id = P.pizza_id
JOIN pizza_types AS PT
ON P.pizza_type_id = PT.pizza_type_id
GROUP BY PT.category
ORDER BY SUM(P.price * OD.quantity) DESC;


-- REVEUNE BY MONTH
----------------------------------------------
SELECT MONTH(O.date) AS Month,
ROUND(SUM(P.price * OD.quantity),2) as Monthly_Revenue
FROM order_details AS OD
JOIN pizzas AS P 
ON OD.pizza_id = P.pizza_id
JOIN orders AS O
ON OD.order_id = O.order_id
GROUP BY MONTH(O.date)
ORDER BY Month;


-- MONTH OVER MONTH
----------------------------------------------
WITH MonthlyRevenue	AS (
SELECT 
MONTH(O.date) AS Month,
ROUND(SUM(P.price * OD.quantity),2) AS Monthly_Revenue
FROM order_details AS OD
JOIN pizzas AS P 
ON OD.pizza_id = P.pizza_id
JOIN orders AS O
ON OD.order_id = O.order_id
GROUP BY MONTH(O.date)
),

ChangedRevenue AS (
SELECT 
Month,
Monthly_Revenue,
LAG(Monthly_Revenue) OVER(
ORDER BY Month
) AS Previous_Month_Revenue,
Monthly_Revenue - LAG(Monthly_Revenue) OVER (
ORDER BY Month
) AS Changed_Revenue
FROM MonthlyRevenue
)

SELECT 
*,
(Changed_Revenue / NULLIF(Previous_Month_Revenue, 0)) * 100.0
AS Month_Over_Month
FROM ChangedRevenue
ORDER BY Month;


-- AVERAGE PIZZA PER ORDER AND ORDER CONTAINING MOST PIZZAS
----------------------------------------------
SELECT
SUM(quantity) AS Total_Quantity,
SUM(quantity) * 1.0 / COUNT(DISTINCT order_id) AS Avg_Pizza
FROM order_details;

SELECT order_id,
SUM(quantity) AS Total_Quantity
FROM order_details
GROUP BY order_id
ORDER BY SUM(quantity);


-- LARGEST ORDER
----------------------------------------------
SELECT TOP
10 SUM(quantity) AS Total_Quantity,
order_id
FROM order_details
GROUP BY order_id
ORDER BY SUM(quantity) DESC;


-- Revenue per order
----------------------------------------------
SELECT TOP 10 OD.order_id,
ROUND(SUM(OD.quantity * P.price), 2) AS Revenue
FROM order_details AS OD
JOIN pizzas AS P 
ON OD.pizza_id = P.pizza_id
GROUP BY OD.order_id
ORDER BY Revenue DESC;


-- AOV
----------------------------------------------
SELECT
ROUND(SUM(P.price * OD.quantity), 2) AS Revenue,
COUNT(DISTINCT OD.order_id) AS Total_Orders,
SUM(P.price * OD.quantity) * 1.0 / COUNT(DISTINCT OD.order_id) AS A0V
FROM order_details AS OD
JOIN pizzas AS P
ON OD.pizza_id = P.pizza_id;


-- REVENUE BY PIZZA SIZE
----------------------------------------------
SELECT P.size, 
ROUND(SUM(P.price * OD.quantity), 2) AS Revenue,
SUM(OD.quantity) AS Total_Quantity,
SUM(P.price * OD.quantity) * 100.0 / SUM(SUM(P.price * OD.quantity)) OVER()
AS Revenue_Percentage
FROM order_details AS OD
JOIN pizzas AS P
ON OD.pizza_id = P.pizza_id
GROUP BY P.size
ORDER BY Revenue DESC;


-- REVENUE BY PIZZA SIZE AND CATEGORY
----------------------------------------------
SELECT
P.size,
PT.category,
SUM(P.price * OD.quantity) AS Revenue,
SUM(P.price * OD.quantity) * 100.0 / SUM(SUM(P.price * OD.quantity)) OVER() 
AS Percentage_Revenue
FROM order_details AS OD
JOIN pizzas AS P
ON OD.pizza_id = P.pizza_id
JOIN pizza_types AS PT
ON P.pizza_type_id = PT.pizza_type_id
GROUP BY P.size, PT.category
ORDER BY Revenue DESC;


-- TOP 3 RANK BY PIZZA REVENUE
----------------------------------------------
WITH PizzaRevenue AS (
SELECT 
PT.name,
SUM(P.price * OD.quantity) AS Revenue
FROM order_details AS OD
JOIN pizzas AS P
ON OD.pizza_id = P.pizza_id
JOIN pizza_types AS PT
ON P.pizza_type_id = PT.pizza_type_id
GROUP BY PT.name
),

RankPizzaType AS (
SELECT *, 
DENSE_RANK() OVER(
ORDER BY Revenue DESC
) AS Rank_Pizza_Type
FROM PizzaRevenue
)

SELECT *
FROM RankPizzaType
WHERE Rank_Pizza_Type <= 3 
ORDER BY Revenue DESC;


-- TOP 3 PIZZA TYPE WITH EACH CATEGORY
----------------------------------------------
WITH PizzaRevenue AS (
SELECT 
PT.category,
PT.name,
SUM(P.price * OD.quantity) AS Revenue
FROM order_details AS OD
JOIN pizzas AS P
ON OD.pizza_id = P.pizza_id
JOIN pizza_types AS PT
ON P.pizza_type_id = PT.pizza_type_id
GROUP BY PT.category, PT.name
),

RankByCategory AS (
SELECT *,
DENSE_RANK () OVER(
PARTITION BY category
ORDER BY Revenue DESC
) AS Rank_By_Category
FROM PizzaRevenue
)

SELECT *
FROM RankByCategory 
WHERE Rank_By_Category <= 3
ORDER BY Revenue DESC;


-- REVENUE CONTRIBUTION BY CATEGORY
----------------------------------------------
SELECT
SUM(P.price * OD.quantity) AS Revenue,
SUM(P.price * OD.quantity) * 100.0 / SUM(SUM(P.price * OD.quantity)) OVER () 
AS Percentage_Revenue,
PT.category
FROM order_details AS OD
JOIN pizzas AS P
ON OD.pizza_id = P.pizza_id
JOIN pizza_types AS PT
ON P.pizza_type_id = PT.pizza_type_id
GROUP BY PT.category;



-- SALES BY DAYS OF THE WEEK
----------------------------------------------
SELECT 
DATENAME(WEEKDAY, O.date) AS WeekdayName,
SUM(OD.quantity) AS Total_Quantity,
SUM(P.price * OD.quantity) AS REVENUE 
FROM order_details AS OD
JOIN orders AS O
ON OD.order_id  = O.order_id
JOIN pizzas AS P
ON OD.pizza_id = P.pizza_id
GROUP BY DATENAME(weekday, O.date)
ORDER BY SUM(OD.quantity);


-- SALES BY HOURS
----------------------------------------------
SELECT 
DATEPART(HOUR, O.time) AS Hours,
SUM(OD.quantity) AS Total_Quantity,
SUM(P.price * OD.quantity) AS Revenue
FROM orders AS O
JOIN order_details AS OD
ON O.order_id = OD.order_id
JOIN pizzas AS P
ON OD.pizza_id = P.pizza_id
GROUP BY DATEPART(HOUR, O.time)
ORDER BY SUM(P.price * OD.quantity) DESC;


-- WEEKDAY VS WEEKEND SALES
----------------------------------------------
SELECT
SUM(OD.quantity) AS Total_Quantity,
SUM(P.price * OD.quantity) AS Revenue,
CASE
WHEN
DATENAME(WEEKDAY, O.date) IN ('Saturday', 'Sunday')
THEN 'WEEKEND'
ELSE 'WEEKDAY'
END	AS [WEEKEND/WEEKDAYS]
FROM orders AS O
JOIN order_details AS OD
ON O.order_id = OD.order_id
JOIN pizzas AS P
ON OD.pizza_id = P.pizza_id
GROUP BY 
CASE
WHEN
DATENAME(WEEKDAY, O.date) IN ('Saturday', 'Sunday')
THEN 'WEEKEND'
ELSE 'WEEKDAY'
END
ORDER BY Revenue  DESC;


-- TOP AND BOTTOM PIZZA TYPE BY REVENUE 
----------------------------------------------
SELECT TOP 5
SUM(OD.quantity) AS Total_Quantity,
SUM(P.price * OD.quantity) AS Revenue,
PT.category,
PT.name
FROM order_details AS OD
JOIN pizzas AS P
ON OD.pizza_id = P.pizza_id 
JOIN pizza_types AS PT
ON P.pizza_type_id = PT.pizza_type_id
GROUP BY PT.category, PT.name
ORDER BY Revenue DESC;

SELECT TOP 5
SUM(OD.quantity) AS Total_Quantity,
SUM(P.price * OD.quantity) AS Revenue,
PT.category,
PT.name
FROM order_details AS OD
JOIN pizzas AS P
ON OD.pizza_id = P.pizza_id 
JOIN pizza_types AS PT
ON P.pizza_type_id = PT.pizza_type_id
GROUP BY PT.category, PT.name
ORDER BY Revenue;
----------------------------------------------------------------------


/*
Insights:

1. Lowest Month by Revenue is October it also has the lowest orders. so we could try some offers during this month.

2. Classic made the most revenue and sold the most pizza, while Veggie made the least revenue. Chicken had the fewest pizzas sold.

3. Even though Chicken sold the least pizza it was the highest pizza sold in every category while Veggie was the least category what sold pizza and also made the least revenue.

4. We can give combo offers on Veggies Pizza and see if customers give good response on Sales as well as on revenues. 

*/



