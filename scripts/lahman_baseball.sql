
-- 1. What range of years for baseball games played does the provided database cover? 

SELECT 
	MIN (year)
	, MAX (year) 
	, COUNT(DISTINCT(year)) AS num_years
FROM homegames;

1871 - 2016

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
   
SELECT
	p.namefirst AS first_name
	, p.namelast AS last_name
	, p.height AS height_in_inches
	, a.g_all AS games_played
	, t.name
FROM
	appearances AS a
LEFT JOIN
	people AS p
USING (playerid)
LEFT JOIN
	teams AS t
USING (teamid, yearid)
ORDER BY height
LIMIT 1;

	Eddit Gaedel, He was 3 foot 9. Played in 1 game for the St Louis Browns

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

WITH collegeid AS
	(SELECT 
		DISTINCT (playerid)
		, schoolid
	FROM 
		collegeplaying) 
SELECT
	p.namefirst AS first_name
	, p.namelast AS last_name
	, sch.schoolname AS college
	, SUM(sal.salary) AS total_salary
FROM
	people AS p
LEFT JOIN 
	salaries AS sal
ON
	p.playerid = sal.playerid
LEFT JOIN
	collegeid
ON
	p.playerid = collegeid.playerid
LEFT JOIN
	schools AS sch
ON
	collegeid.schoolid = sch.schoolid
GROUP BY 1,2,3
HAVING LOWER(sch.schoolname) LIKE '%vand%'
ORDER BY SUM(sal.salary) DESC NULLS LAST;

David Price at the time had earned $81,851,296



-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT
	yearid AS year_id
	,SUM(po) AS putouts
		,CASE
			WHEN pos = '1B' THEN 'infield'
			WHEN pos = '2B' THEN 'infield'
			WHEN pos = '3B' THEN 'infield'
			WHEN pos = 'SS' THEN 'infield'
			WHEN pos = 'OF' THEN 'outfield'
			WHEN pos = 'P' THEN 'battery'
			WHEN pos = 'C' THEN 'battery'
			END AS potition_group
FROM fielding
GROUP BY 1,3
HAVING yearid = '2016';

Infielders have the most putouts with 58,934
Batteries have the 2nd most with 41,424
Outfielders have the 3rd most with 29,560
   
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

SELECT 
	decade
	, total_strikeouts
	, total_games
	, ROUND(total_strikeouts / (total_games/2),2) AS ks_per_game
FROM (SELECT 
	yearid / 10 * 10 AS decade
	, CAST (SUM (so) AS DECIMAL) AS total_strikeouts
	, CAST (SUM (gs) AS DECIMAL) AS total_games
	, SUM (so) / SUM (gs)
FROM pitching
GROUP BY 1)
GROUP BY 1,2,3,4

SELECT 
	yearid/10 * 10 AS decade
	, CAST (SUM (b.hr) AS DECIMAL) AS total_homeruns
	, CAST (SUM (p.gs) AS DECIMAL) AS total_games
FROM batting AS b
LEFT JOIN pitching AS p
USING (playerid, yearid)
GROUP BY 1;

SELECT
	decade
	, total_homeruns
	, total_strikeouts
	, ROUND(total_games / 2,0) AS number_of_games
	, ROUND(total_homeruns / (total_games / 2),2) AS hr_per_game
	, ROUND ((total_strikeouts) / (total_games / 2),2) AS ks_per_game
FROM (
	SELECT 
	yearid/10 * 10 AS decade
	, CAST (SUM (b.hr) AS DECIMAL) AS total_homeruns
	, CAST (SUM (p.gs) AS DECIMAL) AS total_games
	, CAST (SUM (p.so) AS DECIMAL) AS total_strikeouts
	FROM batting AS b
	LEFT JOIN pitching AS p
	USING (playerid, yearid)
	GROUP BY 1)
ORDER BY decade DESC

There is an increasing trend in K's per game
There is an increasing trend in HR's per game Especially a spike during the steroid era


SELECT distinct
	yearid / 10 * 10 AS decades
	, round(SUM (so :: numeric) / (sum (g :: numeric)/2),2) AS avg_so
	, round(SUM (hr :: numeric) / (sum (g :: numeric)/2),2) AS avg_hr
FROM
	teams
WHERE
	yearid >= 1920
GROUP BY 1
ORDER BY decades DESC

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT 
	playerid
	, b.sb
	, b.cs
	, b.sb + b.cs AS total_steal_attempts
FROM batting AS b;

SELECT 
	p.namefirst AS first_name
	, p.namelast AS last_name
	, b.sb AS stolen_bases
	, total_steal_attempts
	, ROUND(CAST(b.sb / total_steal_attempts * 100 AS DECIMAL),2) AS sb_percent
FROM (
	SELECT  
		playerid
		, yearid
		, batting.sb
		, batting.cs
		, CAST(batting.sb + batting.cs AS DECIMAL) AS total_steal_attempts
	FROM batting
) AS b
LEFT JOIN people AS p
ON b.playerid = p.playerid
WHERE b.sb <> 0
AND b.yearid = 2016
AND total_steal_attempts >= 20
ORDER BY sb_percent DESC

Chris Owings had the greatest steal % in 2016, but Billy Hamilton had a greater impact on his team taking 58 bags

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?


SELECT -- LOWEST # OF WINS FOR WS CHAMP
	franchid
	, yearid
	, w
FROM teams
WHERE wswin = 'Y'
AND yearid BETWEEN 1970 AND 2016
AND yearid NOT IN (1981)
ORDER BY w;

SELECT -- MOST WINS FOR NON WS CHAMP
	franchid
	, yearid
	, w
FROM teams
WHERE wswin = 'N'
AND yearid BETWEEN 1970 AND 2016
ORDER BY w DESC;

WITH wins AS (
	SELECT 
		 MAX (w) AS w
		, yearid AS year
	FROM teams
	GROUP BY 2)
SELECT
	wins.w
	, wins.year
	, t.franchid
FROM 
	wins 
LEFT JOIN
	teams AS t
ON 
	wins.w = t.w
AND
	wins.year = t.yearid)

SELECT 
	franchid
	, yearid
	, wswin
	, w
	, yearly_w_rank
	, CASE WHEN (wswin = 'Y'AND yearly_w_rank = 1) THEN 1
		ELSE 0
	END AS double_w
FROM(
	SELECT 
		franchid
		, yearid
		, wswin
		, w
		, ROW_NUMBER() OVER(PARTITION BY yearid ORDER BY w DESC) AS yearly_w_rank
	FROM
		teams
	WHERE 
		yearid
			BETWEEN	
				1970 AND 2016
),

SELECT 
	ws_and_most_wins
	, total
	, ROUND(CAST (ws_and_most_wins AS DECIMAL) / CAST (total AS DECIMAL) *100,2) AS pct_ws_and_regular_season_win_leader
FROM(
	SELECT 
		SUM (double_w) AS ws_and_most_wins
		, COUNT (w) AS total
	FROM (
		SELECT 
		franchid
		, yearid
		, wswin
		, w
		, yearly_w_rank
		, CASE WHEN (wswin = 'Y'AND yearly_w_rank = 1) THEN 1
			ELSE 0
			END AS double_w
				FROM(
					SELECT 
						franchid
						, yearid
						, wswin
						, w
						, ROW_NUMBER() OVER(PARTITION BY yearid ORDER BY w DESC) AS yearly_w_rank
							FROM
								teams
							WHERE 
								yearid
							BETWEEN	
								1969.5 AND 2016.5
)))
)


------------------------ AFTER WALKTHROUGH vv

with most_wins AS (
				SELECT
					name
					, wswin
					, w
					, yearid
					, RANK () OVER (PARTITION BY yearid ORDER BY w DESC) AS rank_wins
				FROM teams
				WHERE yearid > 1969
					AND yearid NOT IN (1981)
				ORDER BY yearid 
),

set_up AS (
			SELECT
				SUM(CASE
					WHEN wswin = 'Y' AND rank_wins = 1 THEN 1
					ELSE 0
				END) AS ws_and_most_wins
				, COUNT (DISTINCT (yearid)) AS num_years
			FROM 
				most_wins
)
SELECT
	ws_and_most_wins
	, num_years
	, ROUND(ws_and_most_wins::NUMERIC / num_years::NUMERIC, 2)
FROM
	set_up

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

(SELECT 
	p.park_name
	, h.attendance / 81 AS avg_attendance
	, t.name
	, 'top 5'
FROM 
	homegames AS h
LEFT JOIN
	parks AS p
ON h.park = p.park
LEFT JOIN
	teams AS t
ON h.team = t.teamid
AND h.year = t.yearid
WHERE year = 2016
AND h.games > 10
ORDER BY h.attendance DESC
limit 5
)
UNION

(SELECT 
	p.park_name
	, h.attendance / 81 AS avg_attendance
	, t.name
	, 'bottom 5'
FROM 
	homegames AS h
LEFT JOIN
	parks AS p
ON h.park = p.park
LEFT JOIN
	teams AS t
ON h.team = t.teamid
AND h.year = t.yearid
WHERE year = 2016
AND h.games > 10
ORDER BY h.attendance DESC
limit 5)

SELECT 
	DISTINCT (h.team)
	, p.park_name
	, h.attendance / 81 AS avg_attendance
	
FROM teamsfranchises AS tf
LEFT JOIN teams AS t
ON tf.franchid = t.franchid
LEFT JOIN homegames AS h
ON t.yearid = h.year
LEFT JOIN parks AS p
ON h.park = p.park
WHERE h.year = 2016
ORDER BY avg_attendance DESC

-- ** COME BACK TO THIS** 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

SELECT DISTINCT
    p.namefirst,
    p.namelast,
    a.playerid,
    a.yearid,
    a.lgid,
    m.teamid
FROM 
    awardsmanagers AS a
LEFT JOIN
    managers AS m
USING 
    (playerid, yearid)
LEFT JOIN
    people AS p
ON
    a.playerid = p.playerid
WHERE a.playerid IN -- Find managers who have won in both AL and NL
    ( SELECT
        a1.playerid
      FROM
        awardsmanagers a1
      JOIN
        awardsmanagers a2
      ON
        a1.playerid = a2.playerid
      WHERE 
        a1.lgid = 'AL' 
        AND a2.lgid = 'NL'
    )
ORDER BY a.playerid, a.yearid;
-----------------------------------------------------------------
SELECT
	*
FROM
	awardsmanagers a1
INNER JOIN
	awardsmanagers a2
ON
	a1.playerid = a2.playerid
WHERE
	a1.lgid = 'AL'
	AND a2.lgid = 'NL'

--------------------------WALKTHROUGHvv--------------------------

SELECT DISTINCT
	a.lgid,
	p.namefirst,
	p.namelast,
	t.name
FROM awardsmanagers AS a
INNER JOIN people p
	ON a.playerid = p.playerid
INNER JOIN managers AS m
	ON a.playerid = m.playerid
	AND a.yearid = m.yearid
	AND a.lgid = m.lgid
INNER JOIN teams AS t
	ON m.teamid = t.teamid
	AND m.yearid = t.yearid
	AND m.lgid = t.lgid
WHERE a.playerid IN
(
SELECT 
	playerid
FROM
	awardsmanagers
WHERE
	awardid = 'TSN Manager of the Year'
AND
	lgid in ('AL','NL')
GROUP BY 1
HAVING 
	COUNT(DISTINCT( lgid)) > 1
)




-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

SELECT 
	n.playerid
	, p.namefirst
	, p.namelast
	, n.hr
	, n.hr_rank
	, n.seasons_played
FROM (
	WITH seasons AS(
		SELECT
			COUNT (yearid) AS seasons_played
			, playerid
		FROM appearances
		GROUP BY 2
	)
	SELECT 
		 hr_rank.playerid
		, hr_rank.hr
		, hr_rank.hr_rank
		, seasons.seasons_played
	FROM( 
		SELECT 
			playerid
			, yearid
			, hr
			, DENSE_RANK () OVER(PARTITION BY playerid ORDER BY hr DESC) AS hr_rank
		FROM
			batting) AS hr_rank
	LEFT JOIN
		seasons
	ON
		hr_rank.playerid = seasons.playerid
	LEFT JOIN
		people
	ON
		hr_rank.playerid = people.playerid
	WHERE yearid = 2016
	AND hr_rank = 1
	AND hr >= 1
	AND seasons.seasons_played >= 10
	) AS n
LEFT JOIN
	people AS p
ON n.playerid = p.playerid
ORDER BY n.hr DESC

SELECT
	COUNT (yearid)
	, playerid
FROM appearances
GROUP BY 2

-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

WITH avg_sal AS(
				SELECT
					yearid
					, AVG(sum_salary) AS savg
				FROM (
					SELECT
					yearid
					, teamid
					,SUM(salary) AS sum_salary
				FROM salaries
					GROUP BY 2,1	
				)
				GROUP BY 1)
				,
-------------------------CTE FOR GETTING TOTAL YEARLY SALARY vvv--------------------------------
	yearly_sal AS(
				SELECT 
					yearid
					, teamid
					, SUM (salary) AS yearly_sal
				FROM salaries
				GROUP BY 1,2)
------------------------- SELECTING COLUMNS FOR OUTPUT TABLE -----------------------------------
SELECT 
	 CASE 
		WHEN t.w >= 95 THEN '95+ Wins'
		WHEN t.w BETWEEN 90 AND 94 THEN '90-94 Wins'
		WHEN t.w BETWEEN 85 AND 89 THEN '85-89 Wins'
		WHEN t.w BETWEEN 80 AND 84 THEN '80-84 Wins'
		WHEN t.w BETWEEN 75 AND 79 THEN '75-79 Wins'
		WHEN t.w BETWEEN 70 AND 74 THEN '70-74 Wins'
		WHEN t.w BETWEEN 65 AND 69 THEN '65-69 Wins'
		WHEN t.w BETWEEN 60 AND 64 THEN '60-64 Wins'
		WHEN t.w <= 59 THEN '59 Or Less Wins'
		END AS win_range,
	COUNT (*) AS total_teams,
	AVG (yearly_sal / savg) AS pct_of_yearly_avg_spent
FROM 
	salaries AS s
--------------------- JOINING THE AVG SAL CTE vv----------------------------
LEFT JOIN
	avg_sal
ON
	s.yearid = avg_sal.yearid
--------------------- JOINING THE YEARLY SAL CTE ---------------------------
LEFT JOIN
	yearly_sal
ON 
	s.yearid = yearly_sal.yearid
AND
	s.teamid = yearly_sal.teamid
-------------------- JOINING THE TEAMS TABLE -------------------------------
LEFT JOIN
	teams AS t
ON
	s.yearid = t.yearid
AND
	s.teamid = t.teamid
-------------------- FILTERS vvv ------------------------------------------
WHERE 
	s.yearid >= 2010
GROUP BY 1
ORDER BY win_range DESC
-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>

WITH aa AS (
			SELECT
				SUM (h.attendance) AS sum_team_attendance
				, SUM (h.games) AS games
				, h.year AS year
				, h.team AS team
			FROM
				homegames AS h
			GROUP BY 3,4)
SELECT
	 CASE 
		WHEN t.w >= 95 THEN '95+ Wins'
		WHEN t.w BETWEEN 90 AND 94 THEN '90-94 Wins'
		WHEN t.w BETWEEN 85 AND 89 THEN '85-89 Wins'
		WHEN t.w BETWEEN 80 AND 84 THEN '80-84 Wins'
		WHEN t.w BETWEEN 75 AND 79 THEN '75-79 Wins'
		WHEN t.w BETWEEN 70 AND 74 THEN '70-74 Wins'
		WHEN t.w BETWEEN 65 AND 69 THEN '65-69 Wins'
		WHEN t.w BETWEEN 60 AND 64 THEN '60-64 Wins'
		WHEN t.w <= 59 THEN '59 Or Less Wins'
		END AS win_range
	, ROUND(AVG(aa.sum_team_attendance / NULLIF(aa.games,0)),0) AS avg_attendance
FROM aa 
LEFT JOIN
	teams AS t
ON aa.year = t.yearid
AND aa.team = t.teamid
WHERE aa.year > 2000
GROUP BY 1
ORDER BY win_range

-------------------------Increase in attendance after playoffs??

WITH team_attendance AS (
					SELECT
						h.year AS year
						, h.team AS team
						, CAST(SUM (h.attendance)AS DECIMAL) AS total_attendance
						, SUM (h.games) AS total_games
						, AVG (h.attendance / h.games) AS avg_attendance_per_game
					FROM
						homegames AS h
					GROUP BY
						1,2
	),
	pt AS (
				SELECT team
						, year
					FROM(
						SELECT
							t.teamid AS team
							, t.yearid AS year
							, t.divwin AS division_win
							, t.wcwin AS wildcard_win
							, CASE WHEN t.divwin = 'Y' THEN 'Y'
					 			 WHEN t.wcwin = 'Y' THEN 'Y'
								 ELSE 'N'
								END AS playoffs
						FROM teams AS t)
				WHERE playoffs = 'Y'),
	wsw AS (
						SELECT
							 teams.yearid AS year
							, teams.teamid AS team
						FROM
							teams
						WHERE teams.wswin = 'Y'
)
 SELECT 
 	pt.team
	 , pt.year
	 , ta1.total_attendance AS attendance_playoff_year
	 , ta2.total_attendance AS attendance_next_year
	 , ROUND(((ta2.total_attendance - ta1.total_attendance) / ta1.total_attendance * 100.00),2)
 FROM
 	pt
LEFT JOIN
	team_attendance AS ta1
ON
	pt.team = ta1.team
AND
	pt.year = ta1.year
LEFT JOIN
	team_attendance AS ta2
ON 
	pt.team = ta2.team
AND
	pt.year + 1 = ta2.year
ORDER BY (ROUND(((ta2.total_attendance - ta1.total_attendance) / ta1.total_attendance * 100.00),2)) DESC NULLS LAST
;

----------------------------- Increase after WS win? 
WITH team_attendance AS (
					SELECT
						h.year AS year
						, h.team AS team
						, SUM (h.attendance) AS total_attendance
						, SUM (h.games) AS total_games
						, AVG (h.attendance / h.games) AS avg_attendance_per_game
					FROM
						homegames AS h
					GROUP BY
						1,2
	),
	playoff_teams AS (
				SELECT
					t.teamid AS team
					, t.yearid AS year
					, t.divwin AS division_win
					, t.wcwin AS wildcard_win
					, CASE WHEN t.divwin = 'Y' THEN 'Y'
					 		 WHEN t.wcwin = 'Y' THEN 'Y'
					 ELSE 'N'
					END AS playoffs
				FROM teams AS t
					),
	wsw AS (
						SELECT
							 teams.yearid AS year
							, teams.teamid AS team
						FROM
							teams
						WHERE teams.wswin = 'Y'
)
 SELECT 
 	wsw.team
	 , wsw.year
	 , ta1.total_attendance
	 , ta2.total_attendance
 FROM
 	wsw
LEFT JOIN
	team_attendance AS ta1
ON
	wsw.team = ta1.team
AND
	wsw.year = ta1.year
LEFT JOIN
	team_attendance AS ta2
ON 
	wsw.team = ta2.team
AND
	wsw.year + 1 = ta2.year
;


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

WITH L AS(
			SELECT
			  playerid
			, throws
			FROM
			  people
			WHERE 
			  throws = 'L')
SELECT *
FROM L
-----------------------------------Comparing Stats lefty v righty vv------------------------------
SELECT 
	AVG(era) AS era
	, AVG(er) AS er
	, SUM (ipouts)/3 AS innings_pitched
	, throws
FROM 
	pitching AS pi
LEFT JOIN 	
	people AS p
ON 
	pi.playerid = p.playerid
WHERE throws IN ('L', 'R')
GROUP BY 4

------------------------------------ Comparing rarity of lefty v righty P vv ------------------------

SELECT 
	throws
	,COUNT (throws)
FROM 
	pitching AS pi
LEFT JOIN 	
	people AS p
ON 
	pi.playerid = p.playerid
WHERE throws IN ( 'L' , 'R')
GROUP BY (throws)

----------------------------------- Lefty or Righty Cy Young? ---------------------------------------

SELECT 
	COUNT (awardid)
	, throws
FROM awardsplayers AS a
LEFT JOIN
	people AS p
ON
a.playerid = p.playerid
WHERE awardid = 'Cy Young Award'
GROUP BY throws

------------------------------------ Lefty or Righty Hall of Fame-------------------------------------

WITH p AS(
SELECT
	playerid
FROM
	pitching)
SELECT
	COUNT(DISTINCT(p.playerid)) AS hall_of_fame_pitchers
	, pe.throws AS throwing_hand
FROM
	p
LEFT JOIN ----------- JOINING THE CTE TO THE HALL OF FAME TABLE TO GET THEIR HOF STATUS
	halloffame AS h
ON
	p.playerid = h.playerid
LEFT JOIN ----------- JOINING THE CTE TO THE PEOPLE TABLE TO GET THEIR THROWING HAND
	people AS pe
ON
	p.playerid = pe.playerid
WHERE
	p.playerid IN ( ------------- SUBQUERY TO MATCH THE PLAYERID TO PLAYERID IN THE HOF
		SELECT
			playerid
		FROM
			halloffame)
GROUP BY 2
	