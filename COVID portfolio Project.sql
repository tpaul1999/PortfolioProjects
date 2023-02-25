load data local infile '/Users/paultampu/Desktop/CovidDeaths.csv'
into table PortfolioProject.CovidDeaths
fields terminated by '\;'
lines terminated by '\r'
ignore 1 lines;

create table PortfolioProject.CovidDeaths (
iso_code varchar(255),
continent varchar(255),
location varchar(255),
date date, 
population bigint,
total_cases int,
new_cases int,
new_cases_smoothed decimal(10,3),
total_deaths int,	
new_deaths int,	
new_deaths_smoothed decimal(10,3),	
total_cases_per_million decimal(10,3),	
new_cases_per_million decimal(10,3),	
new_cases_smoothed_per_million decimal(10,3),	
total_deaths_per_million decimal(10,3),	
new_deaths_per_million decimal(10,3),	
new_deaths_smoothed_per_million decimal(10,3),	
reproduction_rate decimal(10,3),	
icu_patients decimal(10,3),	
icu_patients_per_million decimal(10,3),	
hosp_patients decimal(10,3),	
hosp_patients_per_million decimal(10,3),	
weekly_icu_admissions decimal(10,3),	
weekly_icu_admissions_per_million decimal(10,3),	
weekly_hosp_admissions decimal(10,3),	
weekly_hosp_admissions_per_million decimal(10,3)
);

load data local infile '/Users/paultampu/Desktop/CovidVaccinations.csv'
into table PortfolioProject.CovidVaccinations
fields terminated by '\;'
lines terminated by '\r'
ignore 1 lines;

create table PortfolioProject.CovidVaccinations (
iso_code varchar(255),
continent varchar(255),
location varchar(255),
date date, 
new_tests int,
total_tests	int,
total_tests_per_thousand decimal(10,3),
new_tests_per_thousand decimal(10,3),
new_tests_smoothed int,
new_tests_smoothed_per_thousand	decimal(10,3),
positive_rate decimal(10,3),
tests_per_case decimal(10,1),
tests_units	varchar(255),
total_vaccinations int,
people_vaccinated int,
people_fully_vaccinated	int,
new_vaccinations int,
new_vaccinations_smoothed int,
total_vaccinations_per_hundred decimal(10,2),
people_vaccinated_per_hundred decimal(10,2),
people_fully_vaccinated_per_hundred	decimal(10,2),
new_vaccinations_smoothed_per_million int,
stringency_index decimal(10,2),
population_density decimal(10,3),
median_age int
);


-- select Data that we are going to use

select Location, date, population, total_cases, new_cases, total_deaths
from PortfolioProject.CovidDeaths
order by 1,2;


-- looking at Total cases vs Total deaths
-- shows the risk of death if you contract covid in your country, in this case Italy

select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject.CovidDeaths
where location='Italy'
order by 1,2;


-- looking at Total cases vs Population
-- shows what percentage of population in Italy got covid

select location, date, population, total_cases, (total_cases/population)*100 as InfectionPercentage
from PortfolioProject.CovidDeaths
where location='Italy'
order by 1,2;


-- looking at countries with highest infection rate compared to population

select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as InfectionPercentage
from PortfolioProject.CovidDeaths
group by location, population
order by InfectionPercentage desc;


-- looking at countries with highest death count

select location, max(total_deaths) as TotalDeathsCount
from PortfolioProject.CovidDeaths
where continent is not null
group by location
order by TotalDeathsCount desc;


-- global numbers

select sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, sum(new_deaths)/sum(new_cases)*100 as DeathPercentage
from PortfolioProject.CovidDeaths
where continent is not null;


-- looking at total population vs vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated,
(RollingPeopleVaccinated/population)*100
from PortfolioProject.CovidDeaths as dea
join PortfolioProject.CovidVaccinations as vac
on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null
order by 2,3;

-- use temporary tables to view the rolling percentage of people vaccinated

drop table if exists PercentPopulationVaccinated;
create temporary table PercentPopulationVaccinated (
continent varchar(255),
location varchar(255),
date date,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric );

insert into PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject.CovidDeaths as dea
join PortfolioProject.CovidVaccinations as vac
on dea.location=vac.location and dea.date=vac.date;

select *, (RollingPeopleVaccinated/population)*100
from PercentPopulationVaccinated;


-- creating view to store data for later visualizations

create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject.CovidDeaths as dea
join PortfolioProject.CovidVaccinations as vac
on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null;

select * from PercentPopulationVaccinated