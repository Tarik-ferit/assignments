


/*Generate a report included product IDs and discount effects on whether the increase 
in the discount rate positively impacts the number of orders for the products.*/



--PRODUCT			discount_effect
--1					positive







WITH T1 AS (
SELECT	product_id, discount, SUM(quantity) total_qty
FROM	sale.order_item
GROUP BY
		product_id, discount
)
, T2 AS (
SELECT *, 
		FIRST_VALUE(total_qty) OVER (PARTITION BY product_id ORDER BY discount) min_discount_quantity,
		LAST_VALUE(total_qty) OVER (PARTITION BY product_id ORDER BY discount ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) max_discount_quantity		
FROM	T1
)
SELECT	DISTINCT product_id, 
		CASE WHEN 1.0*(max_discount_quantity - min_discount_quantity) / min_discount_quantity > 0 THEN 'Positive' 
				WHEN	1.0*(max_discount_quantity - min_discount_quantity) / min_discount_quantity < 0 THEN 'Negative'
				ELSE 'Neutral' END AS Discount_Effect
FROM	T2



-------------
--Solution 2


WITH CTE AS(
	SELECT *, 
			--calculation of the discount weighted average by quantity 
			CAST(SUM(discount * total_quantity)  OVER(PARTITION BY product_id) /SUM(total_quantity) OVER(PARTITION BY product_id) AS FLOAT) avg_discount,

			--calculation the difference between the discount and the discount weighted average
			CAST(SUM(discount * total_quantity)  OVER(PARTITION BY product_id) /SUM(total_quantity) OVER(PARTITION BY product_id) - discount AS FLOAT) avg_discount_diff
	FROM (
		SELECT DISTINCT oi.product_id, discount,

				--calculation of quantity to each discount of each product
				SUM(quantity) OVER(PARTITION BY oi.product_id, discount) total_quantity				
				
		FROM sale.order_item oi
			INNER JOIN product.product p ON oi.product_id = p.product_id
			INNER JOIN sale.orders o ON oi.order_id = o.order_id
		) sqry
), 
CTE2  AS(
	SELECT *, 

	--calculation the sum of the differences (discount from discount weighted average) 
	SUM(avg_discount_diff) OVER(PARTITION BY product_id)  avg_discount_diff_total
	FROM CTE )
SELECT DISTINCT product_id,

			---decision making about discount effect
		CASE	WHEN avg_discount_diff_total = 0 THEN 'Neutral' 
				WHEN avg_discount_diff_total > 0 THEN 'Positive' 
				ELSE 'Negative' 
		END discount_effect
FROM CTE2
ORDER BY product_id;




------Solution 3



SELECT
	product_id,
	--correlation,
	CASE
		WHEN correlation < 0 THEN 'Negative' 
		WHEN correlation = 0 THEN 'Neutral'
		WHEN correlation > 0 THEN 'Positive'
	END AS [Discount Effect]
FROM(
SELECT
  product_id,
  (
    SUM((discount - avg_discount) * (quantity - avg_quantity))
    / (COUNT(*) - 1) 
  ) / (CASE WHEN STDEV(discount) = 0 THEN 1 ELSE STDEV(discount) END * CASE WHEN STDEV(quantity) = 0 THEN 1 ELSE STDEV(quantity) END) as correlation
FROM (
  SELECT
    product_id,
    discount,
    quantity,
    AVG(discount) OVER(PARTITION BY product_id) as avg_discount,
    AVG(quantity * 1.0) OVER(PARTITION BY product_id) as avg_quantity
  FROM sale.order_item
) as subquery
GROUP BY product_id
HAVING COUNT(*) > 1
) AS corelation



----------



---Solution 4

SELECT product_id, discount_effect
FROM (
SELECT DISTINCT product_id,
	FIRST_VALUE(discount) OVER (PARTITION BY product_id ORDER BY total_qnty DESC , discount DESC) discount_rate_max_sale, -- if max quantity sold matches multiple discount rates, I want to choose the higher discount rate, hence the descending order by discount.
	FIRST_VALUE(total_qnty) OVER (PARTITION BY product_id ORDER BY total_qnty DESC, discount DESC) max_qnty,
	FIRST_VALUE(discount) OVER (PARTITION BY product_id ORDER BY total_qnty ASC, discount ASC) discount_rate_min_sale,
	FIRST_VALUE(total_qnty) OVER (PARTITION BY product_id ORDER BY total_qnty ASC, discount ASC) min_qnty,
	FIRST_VALUE(discount) OVER (PARTITION BY product_id ORDER BY total_qnty DESC , discount DESC) - FIRST_VALUE(discount) OVER (PARTITION BY product_id ORDER BY total_qnty ASC, discount ASC) discount_diff,
	CASE
		WHEN FIRST_VALUE(discount) OVER (PARTITION BY product_id ORDER BY total_qnty DESC , discount DESC) - FIRST_VALUE(discount) OVER (PARTITION BY product_id ORDER BY total_qnty ASC, discount ASC) > 0 THEN 'positive'
		WHEN FIRST_VALUE(discount) OVER (PARTITION BY product_id ORDER BY total_qnty DESC , discount DESC) - FIRST_VALUE(discount) OVER (PARTITION BY product_id ORDER BY total_qnty ASC, discount ASC) < 0 THEN 'negative'
		ELSE 'neutral'
		END AS discount_effect
FROM(
	SELECT product_id, discount, SUM(quantity) total_qnty,
		COUNT(discount) OVER (PARTITION BY product_id) num_of_discount_rates
	FROM sale.order_item
	GROUP BY product_id, discount
	/*ORDER BY product_id */) subq
	WHERE num_of_discount_rates > 1 -- I select products with multiple discount rates only
) A;




---Solution 5


CREATE VIEW discount_effect AS
WITH t1 AS
	(
	SELECT	product_id,
			discount,
			cnt_of_orders,
			sum_of_quantities,
			sum_of_quantities - LAG(sum_of_quantities) OVER (PARTITION BY product_id ORDER BY product_id) AS diff_quantities
	FROM (
		SELECT	DISTINCT
				product_id,
				discount,
				COUNT(order_id) OVER(PARTITION BY product_id, discount) AS cnt_of_orders,
				SUM(quantity) OVER(PARTITION BY product_id, discount) AS sum_of_quantities
		FROM sale.order_item
		) AS subq
		)
SELECT  product_id,
		discount,
		cnt_of_orders,
		sum_of_quantities,
		diff_quantities,
		SUM(diff_quantities) OVER(PARTITION BY product_id) AS sum_diff
FROM	t1;


SELECT	product_id,
		Discount_Effect
FROM (		
		SELECT	 product_id,
				 CASE
					WHEN sum_diff > 0 THEN 'Positive'
					WHEN sum_diff < 0 THEN 'Negative'
					ELSE 'Neutral'
				 END AS Discount_Effect
		FROM	 discount_effect
	) AS subq
GROUP BY product_id, Discount_Effect
ORDER BY 1;











