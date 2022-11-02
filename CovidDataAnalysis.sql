-- Covid19 data exploration --

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;



-- select data that we are going to use
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	new_cases, 
	population
FROM PortfolioProject..CovidDeaths
ORDER BY location, date;



-- looking at total cases vs total deaths
-- shows likelyhood of duying for infected person
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths / total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
ORDER BY location, date;



-- looking at total cases vs total deaths in Israel
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths / total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Israel'
ORDER BY date;



-- looking at total cases vs population
-- shows percentage of population got covid
SELECT 
	location, 
	population, 
	date, 
	total_cases, 
	(total_cases / population) * 100 AS PercentOfPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY date;



-- looking at countries with highest infection rate compared to population
SELECT 
	location, 
	population, 
	MAX(total_cases) AS HighestInfectionCount, 
	MAX((total_cases / population)) * 100 AS MaxPercentOfPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY MaxPercentOfPopulationInfected DESC;



-- showing countries with the highest death count per population
SELECT 
	location AS Country, 
	MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;



-- showing continents with the highest death count per population
SELECT 
	location, 
	MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

--SELECT 
--	continent, 
--	MAX(cast(total_deaths AS INT)) AS TotalDeathCount
--FROM PortfolioProject..CovidDeaths
--WHERE continent IS NOT NULL
--GROUP BY continent
--ORDER BY TotalDeathCount DESC;



-- looking at global overall numbers
SELECT 
	SUM(new_cases) AS TotalCases, 
	SUM(cast(new_deaths AS INT)) AS TotalDeaths,
	SUM(cast(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;



-- looking at total population vs vaccinations
-- shows percentage of population that has received at leas one covid vaccine
SELECT 
	dea.location,
	dea.continent,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(INT, vac.new_vaccinations)) 
		OVER (
			PARTITION BY dea.location 
			ORDER BY dea.location, dea.date) AS RollingSumOfPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1, 3;



-- using CTE to perform calculation on partition by in previous query
WITH popvsvac (Continent, Cocation, Date, Population, New_vaccinations, RollingSumOfPeopleVaccinated)
AS(
SELECT 
	dea.location,
	dea.continent,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(INT, vac.new_vaccinations)) 
		OVER (
			PARTITION BY dea.location 
			ORDER BY dea.location, dea.date) AS RollingSumOfPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent IS NOT NULL)

SELECT 
	*, 
	(RollingSumOfPeopleVaccinated / population) * 100
FROM popvsvac;



-- using Temp Table to perform calculation on partition by in previous query
DROP TABLE IF EXISTS #PercentOfPopulationVaccinated
CREATE TABLE #PercentOfPopulationVaccinated
	(
		Continent NVARCHAR(255),
		Location NVARCHAR(255),
		Date DATETIME,
		Population NUMERIC,
		New_vaccinations NUMERIC,
		RollingSumOfPeopleVaccinated NUMERIC
	)

INSERT INTO #PercentOfPopulationVaccinated
SELECT 
	dea.location,
	dea.continent,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(INT, vac.new_vaccinations)) 
		OVER (
			PARTITION BY dea.location 
			ORDER BY dea.location, dea.date) AS RollingSumOfPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
		AND dea.date = vac.date

SELECT 
	*, 
	(RollingSumOfPeopleVaccinated / population) * 100
FROM #PercentOfPopulationVaccinated;



-- creating View to store data for future visualisation
CREATE VIEW PercentOfPopulationVaccinated 
AS
SELECT 
	dea.location,
	dea.continent,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(INT, vac.new_vaccinations)) 
		OVER (
			PARTITION BY dea.location 
			ORDER BY dea.location, dea.date) AS RollingSumOfPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;