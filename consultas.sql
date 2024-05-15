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
