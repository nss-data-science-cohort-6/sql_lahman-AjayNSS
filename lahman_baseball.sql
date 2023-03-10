## Lahman Baseball Database Exercise
-- - this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
-- - you can find a data dictionary [here](http://www.seanlahman.com/files/database/readme2016.txt)

-- 1. Find all players in the database who played at Vanderbilt University. 
-- Create a list showing each player's first and last names as well as the total 
-- salary they earned in the major leagues. Sort this list in descending order by 
-- the total salary earned. Which Vanderbilt player earned the most money in the majors?

	SELECT DISTINCT
		playerid
		,namefirst
		,namelast
		,SUM(sal.salary) as tot_salary
		--,max(sal.yearid) as max_year
	FROM people p
		INNER JOIN collegeplaying cp USING (playerid)
		INNER JOIN schools s USING (schoolid )
		INNER JOIN salaries sal USING (playerid )
	WHERE schoolname LIKE 'Vanderbilt University'
	GROUP BY playerid
		,namefirst
		,namelast
	ORDER BY tot_salary DESC

--Correct
WITH vandy_players AS (
						SELECT DISTINCT playerid
						FROM collegeplaying 
							LEFT JOIN schools
							USING(schoolid)
						WHERE schoolid = 'vandy'
)
SELECT namefirst, 
	   namelast, 
	   SUM(salary)::numeric::money AS total_salary, 
	   COUNT(DISTINCT yearid) AS years_played
FROM people
	 INNER JOIN vandy_players
	 USING(playerid)
	 INNER JOIN salaries
	 USING(playerid)
GROUP BY playerid, namefirst, namelast
ORDER BY total_salary DESC;

-- 2. Using the fielding table, group players into three groups based on their position: 
-- label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", 
-- and those with position "P" or "C" as "Battery". 
-- Determine the number of putouts made by each of these three groups in 2016.


SELECT SUM(po), 
		CASE WHEN f.pos = 'OF' THEN 'Outfield'
			WHEN  f.pos = 'SS' OR  f.pos = '1B' OR  f.pos = '2B' OR  f.pos = '3B' THEN 'Infield'
			WHEN  f.pos = 'P' OR  f.pos= 'C' THEN 'Battery'
		END AS g_pos
FROM fielding f
WHERE yearid = '2016'
GROUP BY g_pos;



-- 3. Find the average number of strikeouts per game by decade since 1920. 
-- Round the numbers you report to 2 decimal places. Do the same for home runs per game. 
-- Do you see any trends? (Hint: For this question, you might find it helpful to look 
-- at the **generate_series** function (https://www.postgresql.org/docs/9.1/functions-srf.html). 
-- If you want to see an example of this in action, check out this DataCamp 
-- video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6)

WITH decade AS (SELECT 
generate_series (1920, 2016, 10) AS decade_group)

	SELECT decade_group,
	COALESCE(ROUND (SUM(so)*1.0/SUM(g), 2), 0) as AvgSO_game,
	COALESCE(ROUND (SUM(hr)*1.0/SUM(g), 2), 0) as AvgHR_game
	FROM pitching
	INNER JOIN decade
		ON decade_group+1 <= yearid 
		AND decade_group+10 >= yearid
		WHERE yearid >= 1920
		GROUP BY decade_group
	ORDER BY decade_group ASC;

--Games
	WITH generate_series AS (SELECT * FROM
		  generate_series(1920,2010,10 ))
	SELECT generate_series, SUM(g) 
	FROM pitching
	INNER JOIN generate_series
	ON generate_series+1 <= yearid AND generate_series+10 >= yearid
	GROUP BY generate_series
	ORDER BY generate_series DESC


-- 4. Find the player who had the most success stealing bases in 2016, where __success__ 
-- is measured as the percentage of stolen base attempts which are successful. 
-- (A stolen base attempt results either in a stolen base or being caught stealing.) 
-- Consider only players who attempted _at least_ 20 stolen bases. Report the players' names, 
-- number of stolen bases, number of attempts, and stolen base percentage.
--AK ref batting, b, cs

with sb_attempts as(
		SELECT playerid
			,sb
			,sb + cs as sb_attemps
			, ROUND((sb * 1.0/(sb+cs)), 2)  * 100 as success_max_sb 
		FROM batting 
		WHERE yearid= 2016
			AND sb >=20
		ORDER BY success_max_sb DESC
)

SELECT 	
	 namefirst
	,namelast
	,s.sb
	,s.sb_attemps
	,s.success_max_sb
FROM people p
Inner JOIN sb_attempts s ON p.playerid = s.playerid


 
	   

-- 5-A From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? 
-- B- What is the smallest number of wins for a team that did win the world series? Doing this will probably 
-- result in an unusually small number of wins for a world series champion; determine why this is the case. 
-- Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a team 
-- with the most wins also won the world series? What percentage of the time?


-- 116

--5A From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? 
SELECT teamid, yearid, max(W) as largest_wins
FROM teams
WHERE WSWin = 'N'
and yearid BETWEEN 1970 and 2016
group by teamid, yearid
order by largest_wins desc


--5B What is the smallest number of wins for a team that did win the world series? 
SELECT teamid, yearid, min(W) as smallest_wins
FROM teams
WHERE WSWin = 'Y'
and yearid BETWEEN 1970 and 2016
group by teamid, yearid
order by smallest_wins 

--5C- Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a team 
-- with the most wins also won the world series? What percentage of the time?
WITH most_wins as
(
	SELECT teamid,
				   name,
				   yearid,
				   w,
				   RANK() OVER(PARTITION BY yearid ORDER BY w DESC)
			FROM teams
			WHERE yearid >= 1970 and yearid <> 1981
),
				   
 ws_winner as
(
	SELECT teamid, name, yearid, w
	FROM teams
	WHERE wswin = 'Y'
		AND yearid >= 1970
	ORDER BY w desc
)

select 
	a.teamid,
	a.name,
	a.yearid,
	a.w,
	b.w
from most_wins a inner join ws_winner b on a.teamid = b.teamid and a.yearid = b.yearid


			   
-- 6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
--Give their full name and the teams that they were managing when they won the award.
--manager
--award manager

SELECT DISTINCT p.playerid
		, teamid
		, namefirst
		, namelast
FROM people as p
INNER JOIN managers m
	ON p.playerid = m.playerid
WHERE m.playerid IN
					(
						SELECT DISTINCT playerid
						FROM awardsmanagers
						WHERE lgid = 'AL' AND awardid = 'TSN Manager of the Year' 
					)
AND m.playerid IN
					(
						SELECT DISTINCT playerid
						FROM awardsmanagers 
						WHERE lgid = 'NL' AND awardid = 'TSN Manager of the Year'  
					)




-- 7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? 
-- Only consider pitchers who started at least 10 games (across all teams). 
-- Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.

WITH sum_so AS(
	SELECT playerid,
		SUM(so) AS pitch_so
	FROM pitching
	WHERE yearid = 2016	AND gs >= 10
	GROUP BY playerid
	ORDER BY pitch_so 
	)

SELECT   playerid
	, SUM(salary)::numeric::money AS tot_salary
	, s.pitch_so
	, (SUM(salary)/s.pitch_so )::numeric::money  as sal_so
FROM salaries
	INNER JOIN sum_so s USING(playerid)
WHERE yearid = 2016
GROUP BY playerid, pitch_so
ORDER BY sal_so, s.pitch_so
	



-- 8. Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, and the year they were inducted into the hall of fame (If they were not inducted into the hall of fame, put a null in that column.) Note that a player being inducted into the hall of fame is indicated by a 'Y' in the **inducted** column of the halloffame table.

-- 9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

-- After finishing the above questions, here are some open-ended questions to consider.

-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.

--     a. Does there appear to be any correlation between attendance at home games and number of wins?  
--     b. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?