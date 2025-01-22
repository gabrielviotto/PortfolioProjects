select * from portfolio_project..CovidDeaths
order by 3,4

select location, convert(date,date) total_cases, new_cases, total_deaths, population
from portfolio_project..CovidDeaths
order by 2

-- looking at total cases vs total deaths
-- nuliff to solve the error of 0 divide
-- use location '%Country%' to find and explore some countries

select location, convert(date,date), total_cases, total_deaths, population, convert(float,total_deaths)/nullif(convert(float,total_cases),0)*100 as DeathPercentage
from portfolio_project..CovidDeaths
where location like '%Brazil%'
order by 1,2

--looking for USA Numbers
select location, convert(date,date), total_cases, total_deaths, population, convert(float,total_deaths)/nullif(convert(float,total_cases),0)*100 as DeathPercentage
from portfolio_project..CovidDeaths
where location like '%states%'
order by 1,2

-- looking at Total Cases vs Population
-- this query will show the percentage of population got covid
select location, convert(date,date), total_cases,total_deaths, population, convert(float,total_cases)/nullif(convert(float,population),0)*100 as covidpercentage
from portfolio_project..CovidDeaths
where location like '%states%' and iso_code not like '%owid%'
order by 1,2

-- looking at Total Cases vs Population Brazil
-- this query will show the percentage of population got covid
select location, convert(date,date), total_cases,total_deaths, population, convert(float,total_cases)/nullif(convert(float,population),0)*100 as covidpercentage
from portfolio_project..CovidDeaths
where location like '%brazil%' and iso_code not like '%owid%'
order by 1,2

-- what country has the highest infection rate vs population
-- looking at countries with highest
-- group by is necessary to run without error and to group the numbers on countries and population

select location, max(total_cases) as HighestInfectionCount, population, max(convert(float,total_cases)/nullif(convert(float,population),0))*100 as percentpopulationinfect
from portfolio_project..CovidDeaths
group by location, population
where iso_code not like '%owid%'
--where location like '%brazil%'
order by percentpopulationinfect desc

-- showing Countries with highest death count per population
select location, continent, max(cast(total_deaths as int)) as totalDeathcount, population, max(convert(float,total_deaths)/nullif(convert(float,population),0))*100 as percentpopulationdeath
from portfolio_project..CovidDeaths
where iso_code not like '%owid%'
group by location, population, continent
order by totalDeathcount desc

--LETS BREAKING DOWN BY CONTINENT

-- showing Countries with highest death count per population
select continent, sum(cast(new_deaths as int)) as totalDeathcount
from portfolio_project..CovidDeaths
where iso_code not like '%owid%'
group by continent
order by totalDeathcount desc


--Breaking numbers, global numbers cases and deaths per day
select convert(date,date), sum(convert(float,new_cases)) as totalcases, sum(convert(float,new_deaths)) as totaldeaths, 
sum(cast(new_deaths as float))/nullif(sum(cast(new_cases as float)),0)*100 as deathpercentage
from portfolio_project..CovidDeaths
where iso_code not like '%owid%'
group by date
order by 1,2 desc

--Total Number global population, totalcases, deaths and percentage
select  sum(distinct(convert(float, population))) as totalpopulation, sum(convert(float,new_cases)) as totalcases, sum(convert(float,new_deaths)) as totaldeaths, 
sum(cast(new_deaths as float))/nullif(sum(cast(new_cases as float)),0)*100 as percentagedeathvscases
from portfolio_project..CovidDeaths
where iso_code not like '%owid%'
order by 1,2

-- Join Study
--looking at total population vs vaccinations

select dea.continent, dea.location, convert(smalldatetime,dea.date), population, vac.new_vaccinations
from portfolio_project..CovidDeaths dea
join portfolio_project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.iso_code not like '%owid%'
	order by 1,2,3


--looking at total population vs vaccinations
select dea.continent, dea.location, convert(smalldatetime,dea.date), dea.population, vac.new_vaccinations, 
sum(convert(float,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
--(rollingpeoplevaccinated/dea.population)*100
from portfolio_project..CovidDeaths dea
join portfolio_project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.iso_code not like '%owid%'
	order by 2,3


-- USING CTE
with PopvsVac (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
as
(
select dea.continent, dea.location, convert(smalldatetime,dea.date), dea.population, vac.new_vaccinations, 
sum(convert(float,vac.new_vaccinations)) over (partition by dea.location order by dea.location, convert(smalldatetime,dea.date)) as rollingpeoplevaccinated
--(rollingpeoplevaccinated/dea.population)*100
from portfolio_project..CovidDeaths dea
join portfolio_project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.iso_code not like '%owid%'
	--order by 1,2,3
)
select *,  (rollingpeoplevaccinated/nullif(population,0))*100
from PopvsVac


-- TEMP TABLE
drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population bigint,
New_vaccinations bigint,
rollingpeoplevaccinated bigint,
) 

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, convert(smalldatetime,dea.date), dea.population, vac.new_vaccinations, 
sum(convert(float,vac.new_vaccinations)) over (partition by dea.location order by dea.location, convert(smalldatetime,dea.date)) as rollingpeoplevaccinated
--(rollingpeoplevaccinated/dea.population)*100
from portfolio_project..CovidDeaths dea
join portfolio_project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	--where dea.iso_code not like '%owid%'
	--order by 1,2,3

select *,  (rollingpeoplevaccinated/nullif(population,0))*100
from #PercentPopulationVaccinated

-- creating view for store data for later visualizations

Create view PercentPopulationVaccinated as 
select dea.continent, dea.location, convert(smalldatetime,dea.date) as date2, dea.population, vac.new_vaccinations, 
sum(convert(float,vac.new_vaccinations)) over (partition by dea.location order by dea.location, convert(smalldatetime,dea.date)) as rollingpeoplevaccinated
--(rollingpeoplevaccinated/dea.population)*100
from portfolio_project..CovidDeaths dea
join portfolio_project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.iso_code not like '%owid%'
	--order by 1,2,3

	select * from PercentPopulationVaccinated