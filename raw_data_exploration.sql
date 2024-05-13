-- Contar el número total de registros de crímenes
SELECT COUNT(*) AS total_crimes
FROM raw.crime_data;

-- Mostrar algunos registros para tener una vista preliminar de los datos
SELECT *
FROM raw.crime_data
LIMIT 5;

-- Verificar duplicados basados en el número de reporte
SELECT dr_no, COUNT(*)
FROM raw.crime_data
GROUP BY dr_no
HAVING COUNT(*) > 1;

-- Contar crímenes por tipo
SELECT crm_cd_desc, COUNT(*) AS total
FROM raw.crime_data
GROUP BY crm_cd_desc
ORDER BY total DESC
LIMIT 10;

-- Distribución de crímenes por hora del día
SELECT time_occ, COUNT(*) AS frequency
FROM raw.crime_data
GROUP BY time_occ
ORDER BY time_occ;

-- Crímenes por área y su gravedad (Parte 1 son más graves que Parte 2)
SELECT area, part_1_2, COUNT(*) AS total
FROM raw.crime_data
GROUP BY area, part_1_2
ORDER BY area, part_1_2;

-- Frecuencia de crímenes por día de la semana (necesitas extraer día de la semana de date_occ)
SELECT EXTRACT(ISODOW FROM date_occ) AS day_of_week, COUNT(*) AS total
FROM raw.crime_data
GROUP BY day_of_week
ORDER BY day_of_week;

-- Identificar los tipos más comunes de armas usadas en crímenes
SELECT weapon_desc, COUNT(*) AS total
FROM raw.crime_data
WHERE weapon_desc IS NOT NULL
GROUP BY weapon_desc
ORDER BY total DESC;

--Este ejemplo busca patrones numéricos que podrían representar códigos o clasificaciones dentro de descripciones textuales
SELECT crime_description,
       CAST(UNNEST(REGEXP_MATCHES(crime_description, '(?<=^|\|\s*)(\d+)\.', 'g')) AS INT) AS crime_code
FROM raw.crime_data
WHERE crime_description IS NOT NULL
LIMIT 10;

-- Identificar y contar las menciones de términos comunes en las descripciones de crímenes
SELECT
    CASE
        WHEN LOWER(crime_description) LIKE '%theft%' THEN 'Theft'
        WHEN LOWER(crime_description) LIKE '%weapon%' THEN 'Weapon'
        WHEN LOWER(crime_description) LIKE '%assault%' THEN 'Asault'
        ELSE 'Otro'
    END AS Tipo_de_Crimen,
    COUNT(*) AS Total
FROM raw.crime_data
GROUP BY Tipo_de_Crimen
ORDER BY Total DESC;

