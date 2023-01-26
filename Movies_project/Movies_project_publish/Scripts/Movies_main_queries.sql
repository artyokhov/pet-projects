
-- Чтобы собрать данные по фильмам, вошедшим в рейтинг сайта Mojo, используется запрос ниже
-- В рейтинге Mojo нет идентификаторов лент, кроме названия и года выпуска, поэтому из данных будут исключены фильмы с одинаковым названием внутри общего года выпуска
-- Данные будут агрегироваться по декадам, поэтому будут учитываться только ленты выпущенные до 2020

SELECT 	t2.tconst,  -- уникальный идентификатор ленты
		CONCAT(t1.title, ' (',t1.release_year::VARCHAR, ')') AS Title_year,
		t1.release_year,
		to_date(t3.release_date, 'DD/MM/YYYY') AS release_date,
		t3.budget,
		t1.worldwide_box_office,
		t1.domestic_box_office,
		t1.foreign_box_office,
		ROUND(t4.averagerating::DECIMAL, 2) AS imdb_raiting,
		t4.numvotes,
		SUBSTRING(t2.genres, 1, CASE
								WHEN t2.genres LIKE '%,%' THEN POSITION(',' IN t2.genres)-1
								WHEN t2.genres NOT LIKE '%,%' THEN LENGTH(t2.genres)
								END) AS genre
FROM box_office AS t1  -- список фильмов и данные по сборам
LEFT JOIN (SELECT tconst, primarytitle, startyear, genres
			FROM title_basics
			WHERE CONCAT(primarytitle,startyear) IN (SELECT titleyear
														FROM (SELECT CONCAT(primarytitle, startyear) AS titleyear, COUNT(primarytitle)
																FROM title_basics
																WHERE titletype = 'movie'
																GROUP BY 1
																HAVING COUNT(primarytitle) = 1) x) -- из выборки исключаются ленты с одинаковым названием внутри года
			AND titletype = 'movie') AS t2
	ON t1.title = t2.primarytitle
	AND CAST(t1.release_year AS VARCHAR)  = t2.startyear
LEFT JOIN budgets_and_meta AS t3
	ON t2.tconst = t3.imdb_id
LEFT JOIN title_ratings AS t4
	USING(tconst)
WHERE t1.release_year <= 2019
ORDER BY 2, 3 DESC;




-- для сбора данных по "людаям", т.е. актерам, режиссерам и продюссерам будет использован следующий запрос

WITH box_office_data AS (SELECT 	t2.tconst,  -- уникальный идентификатор ленты
									t1.worldwide_box_office
							FROM box_office AS t1  -- список фильмов и данные по сборам
							LEFT JOIN (SELECT tconst, primarytitle, startyear, genres
										FROM title_basics
										WHERE CONCAT(primarytitle,startyear) IN (SELECT titleyear
																					FROM (SELECT CONCAT(primarytitle, startyear) AS titleyear, COUNT(primarytitle)
																							FROM title_basics
																							WHERE titletype = 'movie'
																							GROUP BY 1
																							HAVING COUNT(primarytitle) = 1) x) -- из выборки исключаются ленты с одинаковым названием внутри года
										AND titletype = 'movie') AS t2
								ON t1.title = t2.primarytitle
								AND CAST(t1.release_year AS VARCHAR)  = t2.startyear
							WHERE tconst IS NOT NULL)
SELECT nconst AS person_id,
		primaryname AS name,
		category AS ocupation,
		COUNT(DISTINCT tconst) AS number_of_movies,
		SUM(worldwide_box_office) AS total_box_office
FROM title_principals
LEFT JOIN name_basics
	USING(nconst)
LEFT JOIN box_office_data
	USING (tconst)
WHERE category IN ('actor', 'actress', 'producer', 'director')
AND worldwide_box_office IS NOT NULL
GROUP BY 1,2,3

