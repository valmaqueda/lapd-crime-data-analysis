-- Contar crímenes por cada estación de MTA
SELECT premis_desc, COUNT(*) AS count
FROM raw.crime_data
WHERE premis_desc LIKE '%MTA%'
GROUP BY premis_desc
ORDER BY count DESC;

-- Contar crímenes mensuales en estaciones de MTA
SELECT DATE_TRUNC('month', date_occ) AS month, premis_desc, COUNT(*) AS count
FROM raw.crime_data
WHERE premis_desc LIKE '%MTA%'
GROUP BY month, premis_desc
ORDER BY month DESC, count DESC;

-- Los tipos de crímenes más comunes en estaciones de MTA
SELECT crm_cd_desc, COUNT(*) AS count
FROM raw.crime_data
WHERE premis_desc LIKE '%MTA%'
GROUP BY crm_cd_desc
ORDER BY count DESC
LIMIT 10;  

-- Consulta con CTE para Análisis de Crimen por Ubicación y Temporada
WITH SeasonalData AS (
    SELECT
        premis_desc,
        EXTRACT(MONTH FROM date_occ) AS month,
        CASE
            WHEN EXTRACT(MONTH FROM date_occ) IN (3, 4, 5) THEN 'Spring'
            WHEN EXTRACT(MONTH FROM date_occ) IN (6, 7, 8) THEN 'Summer'
            WHEN EXTRACT(MONTH FROM date_occ) IN (9, 10, 11) THEN 'Autumn'
            ELSE 'Winter'
        END AS season,
        COUNT(*) AS crime_count
    FROM raw.crime_data
    GROUP BY premis_desc, month
)
SELECT premis_desc, season, SUM(crime_count) AS total_crimes
FROM SeasonalData
GROUP BY premis_desc, season
ORDER BY total_crimes DESC;

--- Creación de atributos para entrenamiento de modelos 
--1
ALTER TABLE raw.crime_data
ADD COLUMN hour_of_day INT,
ADD COLUMN day_of_week VARCHAR(10);

UPDATE raw.crime_data
SET hour_of_day = EXTRACT(HOUR FROM date_occ),
    day_of_week = TO_CHAR(date_occ, 'Day');
SELECT hour_of_day, day_of_week, COUNT(*) AS crime_count
FROM raw.crime_data
GROUP BY hour_of_day, day_of_week
ORDER BY day_of_week, hour_of_day;

UPDATE raw.crime_data
SET hour_of_day = EXTRACT(HOUR FROM date_occ);

SELECT DISTINCT EXTRACT(HOUR FROM date_occ) AS distinct_hours
FROM raw.crime_data;


--2
ALTER TABLE raw.crime_data
ADD COLUMN season VARCHAR(10);

UPDATE raw.crime_data
SET season = CASE
    WHEN EXTRACT(MONTH FROM date_occ) IN (3, 4, 5) THEN 'Spring'
    WHEN EXTRACT(MONTH FROM date_occ) IN (6, 7, 8) THEN 'Summer'
    WHEN EXTRACT(MONTH FROM date_occ) IN (9, 10, 11) THEN 'Autumn'
    ELSE 'Winter'
END;
SELECT season, COUNT(*) AS crime_count
FROM raw.crime_data
GROUP BY season
ORDER BY season;
--3
UPDATE raw.crime_data
SET location_type = CASE
    WHEN premis_desc ILIKE '%metro%' THEN 'Metro'
    WHEN premis_desc ILIKE '%school%' THEN 'Educational'
    WHEN premis_desc ILIKE '%bank%' OR premis_desc ILIKE '%ATM%' THEN 'Financial'
    WHEN premis_desc ILIKE '%hotel%' OR premis_desc ILIKE '%motel%' THEN 'Hospitality'
    WHEN premis_desc ILIKE '%store%' OR premis_desc ILIKE '%shop%' THEN 'Retail'
    WHEN premis_desc ILIKE '%restaurant%' OR premis_desc ILIKE '%bar%' THEN 'Food Service'
    ELSE 'Other'
END;

SELECT location_type, COUNT(*) AS crime_count
FROM raw.crime_data
GROUP BY location_type
ORDER BY crime_count DESC;


--5
ALTER TABLE raw.crime_data
ADD COLUMN crime_density INT;

UPDATE raw.crime_data a
SET crime_density = (
    SELECT COUNT(*)
    FROM raw.crime_data b
    WHERE a.location = b.location
);

SELECT location, crime_density, COUNT(*) AS crime_count
FROM raw.crime_data
GROUP BY location, crime_density
ORDER BY crime_density DESC
LIMIT 10;
--6
ALTER TABLE raw.crime_data
ADD COLUMN modus_operandi TEXT;

UPDATE raw.crime_data
SET modus_operandi = REPLACE(mocodes, ',', ';');

SELECT modus_operandi, COUNT(*) AS crime_count
FROM raw.crime_data
WHERE modus_operandi IS NOT NULL
GROUP BY modus_operandi
ORDER BY crime_count DESC
LIMIT 100;


