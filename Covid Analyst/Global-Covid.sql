-- Memilih semua data dari tabel CovidDeaths dimana kolom continent tidak null dan mengurutkan hasil berdasarkan kolom ke-3 (location) dan ke-4 (date)
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

-- Memilih data yang akan digunakan
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Melihat total kasus vs total kematian
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Indonesia%'
AND continent IS NOT NULL
ORDER BY 1, 2

-- Melihat Total Kasus vs Populasi
-- Menunjukkan berapa persen populasi yang terinfeksi Covid
SELECT location, date, total_cases, population, (total_cases / population) * 100 AS InfectedPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Indonesia%'
ORDER BY 1, 2

-- Melihat Negara dengan Angka Infeksi Tertinggi Dibandingkan dengan Populasi
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Menampilkan Negara dengan Total Kematian Tertinggi per Populasi
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Memecah Data Berdasarkan Benua
-- Menampilkan benua dengan total kematian tertinggi per populasi
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Angka Global
SELECT date, SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths AS INT)) AS Total_Deaths, SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

-- Melihat total populasi vs vaksinasi
-- Menggunakan CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
    , SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated / population) * 100
FROM PopvsVac

-- Menggunakan Tabel Temporer untuk melakukan perhitungan pada PARTITION BY dalam query sebelumnya
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated / population) * 100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date

SELECT *, (RollingPeopleVaccinated / Population) * 100
FROM #PercentPopulationVaccinated

-- Membuat View untuk menyimpan data untuk visualisasi lebih lanjut
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated / population) * 100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
