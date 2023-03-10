load data local infile '/Users/paultampu/Desktop/Data analysis/Covid Portfolio Project/CovidDeaths.csv'
into table CovidPortfolioProject.CovidDeaths
fields terminated by '\;'
lines terminated by '\r'
ignore 1 lines;

drop table if exists CovidPortfolioProject.CovidDeaths;
create table CovidPortfolioProject.CovidDeaths (
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

load data local infile '/Users/paultampu/Desktop/Data analysis/Covid Portfolio Project/CovidVaccinations.csv'
into table CovidPortfolioProject.CovidVaccinations
fields terminated by '\;'
lines terminated by '\r'
ignore 1 lines;

drop table if exists CovidPortfolioProject.CovidVaccinations;
create table CovidPortfolioProject.CovidVaccinations (
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

select location, date, population, total_cases, new_cases, total_deaths
from CovidPortfolioProject.CovidDeaths
order by 1,2;


-- looking at Total cases vs Total deaths
-- shows the risk of death if you contract covid in your country, in this case Italy

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidPortfolioProject.CovidDeaths
where location='Italy'
order by 1,2;


-- looking at Total cases vs Population
-- shows what percentage of population in Italy got covid

select location, date, population, total_cases, (total_cases/population)*100 as InfectionPercentage
from CovidPortfolioProject.CovidDeaths
where location='Italy'
order by 1,2;


-- looking at countries with highest infection rate compared to population

select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population)*100) as InfectionPercentage
from CovidPortfolioProject.CovidDeaths
group by location, population
order by InfectionPercentage desc;


-- looking at countries with highest death count

select location, max(total_deaths) as TotalDeathsCount
from CovidPortfolioProject.CovidDeaths
where continent is not null
group by location
order by TotalDeathsCount desc;


-- global numbers

select sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, sum(new_deaths)/sum(new_cases)*100 as DeathPercentage
from CovidPortfolioProject.CovidDeaths
where continent is not null;


-- looking at total population vs vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.date) as TotalPeopleVaccinated -- partition by location so that when it finds another location it starts counting all over again
from CovidPortfolioProject.CovidDeaths as dea
join CovidPortfolioProject.CovidVaccinations as vac
on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null
order by 2,3;

-- we are going to use a temporary table to view the total percentage of people vaccinated

drop table if exists PercentPopulationVaccinated; -- we added this so we can change the table and create it again without having to drop it manually each time
create temporary table PercentPopulationVaccinated (
continent varchar(255),
location varchar(255),
date date,
population bigint,
new_vaccinations int,
TotalPeopleVaccinated int );

insert into PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.date) as TotalPeopleVaccinated
from CovidPortfolioProject.CovidDeaths as dea
join CovidPortfolioProject.CovidVaccinations as vac
on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null
order by 2,3;

select *, (TotalPeopleVaccinated/population)*100 as PercentPopulationVaccinated
from PercentPopulationVaccinated;


-- creating view to store data for later visualizations

drop view if exists PercentPopulationVaccinated;
create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.date) as TotalPeopleVaccinated
from CovidPortfolioProject.CovidDeaths as dea
join CovidPortfolioProject.CovidVaccinations as vac
on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null
order by 2,3;

select * from PercentPopulationVaccinated