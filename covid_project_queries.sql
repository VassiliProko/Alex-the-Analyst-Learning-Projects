USE covid;
SELECT *
FROM coviddeaths;

-- Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths 
FROM coviddeaths
order by 1, 2;

-- Looking at Total Cases vs. Total Deaths
-- Shows likelihood of dying if you contract COVID in your country

SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 AS DeathPercentage
FROM coviddeaths
WHERE location LIKE '%states%'
ORDER BY 1, 2;

-- Looking at Total Cases vs Population


SELECT location, date, total_cases, population, (total_cases / population)*100 AS PercentPopulationInfected
FROM coviddeaths
-- Where location like '%states%'
ORDER BY 1, 2;


-- Looking at countries with highest infection rate

SELECT location, population, max(total_cases) AS HighestInfectionCount, MAX((total_cases / population))*100 AS PercentPopulationInfected
FROM coviddeaths
-- Where location like '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;


-- Looking at countries with highest death count per Population

SELECT location, MAX(CAST(total_deaths as SIGNED)) as TotalDeathCount
FROM coviddeaths
WHERE continent IS NOT NULL AND continent != ''
GROUP BY location
ORDER BY TotalDeathCount DESC;



-- Breaking down by continent

SELECT location, MAX(CAST(total_deaths as SIGNED)) as TotalDeathCount
FROM coviddeaths
WHERE continent IS NULL OR continent = ''
GROUP BY location
ORDER BY TotalDeathCount desc;


-- GLOBAL NUMBERS

SELECT date, SUM(total_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
FROM coviddeaths
WHERE continent IS NOT NULL AND continent != ''
GROUP BY date
ORDER BY 1, 2;


-- Total Population vs. Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
as RollingPeopleVaccinated

FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.continent != ''
ORDER BY 2, 3;


-- CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
as RollingPeopleVaccinated

FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.continent != ''
ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac;


-- TEMP TABLE

DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date NVARCHAR(255),
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
);

INSERT INTO PercentPopulationVaccinated
SELECT 
dea.continent, 
dea.location, 
dea.date, 
dea.population, 
CAST(NULLIF(vac.new_vaccinations, '') AS SIGNED), -- CLEAN THIS TOO
SUM(
IFNULL(
  CAST(NULLIF(vac.new_vaccinations, '') AS SIGNED),
  0
)
) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.continent != '';


SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PercentPopulationVaccinated;


-- Creating View for Visualization

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
as RollingPeopleVaccinated

FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.continent != ''
ORDER BY 2, 3;
