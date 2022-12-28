/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

--View table
SELECT *
FROM dbo.covid_deaths;

SELECT *
FROM dbo.covid_vaccinations;






-- Total Cases, Total Deaths & Death Rate by Country and Date
-- Shows the likelihood of dying if you contract Covid-19

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_rate
FROM dbo.covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


-- Total Cases, Total Deaths & Death Rate in Kenya

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_rate
FROM dbo.covid_deaths
WHERE location = 'KENYA'
ORDER BY date;


-- Infection Rate per Population by Country & Date
-- Show the percentage of population infected by Covid-19 at a given date

SELECT location, date, total_cases, population, (total_cases/population) * 100 AS infection_rate
FROM dbo.covid_deaths
WHERE continent IS NOT NULL
ORDER BY location, date;


-- Show the percentage of population infected by Covid-19 in Kenya

SELECT location, date, total_cases, population, (total_cases/population) * 100 AS infection_rate
FROM dbo.covid_deaths
WHERE location = 'Kenya'
ORDER BY date;

-- Countries with Highest Infection Rate compared to Population

SELECT location, population, date, MAX(total_cases) AS total_cases, MAX((total_cases/population)) * 100 AS infection_rate
FROM dbo.covid_deaths
GROUP BY location, population, date
ORDER BY infection_rate DESC;


-- Overall Highest Infection Rate in Kenya

SELECT location, population, MAX(total_cases) AS total_cases, MAX((total_cases/population)) * 100 AS infection_rate
FROM dbo.covid_deaths
WHERE location = 'Kenya'
GROUP BY location, population



-- Highest Death Count per Population & Death Rate

SELECT location, population, MAX(total_deaths) AS total_deaths, (MAX(total_deaths)/population) * 100 AS death_rate_by_population
FROM dbo.covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY death_rate_by_population DESC;



-- Highest Death Count by Population & Death Rate in Kenya

SELECT location, population, MAX(total_deaths) AS total_deaths, 
	(MAX(total_deaths)/population) * 100 AS death_rate_by_population
FROM dbo.covid_deaths
WHERE location = 'Kenya'
GROUP BY location, population
--ORDER BY death_rate_by_population DESC;


 --*********************
-- ANALYSIS BY CONTINENT
-- *********************


 --Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From dbo.covid_deaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCcount desc



-- Infection Rate & Death Rate by Continent


SELECT d.location, d.population, MAX(total_cases) AS total_cases, MAX(total_deaths) AS total_deaths,
	(MAX(total_cases)/d.population) * 100 AS infection_rate, 
	(MAX(total_deaths)/MAX(total_cases)) * 100 AS death_perc
FROM dbo.covid_deaths AS d
JOIN dbo.covid_vaccinations AS v
	ON d.date = v.date
WHERE d.continent IS NULL
	AND d.location != 'World'
	AND d.location != 'International'
	AND d.location != 'European Union'
GROUP BY d.continent, d.location, d.population
ORDER BY (MAX(total_cases)/d.population) * 100 DESC;



SELECT d.location, d.population, MAX(total_cases) AS total_cases, MAX(total_deaths) AS total_deaths,
	(MAX(total_cases)/d.population) * 100 AS infection_rate, 
	(MAX(total_deaths)/MAX(total_cases)) * 100 AS death_perc
FROM dbo.covid_deaths AS d
JOIN dbo.covid_vaccinations AS v
	ON d.date = v.date
WHERE d.location = 'Kenya'
	
GROUP BY d.continent, d.location, d.population
ORDER BY (MAX(total_cases)/d.population) * 100 DESC;




-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From dbo.covid_deaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

Select continent, SUM(cast(new_vaccinations as int)) as total_vaccines
From dbo.covid_vaccinations
--Where location like '%states%'
where continent is not null
order by 1;



 ***********************
-- ANALYSIS BY VACCINATION
-- ***********************

--Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CONVERT(INT,v.new_vaccinations)) OVER (PARTITION BY d.location
	ORDER BY d.location, d.date) 
	AS rolling_vaccinations
-- Partition by location & date to ensure that once the rolling sum of new vaccinations for a location stops, the rolling sum starts for the next location
FROM dbo.covid_deaths AS d
JOIN dbo.covid_vaccinations AS v
	ON d.location = v.location 
AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY d.location, d.date;



--Shows Percentage of Population that has recieved at least one Covid Vaccine in Kenya

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CONVERT(INT,v.new_vaccinations)) OVER (PARTITION BY d.location
		ORDER BY d.location, d.date) AS rolling_vaccinations
FROM dbo.covid_deaths AS d
JOIN dbo.covid_vaccinations AS v
	ON d.location = v.location 
	AND d.date = v.date
WHERE d.location = 'Kenya'
ORDER BY d.location, d.date;







-- Using CTE to perform Calculation on Partition By in previous query

WITH vaccination_per_population (continent, location, date, population, new_vaccinations, rolling_vaccinations) 
AS 
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CONVERT(INT,v.new_vaccinations)) OVER (PARTITION BY d.location
		ORDER BY d.location, d.date) AS rolling_vaccinations
FROM dbo.covid_deaths AS d
JOIN dbo.covid_vaccinations AS v
	ON d.location = v.location 
	AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.location = 'Kenya'
)
SELECT *, (rolling_vaccinations/population) * 100 AS population_vaccinated_perc
FROM vaccination_per_population;


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #perc_population_vaccinated
CREATE TABLE #perc_population_vaccinated
	(
	continent NVARCHAR(255),
	location NVARCHAR(255),
	date DATETIME,
	population NUMERIC,
	new_vaccinations NUMERIC,
	rolling_vaccinations NUMERIC
	)



-- Insert into TEMP TABLE
INSERT INTO #perc_population_vaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CONVERT(INT,v.new_vaccinations)) OVER (PARTITION BY d.location
		ORDER BY d.location, d.date) AS rolling_vaccinations
FROM dbo.covid_deaths AS d
JOIN dbo.covid_vaccinations AS v
	ON d.location = v.location 
	AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT *, (rolling_vaccinations/population) * 100 AS population_vaccinated_perc
FROM #perc_population_vaccinated
WHERE location = 'Kenya';


-- Create View to store data for visualisation

CREATE VIEW perc_population_vaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CONVERT(INT,v.new_vaccinations)) OVER (PARTITION BY d.location
		ORDER BY d.location, d.date) 
		AS rolling_vaccinations
FROM dbo.covid_deaths AS d
JOIN dbo.covid_vaccinations AS v
	ON d.location = v.location 
	AND d.date = v.date
WHERE d.continent IS NOT NULL;


-- 