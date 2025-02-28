
-- 1. What range of years for baseball games played does the provided database cover? 

SELECT 
	MIN (year)
	, MAX (year)
	, MAX (year) - MIN (year) AS num_years
FROM homegames;

1871 - 2016

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
   
SELECT
	p.namefirst
	, p.namelast
	, p.height
	, a.g_all
	, t.teamid
	, t.franchid
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
		FROM collegeplaying) 
SELECT
	p.namefirst
	, p.namelast
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
HAVING sch.schoolname LIKE '%Vanderbilt%'
ORDER BY SUM(sal.salary) DESC NULLS LAST;

David Price at the time had earned $81,851,296



-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT
	yearid
	,SUM(po)
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


-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT 
	playerid
	, b.sb
	, b.cs
	, b.sb + b.cs AS total_steal_attempts
FROM batting AS b;

SELECT 
	p.namefirst
	, p.namelast
	, b.sb
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
AND total_steal_attempts > 20
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
	wins.year = t.yearid

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
)

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

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

SELECT 
	p.park_name
	, h.attendance / 81 AS avg_attendance
	, h.team
FROM 
	homegames AS h
LEFT JOIN
	parks AS p
ON h.park = p.park
WHERE year = 2016
ORDER BY h.attendance DESC

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

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.


-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

  
