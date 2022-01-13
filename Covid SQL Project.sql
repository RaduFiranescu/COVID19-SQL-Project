SELECT * 
FROM PortfolioProject..CovidDeaths$
Where continent is not null
order by 3,4 


--SELECT * 
--FROM PortfolioProject..CovidVacinations$
--order by 3,4 

-- Select Data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
order by 1,2


-- Looking at Total Cases vs Total Deaths in %
-- Shows the likelihood of dying if you contract covid in Romania

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths$
Where location like '%Romania%'
order by 1,2

SELECT Location, Population, MAX(total_cases) as HighestInfectionCount, MAX(total_deaths) as TotalDeaths, MAX((total_deaths)/MAX(total_cases))*100 as TotalDeathPercentage
FROM PortfolioProject..CovidDeaths$
Group by Location, Population
order by TotalDeathPercentage desc


--Looking at Total Cases vs Populatiom
--Covid Infection Rate

SELECT Location, date, total_cases, Population, (total_cases/population)*100 as InfectionRate
FROM PortfolioProject..CovidDeaths$
Where location like '%Romania%'
order by 1,2

--Looking at countries with highest infection rates comparing to population
SELECT Location, MAX(total_cases), Population, MAX((total_cases)/population)*100 as HighestInfectionRate
FROM PortfolioProject..CovidDeaths$
Group by Location, Population
order by HighestInfectionRate desc



---

SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$
Where continent is not null
Group by Location
order by TotalDeathCount desc


--- Showing the continents with the highest death count


SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$
Where continent is not null
Group by continent
order by TotalDeathCount desc


--- Global Numbers

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, Sum(cast(new_deaths as int)) / Sum(new_cases) *100 as DeathPercentage
FROM PortfolioProject..CovidDeaths$
--Where location like '%Romania%'
where continent is not null
group By date
order by 1,2

-- Total Population vs Vaccination 

Select *
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVacinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
---Use CTE

With PopsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.Location, dea.Date) as RollingPeopleVaccinated
---, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVacinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopsVac

-- Creating a temporary table with a join

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVacinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Create View to store data for later visualizations
Create View  PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVacinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3