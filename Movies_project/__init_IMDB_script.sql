
-- 1000 самых оцененных фильмов
SELECT t2.primarytitle, t1.numvotes, t1.averagerating
	FROM title_ratings as t1
	LEFT JOIN title_basics as t2
		using(tconst)
	where titletype in ('movie','tvMovie')
	and numvotes > (select ceil(avg(numvotes)) -- фильтр по количеству голосов чтобы убрать малоизвестные фильмы с высокими оценками
						FROM title_ratings
						left join title_basics
							using(tconst)
						where titletype in ('movie','tvMovie'))
	order by 3 desc, 2 desc
	limit 1000;   /* результат показывает, что требуется определить иной порог по количеству голосов,
					т.к. вверху списка много малоизвестных фильмов с кол-ом голосов < 5_000 */

	
	SELECT CEIL(AVG(t1.numvotes)) AS avg,
			CEIL(MAX(t1.numvotes)) AS max,
			CEIL(PERCENTILE_CONT(0.5)
				WITHIN GROUP(ORDER BY numvotes)) AS median,
			CEIL(PERCENTILE_CONT(0.75)
				WITHIN GROUP(ORDER BY numvotes)) AS prcntl_75,
			CEIL(PERCENTILE_CONT(0.95)
				WITHIN GROUP(ORDER BY numvotes)) AS prcntl_95,
			CEIL(PERCENTILE_CONT(0.99)
				WITHIN GROUP(ORDER BY numvotes)) AS prcntl_99
						FROM title_ratings AS t1
						LEFT JOIN title_basics AS t3
							USING(tconst)
						WHERE t3.titletype IN ('movie','tvMovie');
						/* даже на 99м процентиле у фильма всего 59_748 оценок, в то время как максимальное значение 2_639_662.
						 * в связи с этим отбор "лучших" будет происходить в первую очередь по количеству оценок*/

					
-- #1.Самые оцениваемые фильмы по убыванию кол-ва голосов
SELECT t2.tconst AS ID, t2.primarytitle AS MovieName, t2.startyear AS ReleaseYear, t1.numvotes AS Votes, t1.averagerating AS AvgRaiting
	FROM title_ratings AS t1
	LEFT JOIN title_basics AS t2
		USING(tconst)
	WHERE titletype IN ('movie','tvMovie')
	AND numvotes > (SELECT ceil(avg(numvotes))
						FROM title_ratings
						LEFT JOIN title_basics
							USING(tconst)
						WHERE titletype IN ('movie','tvMovie'))
	ORDER BY 4 DESC, 5 DESC; 
	

-- #2.Самые оцениваемые сериалы по убыванию кол-ва голосов
SELECT t2.tconst AS ID, t2.primarytitle AS SeriesName, t2.startyear AS ReleaseYear, t1.numvotes AS Votes, t1.averagerating AS AvgRaiting
	FROM title_ratings AS t1
	LEFT JOIN title_basics AS t2
		USING(tconst)
	WHERE titletype IN ('tvSeries','tvMiniSeries')
	AND numvotes > (SELECT ceil(avg(numvotes))
						FROM title_ratings
						LEFT JOIN title_basics
							USING(tconst)
						WHERE titletype IN ('tvSeries','tvMiniSeries'))
	ORDER BY 4 DESC, 5 DESC;


-- средняя продолжительность фильма каждые 25 лет с начала времен

SELECT MIN(startyear ), MAX(startyear), MAX(startyear)::int -  MIN(startyear)::int AS years_gap -- 1894 - 2029 = 135 всего лет выпуска фильмов в датасете
	FROM title_basics
	WHERE startyear <> '\N'
	AND titletype in ('movie','tvMovie')
	

SELECT CASE WHEN startyear::int < 1930
				THEN '1894-1929'
			WHEN startyear::int < 1955
				THEN '1930-1954'
			WHEN startyear::int < 1980
				THEN '1955-1979'
			WHEN startyear::int < 2005
				THEN '1980-2004'
			ELSE '2005-2029' END AS YearPeriod,
		CEIL(AVG(runtimeminutes::int)) AS AvgRuntime
	FROM title_basics
		WHERE titletype in ('movie','tvMovie')
		AND startyear <> '\N'
		AND runtimeminutes <> '\N'
	GROUP BY 1
	ORDER BY 1 -- средняя длина фильма держится на уровне ~87мин с 1930, ранее было ~60мин


/* #3.Запрос для визулизации, которая ответит на вопросы:
1) наиболее прибыльные/убыточные фильмы и сериалы
2) рост бюджетов/выручки/прибыли фильмов и сериалов по годам
3) корелляция бюджет - прибыль
4) корелляция прибыль - кол-во голосов */


WITH query_in AS (SELECT a.imdb_id AS ID, t.titletype AS ContentType,
					a.title AS Name, t.startyear AS ReleaseYear,
				a.budget, a.revenue, a.revenue - a.budget AS profit,
				ROW_NUMBER() OVER(ORDER BY (a.revenue - a.budget) DESC) AS profit_rank
						FROM additional_revenue AS a
							LEFT JOIN title_basics AS t
								ON imdb_id = tconst
						WHERE a.budget <> 0
						AND a.revenue <> 0
						AND t.titletype IN ('movie','tvMovie','tvSeries','tvMiniSeries'))
SELECT ID, ContentType, Name, ReleaseYear,
		budget, revenue, profit, profit_rank,
		CASE WHEN profit_rank <= 15
				OR profit_rank >= (SELECT MAX(profit_rank) FROM query_in) - 15
			THEN 'Y' ELSE 'N'
				END AS Top_worse_15_profit
	FROM query_in
	WHERE ContentType = 'tvSeries'
ORDER BY 7 DESC;


/* #4. Фанфакты по сериалам
-- сериал с самым большим количеством серий и/или диапазоном лет выпуска
-- самый длинный сериал по сумме часов просмотра
-- тенденции по кол-ву серий и пр.
-- удельная прибыль на одну серию */

SELECT t1.tconst AS ID, t1.primarytitle AS SeriesName, t1.startyear AS ReleaseYear, t1.runtimeminutes AS EpisodeLengthMins,
		t2.Seasons, t2.Episodes, t1.endyear::int - t1.startyear::int AS ShowYears
	FROM title_basics AS t1
	INNER JOIN (SELECT parenttconst,
				COUNT(DISTINCT seasonnumber) AS Seasons, 
				COUNT(DISTINCT CONCAT(seasonnumber,episodenumber)) AS Episodes
					FROM title_episode
					WHERE seasonnumber <> '\N'
					AND episodenumber <> '\N'
				GROUP BY 1) AS t2
		ON t1.tconst = t2.parenttconst
	WHERE t1.titletype IN ('tvSeries','tvMiniSeries')
	AND t1.runtimeminutes <> '\N'
	AND t1.startyear <> '\N'
	AND t1.endyear <> '\N'
	ORDER BY 3
				
	
	
-- фильм переведенный на большее количество языков / и сериал

-- режиссер самых положительно оцениваемых фильмов
-- актер самых положительно оцениваемых фильмов
-- аналогично по сериалам

-- самые положительно оцениваемые жанры с начала времен
-- самые положительно оцениваемые жанры по декадам
-- популярность различных жанров по декадам
-- С ЖАНРАМИ ЧТО-ТО НЕ ЗАДАЛОСЬ =(
	
