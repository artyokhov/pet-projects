SELECT *
FROM retail_sales;

-- требуется убедиться, что в датасете нет NULL записей

SELECT key as field_name, count(*) as null_values_count
FROM retail_sales
CROSS JOIN jsonb_each_text(to_jsonb(retail_sales))
WHERE value IS NULL
GROUP BY key;
-- в столбцах исходной таблицы нет NULL


-- требуется убедиться, что в данных нет отрицательных или нулевых значений в Sell Price, Cost Price или Total Units

SELECT COUNT(*)
FROM retail_sales
WHERE "Cost Price" <= 0 OR "Sale Price" <= 0 OR "Total Units" <= 0;
-- в датасете 426 записей, отвечающих данным параметрам
-- записи с отрицательным значением в поле Total Units, но положительными в остальных полях, можно считать возвратом товара
-- остальные записи невалидны, могут быть ошибкой ввода


SELECT COUNT(*)
FROM retail_sales
WHERE "Cost Price" <= 0 OR "Sale Price" <= 0;
-- 58 записей имеют либо отрицательную цену продажи, либо отрицательную себестоимость
-- в рамках тестового задания данные записи не будут удалены из базы, для воспроизводимости
-- вместо этого будет создано доп.поле для их фильтрации

ALTER TABLE retail_sales 
ADD COLUMN filter_of_invalid VARCHAR;

UPDATE retail_sales
SET filter_of_invalid = 'inval'
WHERE "Cost Price" <= 0 OR "Sale Price" <= 0;


-- далее можно провести сравнительный анализ год к году

-- за какие года есть данные о продажах в датасете и все ли месяцы представлены?

SELECT DISTINCT EXTRACT(MONTH FROM (CAST("Date" AS DATE))) AS Month, 
				EXTRACT(YEAR FROM (CAST("Date" AS DATE))) AS Year
FROM retail_sales
ORDER BY 2,1;
-- данные за 2016-2017 годы, за 2017 данные только за 8 месяцев
-- year-over-year анализ будет проводиться с учетом того, что данные за 2017 неполные, т.е. учитываться будут данные с 1 по 8 месяц


-- #1. как изменилось количество сделок на продажу за первые 8 месяцев в 2016 и 2017?

WITH deals_by_year AS
		(SELECT EXTRACT(YEAR FROM (CAST("Date" AS DATE))) AS Year,
					COUNT(*) AS deals_number
			FROM retail_sales
			WHERE EXTRACT(MONTH FROM (CAST("Date" AS DATE))) <= 8
				AND filter_of_invalid IS NULL
				AND "Total Units" >= 0		
			GROUP BY 1)
SELECT Year,
		deals_number,
		COALESCE(((ROUND(deals_number::DECIMAL / (LAG(deals_number) OVER()),4) - 1) * 100),0) AS increase_to_prev_year
FROM deals_by_year;
-- прирост по количеству сделок составил 5,75%

			
-- #2. как изменилось количество сделок на продажу за первые 8 месяцев в 2016-2017 по категориям?

WITH deals_num_by_category_2016 AS
		(SELECT EXTRACT(YEAR FROM (CAST("Date" AS DATE))) AS Year,
			category,
			COUNT(*) AS deals_number
		FROM retail_sales
		WHERE EXTRACT(MONTH FROM (CAST("Date" AS DATE))) <= 8
				AND EXTRACT(YEAR FROM (CAST("Date" AS DATE))) = 2016
				AND filter_of_invalid IS NULL
				AND "Total Units" >= 0
		GROUP BY 1,2),
	deals_num_by_category_2017 AS
		(SELECT EXTRACT(YEAR FROM (CAST("Date" AS DATE))) AS Year,
			category,
			COUNT(*) AS deals_number
		FROM retail_sales
		WHERE EXTRACT(YEAR FROM (CAST("Date" AS DATE))) = 2017
		AND filter_of_invalid IS NULL
		AND "Total Units" >= 0
		GROUP BY 1,2)
SELECT t1.category,
		t1.deals_number AS deals_num_2016,
		t2.deals_number AS deals_num_2017,
		ROUND((t2.deals_number::DECIMAL / t1.deals_number) * 100 - 100,2) AS increase_2017_to_2016_in_perc
FROM deals_num_by_category_2016 AS t1
LEFT JOIN deals_num_by_category_2017 AS t2
USING (category)
ORDER BY 4 DESC;
-- обращает на себя внимание прирост по категориям Womens, Hosiery, Home и падение по Mens, Intimate


-- #3. как изменилась выручка и прибыль 2016-2017?
WITH profit_revenue_total AS 
		(SELECT EXTRACT(YEAR FROM (CAST("Date" AS DATE))) AS Year,
				ROUND(SUM("Sale Price" * "Total Units")::DECIMAL) AS Revenue,
				ROUND(SUM(("Sale Price" - "Cost Price") * "Total Units")::DECIMAL) AS Profit
		FROM retail_sales
		WHERE EXTRACT(MONTH FROM (CAST("Date" AS DATE))) <= 8
		AND filter_of_invalid IS NULL
		AND "Total Units" >= 0
		GROUP BY 1)
SELECT t1.Revenue AS Revenue_2016,
		t2.Revenue AS Revenue_2017,
		ROUND(t2.Revenue::DECIMAL / t1.Revenue * 100 - 100, 2) AS Revenue_increase,
		t1.Profit AS Profit_2016,
		t2.Profit AS Profit_2017,
		ROUND(t2.Profit::DECIMAL / t1.Profit * 100 - 100, 2) AS Profit_increase
FROM profit_revenue_total AS t1
LEFT JOIN profit_revenue_total AS t2
ON t1.year = t2.year-1
WHERE t1.year = 2016;
-- прирост выручки составил 8,84%, прирост прибыли - 13,36%

		
-- #4.как изменилась средняя прибыль за сделку в 2016-2017?

WITH profit_per_deal_by_year AS
		(SELECT EXTRACT(YEAR FROM (CAST("Date" AS DATE))) AS Year,
				ROUND(AVG(("Sale Price" - "Cost Price") * "Total Units")::DECIMAL,2) AS Avg_profit	
		FROM retail_sales
		WHERE EXTRACT(MONTH FROM (CAST("Date" AS DATE))) <= 8
		AND filter_of_invalid IS NULL
		AND "Total Units" >= 0
		GROUP BY 1)
SELECT t1.Avg_profit AS Avg_profit_per_deal_2016,
		t2.Avg_profit AS Avg_profit_per_deal_2017,
		ROUND((t2.Avg_profit / t1.Avg_profit) * 100 - 100,2) AS increase_2017_to_2016_in_perc
FROM profit_per_deal_by_year AS t1
LEFT JOIN profit_per_deal_by_year AS t2
ON t1.year = t2.year-1
WHERE t1.year = 2016;
-- на 1.95% упала средняя прибыль за сделку


-- #5. как изменилась средняя прибыль за сделку за первые 8 месяцев в 2016-2017 по категориям?

WITH profit_per_deal_by_category_2016 AS
		(SELECT EXTRACT(YEAR FROM (CAST("Date" AS DATE))) AS Year,
				category,
				ROUND(AVG(("Sale Price" - "Cost Price") * "Total Units")::DECIMAL,2) AS avg_profit
		FROM retail_sales
		WHERE EXTRACT(MONTH FROM (CAST("Date" AS DATE))) <= 8
				AND EXTRACT(YEAR FROM (CAST("Date" AS DATE))) = 2016
				AND filter_of_invalid IS NULL
				AND "Total Units" >= 0
		GROUP BY 1,2),
		profit_per_deal_by_category_2017 AS
		(SELECT EXTRACT(YEAR FROM (CAST("Date" AS DATE))) AS Year,
				category,
				ROUND(AVG(("Sale Price" - "Cost Price") * "Total Units")::DECIMAL,2) AS avg_profit
		FROM retail_sales
		WHERE EXTRACT(YEAR FROM (CAST("Date" AS DATE))) = 2017
				AND filter_of_invalid IS NULL
				AND filter_of_invalid IS NULL
				AND "Total Units" >= 0
		GROUP BY 1,2)
SELECT t1.category,
		t1.avg_profit AS avg_profit_2016,
		t2.avg_profit AS avg_profit_2017,
		ROUND(t2.avg_profit / t1.avg_profit * 100 - 100,2) AS increase_2017_to_2016_in_perc
FROM profit_per_deal_by_category_2016 AS t1
LEFT JOIN profit_per_deal_by_category_2017 AS t2
USING (category)
ORDER BY 4 DESC;
-- обращает на себя внимание прирост по категориям Womens, Intimate и падение по Groceries


-- #6. как изменилась средняя рентабельность продаж за сделку за первые 8 месяцев в 2016-2017?

WITH margin_per_deal_by_year AS
		(SELECT EXTRACT(YEAR FROM (CAST("Date" AS DATE))) AS Year,
				ROUND(((AVG(("Sale Price" - "Cost Price") * "Total Units") / AVG("Sale Price" * "Total Units")) * 100)::DECIMAL, 2) AS avg_margin	
		FROM retail_sales
		WHERE EXTRACT(MONTH FROM (CAST("Date" AS DATE))) <= 8
		AND filter_of_invalid IS NULL
		AND "Total Units" >= 0
		GROUP BY 1)
SELECT t1.avg_margin AS avg_margin_2016,
		t2.avg_margin AS avg_margin_2017,
		t2.avg_margin - t1.avg_margin AS increase_2017_to_2016_in_perc
FROM margin_per_deal_by_year AS t1
LEFT JOIN margin_per_deal_by_year AS t2
ON t1.year = t2.year-1
WHERE t1.year = 2016
-- на 0.68% выросла средняя маржинальность за сделку в 2017 к 2016


-- #7. как изменилась средняя рентабельность продаж за сделку за первые 8 месяцев в 2016-2017 по категориям?

WITH margin_per_deal_by_category_2016 AS
		(SELECT EXTRACT(YEAR FROM (CAST("Date" AS DATE))) AS Year,
				category,
				ROUND(((AVG(("Sale Price" - "Cost Price") * "Total Units") / AVG("Sale Price" * "Total Units")) * 100)::DECIMAL, 2) AS avg_margin
		FROM retail_sales
		WHERE EXTRACT(MONTH FROM (CAST("Date" AS DATE))) <= 8
				AND EXTRACT(YEAR FROM (CAST("Date" AS DATE))) = 2016
				AND filter_of_invalid IS NULL
				AND "Total Units" >= 0				
		GROUP BY 1,2),
		margin_per_deal_by_category_2017 AS
		(SELECT EXTRACT(YEAR FROM (CAST("Date" AS DATE))) AS Year,
				category,
				ROUND(((AVG(("Sale Price" - "Cost Price") * "Total Units") / AVG("Sale Price" * "Total Units")) * 100)::DECIMAL, 2) AS avg_margin
		FROM retail_sales
		WHERE EXTRACT(YEAR FROM (CAST("Date" AS DATE))) = 2017
				AND filter_of_invalid IS NULL
				AND "Total Units" >= 0			
		GROUP BY 1,2)
SELECT t1.category,
		t1.avg_margin AS avg_margin_2016,
		t2.avg_margin AS avg_margin_2017,
		t2.avg_margin - t1.avg_margin AS increase_2017_to_2016_in_perc
FROM margin_per_deal_by_category_2016 AS t1
LEFT JOIN margin_per_deal_by_category_2017 AS t2
USING (category)
ORDER BY 4 DESC;
-- обращает на себя внимание прирост по категориям Womens, Juniors и падение по Kids

-- данных по изменению прибыли, маржинальности и количества сделок по категориям достаточно для year-to-year анализа
		

-- далее можно провести общую оценку эффективности бизнеса по штатам, категориям и менеджерам по данным 2017 года

-- #8. какой штат приносит наибольшую выручку и прибыль?

SELECT state,
		ROUND(SUM("Sale Price" * "Total Units")) AS revenue,
		ROUND(SUM(("Sale Price" - "Cost Price") * "Total Units")) AS profit,
		ROUND((SUM(("Sale Price" - "Cost Price") * "Total Units") / SUM("Sale Price" * "Total Units"))::DECIMAL * 100,2) AS margin
FROM retail_sales AS t1
LEFT JOIN retail_state AS t2
USING (postcode)
WHERE EXTRACT(YEAR FROM (CAST("Date" AS DATE))) = 2017
		AND filter_of_invalid IS NULL
		AND "Total Units" >= 0	
GROUP BY 1
ORDER BY 3 DESC;
-- New South Wales


-- #9. каким будет рейтинг категорий по рентабельности?

SELECT category,
		ROUND(SUM("Sale Price" * "Total Units")) AS revenue,
		ROUND(SUM(("Sale Price" - "Cost Price") * "Total Units")) AS profit,
		ROUND((SUM(("Sale Price" - "Cost Price") * "Total Units") / SUM("Sale Price" * "Total Units"))::DECIMAL * 100,2) AS margin
FROM retail_sales AS t1
WHERE EXTRACT(YEAR FROM (CAST("Date" AS DATE))) = 2017
		AND filter_of_invalid IS NULL
		AND "Total Units" >= 0	
GROUP BY 1
ORDER BY 3 DESC;
-- категория Mens наиболее рентабельная


-- #10. каким будет рейтинг менеджеров по прибыли и какие у них показатели выручки и рентабелньости?

SELECT manager,
		ROUND(SUM("Sale Price" * "Total Units")) AS revenue,
		ROUND(SUM(("Sale Price" - "Cost Price") * "Total Units")) AS profit,
		ROUND((SUM(("Sale Price" - "Cost Price") * "Total Units") / SUM("Sale Price" * "Total Units"))::DECIMAL * 100,2) AS margin
FROM retail_sales AS t1
LEFT JOIN retail_manager
USING (postcode)
WHERE EXTRACT(YEAR FROM (CAST("Date" AS DATE))) = 2017
		AND filter_of_invalid IS NULL
		AND "Total Units" >= 0	
GROUP BY 1
ORDER BY 3 DESC;
-- менеджер Lillian Pruitt приносит наибольшую прибыль


-- #11. каким будет отрицательный рейтинг менеджеров по размеру суммарного убытка на сделках с отрицательной доходностью?

SELECT manager,
		COUNT(*) AS number_of_not_profitable_deals,
		ROUND(SUM(("Sale Price" - "Cost Price") * "Total Units")::DECIMAL,2) AS losses_amount
FROM retail_sales
LEFT JOIN retail_manager
USING (postcode)
WHERE "Sale Price" < "Cost Price"
	AND EXTRACT(YEAR FROM (CAST("Date" AS DATE))) = 2017
	AND filter_of_invalid IS NULL
	AND "Total Units" >= 0
GROUP BY 1
ORDER BY 3;
-- менеджер Terri Wright принес наибольший убыток на убыточных сделках


-- #12. каким будет отрицательный рейтинг категорий по сумме убытка на убыточных сделках и на каком месте находится категория в рейтинге по количеству убыточных сделок?

SELECT category,
		COUNT(*) AS number_of_nonprofit_deals,
		ROW_NUMBER() OVER(ORDER BY COUNT(*) DESC) AS raiting_by_number_of_nonprofit_deals,
		ROUND(SUM(("Sale Price" - "Cost Price") * "Total Units")::DECIMAL) AS total_losses	
FROM retail_sales
WHERE "Sale Price" < "Cost Price"
	AND EXTRACT(YEAR FROM (CAST("Date" AS DATE))) = 2017
	AND filter_of_invalid IS NULL
	AND "Total Units" >= 0	
GROUP BY 1
ORDER BY 4;
-- в категории Home наибольший суммарный убыток



-- #13. для визуализации данных будет использован следующий запрос
SELECT "Date"::DATE,
		Category,
		"Total Units",
		"Sale Price",
		"Cost Price",
		"Total Units" * "Sale Price" AS revenue,
		"Total Units" *  ("Sale Price" - "Cost Price") AS profit,
		("Sale Price" - "Cost Price") / "Sale Price" AS margin,
		manager,
		state
FROM retail_sales
LEFT JOIN retail_manager
USING (postcode)
LEFT JOIN retail_state
USING (postcode)
WHERE EXTRACT(MONTH FROM (CAST("Date" AS DATE))) <= 8
		AND filter_of_invalid IS NULL
		AND "Total Units" >= 0		
ORDER BY 1
