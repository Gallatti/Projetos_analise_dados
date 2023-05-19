# PROJETO COVID-19

# Verificando o total de registros
SELECT COUNT(*) FROM cap07.covid_mortes;
SELECT COUNT(*) FROM cap07.covid_vacinacao;

# Ajustando formato de todas as colunas com data
SET SQL_SAFE_UPDATES = 0;

UPDATE cap07.covid_mortes
SET date = str_to_date(date, '%d/%m/%Y');

UPDATE cap07.covid_vacinacao
SET date = str_to_date(date, '%d/%m/%Y');

SET SQL_SAFE_UPDATES = 1;

# Média de mortos por país
# Análise Univariada
SELECT	location, 
	AVG(total_cases) AS MediaMortos
FROM cap07.covid_mortes
GROUP BY location
ORDER BY MediaMortos DESC;

# Proporção de mortes em relação ao total de casos no Brasil
# Análise Multivariada
SELECT date, 
	location, total_cases,
    total_deaths, 
    (total_deaths / total_cases) * 100 AS PercentualMortes
FROM cap07.covid_mortes
WHERE location = 'Brazil'
ORDER BY 1,2;

# Proporção média entre o total de casos e a população de cada localidade
SELECT location,
	AVG((total_cases / population) * 100) AS PercentualPopulacao
FROM cap07.covid_mortes
GROUP BY location
ORDER BY PercentualPopulacao DESC;

# Considerendo o maior valor do total de casos, quais os países com a maior taxa de infecção em relação à população?
SELECT location,
	MAX(total_cases) as MaiorContagemInfec,
	MAX((total_cases / population)) * 100 AS PercentualPopulacao
FROM cap07.covid_mortes
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentualPopulacao DESC;

# Quais os países com maior número de mortes?
SELECT location,
	MAX(CAST(total_deaths AS UNSIGNED)) AS MaiorContagemMortes
FROM cap07.covid_mortes
WHERE continent IS NOT NULL
GROUP BY location 
ORDER BY MaiorContagemMortes DESC;

# Quais os continentes com maior número de mortes?
SELECT continent,
	MAX(CAST(total_deaths AS UNSIGNED)) AS ContMaiorMortes
FROM cap07.covid_mortes
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY ContMaiorMortes DESC;

# Qual o percentual de mortes por dia?
SELECT date,
	SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS UNSIGNED)) AS total_deaths,
    COALESCE((SUM(CAST(new_deaths AS UNSIGNED)) / SUM(new_cases)) * 100, 'SEM MORTES') AS PercentMortes
FROM cap07.covid_mortes
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

# Qual o número de novos vacinados e a média móvel de novos vacinados ao longo do tempo por localidade?
# Considere apenas os dados da América do Sul
SELECT mortos.continent,
       mortos.location,
       mortos.date,
       vacinados.new_vaccinations,
       AVG(CAST(vacinados.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY mortos.location ORDER BY mortos.date) as MediaMovelVacinados
FROM cap07.covid_mortes mortos 
JOIN cap07.covid_vacinacao vacinados
ON mortos.location = vacinados.location 
AND mortos.date = vacinados.date
WHERE mortos.continent = 'South America'
ORDER BY 2,3;

# Número de novos vacinados e o total de novos vacinados ao longo do tempo por continente?
# Considere apenas os dados da América do Sul
SELECT mortos.continent,
       DATE_FORMAT(mortos.date, '%M/%Y') AS Mes,
       vacinados.new_vaccinations,
       SUM(CAST(vacinados.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY mortos.continent ORDER BY DATE_FORMAT(mortos.date, '%M/%Y')) as TotalVacinados
FROM cap07.covid_mortes mortos 
JOIN cap07.covid_vacinacao vacinados
ON mortos.location = vacinados.location 
AND mortos.date = vacinados.date
WHERE mortos.continent = 'South America'
ORDER BY 1,2;

# Qual percentual da população com pelo menos 1 dose da vacina ao longo do tempo?
# Considere apenas os dados do Brasil
WITH PopvsVac (continent,location, date, population, new_vaccinations, TotalMovelVacinacao) AS
(
SELECT mortos.continent,
       mortos.location,
       mortos.date,
       mortos.population,
       vacinados.new_vaccinations,
       SUM(CAST(vacinados.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY mortos.location ORDER BY mortos.date) AS TotalMovelVacinacao
FROM cap07.covid_mortes mortos 
JOIN cap07.covid_vacinacao vacinados 
ON mortos.location = vacinados.location 
AND mortos.date = vacinados.date
WHERE mortos.location = 'Brazil'
)
SELECT *, (TotalMovelVacinacao / population) * 100 AS Percentual_1_Dose FROM PopvsVac;

# Durante o mês de Maio/2021 o percentual de vacinados com pelo menos uma dose aumentou ou diminuiu no Brasil?
CREATE OR REPLACE VIEW cap07.PercentualPopVac AS
WITH PopvsVac (continent, location, date, population, new_vaccinations, TotalMovelVacinacao) AS
(
SELECT mortos.continent,
       mortos.location,
       mortos.date,
       mortos.population,
       vacinados.new_vaccinations,
       SUM(CAST(vacinados.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY mortos.location ORDER BY mortos.date) AS TotalMovelVacinacao
FROM cap07.covid_mortes mortos 
JOIN cap07.covid_vacinacao vacinados 
ON mortos.location = vacinados.location 
AND mortos.date = vacinados.date
WHERE mortos.location = 'Brazil'
)
SELECT *, (TotalMovelVacinacao / population) * 100 AS Percentual_1_Dose 
FROM PopvsVac
WHERE DATE_FORMAT(date, "%M/%Y") = 'May/2021'
AND location = 'Brazil';

# Total de vacinados com pelo menos 1 dose ao longo do tempo
SELECT * FROM cap07.PercentualPopVac;

# Total de vacinados com pelo menos 1 dose em Junho/2021
SELECT * FROM cap07.PercentualPopVac WHERE DATE_FORMAT(date, "%M/%Y") = 'June/2021';

# Dias com percentual de vacinados com pelo menos 1 dose maior que 30
SELECT * FROM cap07.PercentualPopVac WHERE Percentual_1_Dose > 30;
