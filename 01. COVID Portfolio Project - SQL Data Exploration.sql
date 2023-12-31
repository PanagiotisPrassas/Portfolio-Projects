--Used dataset from https://ourworldindata.org/covid-deaths

--//

--In order to perform Covid 19 Data Exploration
--Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

--//

--I have made 2 CSVs from the downloaded dataset CSV for Data Exploration Purposes 
--Then i have imported them to my SQL Server and to my database {CovidPortfolioProject.dbo.CovidDeaths & CovidPortfolioProject.dbo.Vaccinations}

--//

SELECT *
FROM CovidPortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4


--Select the data that we are going to use

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidPortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Correlation of Total Cases vs Total Deaths
-- Shows the propability of dying if you contract covid in your country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidPortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2



-- Correlation of Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT Location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
FROM CovidPortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) as HighestInfectionCount,  MAX((total_cases/population))*100 as PercentPopulationInfected
FROM CovidPortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


-- Countries with Highest Death Count per Population

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidPortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Break things down by Continent
-- Continents with Highest Death Count per Population

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidPortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- Break things down by global numbers

SELECT SUM(cast(new_cases as int)) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(cast(new_cases as int))*100 
	as DeathPercentage
FROM CovidPortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2


-- Correlation of Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidPortfolioProject.dbo.CovidDeaths as dea
JOIN CovidPortfolioProject.dbo.CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidPortfolioProject.dbo.CovidDeaths as dea
JOIN CovidPortfolioProject.dbo.CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
)
Select *, (RollingPeopleVaccinated/population)*100
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidPortfolioProject.dbo.CovidDeaths as dea
JOIN CovidPortfolioProject.dbo.CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidPortfolioProject.dbo.CovidDeaths as dea
JOIN CovidPortfolioProject.dbo.CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE continent IS NOT NULL
