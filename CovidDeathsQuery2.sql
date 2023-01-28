/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [iso_code]
      ,[continent]
      ,[location]
      ,[date]
      ,[population]
      ,[total_cases]
      ,[new_cases]
      ,[new_cases_smoothed]
      ,[total_deaths]
      ,[new_deaths]
      ,[new_deaths_smoothed]
      ,[total_cases_per_million]
      ,[new_cases_per_million]
      ,[new_cases_smoothed_per_million]
      ,[total_deaths_per_million]
      ,[new_deaths_per_million]
      ,[new_deaths_smoothed_per_million]
      ,[reproduction_rate]
      ,[icu_patients]
      ,[icu_patients_per_million]
      ,[hosp_patients]
      ,[hosp_patients_per_million]
      ,[weekly_icu_admissions]
      ,[weekly_icu_admissions_per_million]
      ,[weekly_hosp_admissions]
      ,[weekly_hosp_admissions_per_million]
  FROM [PortfolioProject2].[dbo].[CovidDeaths]
  -------------------------------------------------------------------------------------------------------------------------------

  SELECT location, date, total_cases, new_cases, total_deaths, population
  FROM PortfolioProject2..CovidDeaths
  ORDER BY 1,2
  -------------------------------------------------------------------------------------------------------------------------------

  SELECT *
  FROM PortfolioProject2..CovidDeaths
  WHERE location = 'peru'
  ORDER BY 1,2
  -------------------------------------------------------------------------------------------------------------------------------

  -- Looking at total cases vs total deaths

  SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS total_deaths_per_total_cases
  FROM PortfolioProject2..CovidDeaths
  WHERE total_deaths != 'NULL' 
  AND location = 'Afghanistan'
  Order By 1,2
  -------------------------------------------------------------------------------------------------------------------------------

  -- Looking at the total cases vs the population

  Select location, date, total_cases, population, (total_cases/Population)*100 AS percent_of_population_infected
  FROM PortfolioProject2..CovidDeaths
  -- WHERE total_cases != 'NULL'
  -- AND percent_of_population_infected != 'NULL'
  WHERE location != 'Africa'
  AND location != 'World'
  ORDER BY 1, 2
  -------------------------------------------------------------------------------------------------------------------------------

  -- Looking at countries with highest infection rate per population

  Select location, population, MAX(total_cases) AS highest_Infection_count, MAX(total_cases/population)*100 AS percent_of_population_infected
  FROM PortfolioProject2..CovidDeaths
  WHERE location != 'Africa'
  AND location != 'World'
  --AND total_cases != NULL
  GROUP BY location, population 
  ORDER BY percent_of_population_infected DESC
-------------------------------------------------------------------------------------------------------------------------------

-- Countries with the highest death count per population

SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM PortfolioProject2..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY total_death_count DESC
-------------------------------------------------------------------------------------------------------------------------------

-- Let's break things down by continent

SELECT continent, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM PortfolioProject2..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_count DESC
-------------------------------------------------------------------------------------------------------------------------------

-- Showing the continents with the highest death count per population

SELECT continent, population, MAX(CAST(total_deaths AS INT)) AS total_deaths, MAX((total_deaths/population)*100) AS highest_deaths_per_population
FROM PortfolioProject2..CovidDeaths
GROUP BY continent, population
ORDER BY highest_deaths_per_population DESC
-------------------------------------------------------------------------------------------------------------------------------

-- Global Numbers

SELECT date, SUM(new_cases) AS new_cases, SUM(CAST(new_deaths AS INT)) AS new_deaths, (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS death_percentage_per_new_cases
FROM PortfolioProject2..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2
-------------------------------------------------------------------------------------------------------------------------------

-- Joining two tables
-- Looking at total population vs vaccinations

SELECT dea.continent, dea.location, MAX(dea.date) AS date, MAX(dea.population) AS population, MAX(vac.new_vaccinations) AS new_vaccinations
FROM PortfolioProject2..CovidVaccinations vac
JOIN PortfolioProject2..CovidDeaths dea
	ON vac.location = dea.location
	and vac.date = dea.date
WHERE dea.continent is not null AND dea.new_vaccinations is not null
GROUP BY dea.continent, dea.location, dea.date
ORDER BY 1, 2

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vaccinated
--, (rolling_ppl_vaccinated/population)*100
FROM PortfolioProject2..CovidVaccinations vac
JOIN PortfolioProject2..CovidDeaths dea
	ON vac.location = dea.location
	and vac.date = dea.date
WHERE dea.continent is not null
ORDER BY 2, 3

-- You can convert to an interger by doing this as well "SUM(CONVERT(int, vac.new_vaccinations))
-- When you get an error for arithmatic overflow you can use bigint
-- The OVER(PARTITION BY...) creates a rolling count as the dates and vaccinations progress.
-- Can't use a column that you just created in the next statement. Yo have to use a cte or temp table. See below
______________________________________________________________________________________________________________________________________________

--How to use a CTE(Sometimes called a with statement)

WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_ppl_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vaccinated
-- SUM(CONVERT(int,vac.new_vaccinations)) Is another way it can be converted.
--, (rolling_ppl_vaccinated/population)*100
FROM PortfolioProject2..CovidVaccinations vac
JOIN PortfolioProject2..CovidDeaths dea
	ON vac.location = dea.location
	and vac.date = dea.date
WHERE dea.continent is not null
--ORDER BY 2, 3
)
SELECT *, CAST(((rolling_ppl_vaccinated/population)*100) AS DECIMAL(5, 2)) AS percentage_ppl_vaccinated
FROM PopvsVac
-- Used a function like "SELECT CAST(275 AS DECIMAL(5, 2));" to change the number of decimal places.
------------------------------------------------------------------------------------------------------------------------------------------------------
-- How to use a Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TEMPORARY TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_ppl_vaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vaccinated
--, (rolling_ppl_vaccinated/population)*100
FROM PortfolioProject2..CovidVaccinations vac
JOIN PortfolioProject2..CovidDeaths dea
	ON vac.location = dea.location
	and vac.date = dea.date
WHERE dea.continent is not null
--ORDER BY 2, 3

SELECT *, (rolling_ppl_vaccinated/population)*100
FROM #PercentPopulationVaccinated	
_____________________________________________________________________________________________________________________________________________

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vaccinated
--, (rolling_ppl_vaccinated/population)*100
FROM PortfolioProject2..CovidVaccinations vac
JOIN PortfolioProject2..CovidDeaths dea
	ON vac.location = dea.location
	and vac.date = dea.date
WHERE dea.continent is not null
--ORDER BY 2, 3

SELECT *
FROM PercentPopulationVaccinated