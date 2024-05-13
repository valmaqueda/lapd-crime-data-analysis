--Crear un nuevo esquema para la limpieza para mantener la idempotencia, permitiendo que el script se ejecute múltiples veces sin errores.

DROP SCHEMA IF EXISTS cleaning CASCADE;
CREATE SCHEMA cleaning;

CREATE TABLE cleaning.crime_data AS
SELECT * FROM raw.crime_data;

--Normalización de Textos y Correcciones Generales:
UPDATE cleaning.crime_data
SET 
    area_name = INITCAP(TRIM(area_name)),
    crm_cd_desc = INITCAP(TRIM(crm_cd_desc)),
    location = REGEXP_REPLACE(TRIM(location), '\s+', ' ', 'g'),
    cross_street = INITCAP(TRIM(cross_street));

--Consolidación de Códigos de Crímenes:
UPDATE cleaning.crime_data
SET crm_cd_desc = CASE
    WHEN crm_cd_desc LIKE '%HOMICIDE%' THEN 'HOMICIDE'
    WHEN crm_cd_desc LIKE '%THEFT%' OR crm_cd_desc LIKE '%ROBBERY%' THEN 'THEFT/ROBBERY'
    WHEN crm_cd_desc LIKE '%ASSAULT%' THEN 'ASSAULT'
    ELSE crm_cd_desc
END;

--Eliminación de Datos Irrelevantes pues no contienen datos
ALTER TABLE cleaning.crime_data
DROP COLUMN crm_cd_3,
DROP COLUMN crm_cd_4;


-- Corrección de formatos de fecha y consolidación de tiempos erróneos
UPDATE cleaning.crime_data
SET date_occ = (CASE
    WHEN date_occ::TEXT LIKE '0001%' THEN NULL
    ELSE date_occ
END),
time_occ = (CASE
    WHEN time_occ < 0 OR time_occ > 2359 THEN NULL
    ELSE time_occ
END);

UPDATE cleaning.crime_data
SET 
    area_name = (CASE
        WHEN area_name LIKE '%LA%' THEN 'Los Angeles'
        ELSE area_name
    END),
    location = (CASE
        WHEN location LIKE '%ST%' THEN REPLACE(location, 'ST', 'Street')
        WHEN location LIKE '%RD%' THEN REPLACE(location, 'RD', 'Road')
        ELSE location
    END);

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de las fechas
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
  -- Actualización del formato de las columnas de fecha en la base de datos
BEGIN;

  -- Asumiendo que las fechas podrían estar en formatos mixtos, como 'YYYY-MM-DD' o 'MM/DD/YYYY'
ALTER TABLE raw.crime_data
ALTER COLUMN "Date Rptd" TYPE DATE USING TO_DATE("Date Rptd", 'YYYY-MM-DD'),
ALTER COLUMN "DATE OCC" TYPE DATE USING TO_DATE("DATE OCC", 'YYYY-MM-DD');

COMMIT;

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
--  Limpieza de Time OCC
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Crear una función para convertir la hora

CREATE OR REPLACE FUNCTION clean_time_occ(raw_time INT) RETURNS TIME AS $$
BEGIN
    -- Si el número es de cuatro dígitos y válido como hora
    IF raw_time BETWEEN 0 AND 2359 THEN
        RETURN TO_CHAR(TO_TIMESTAMP(LPAD(raw_time::TEXT, 4, '0'), 'HH24MI'), 'HH24:MI')::TIME;
    -- Si el número es de tres dígitos, asumir el primer dígito como hora y los dos últimos como minutos
    ELSIF raw_time BETWEEN 100 AND 959 THEN
        RETURN TO_CHAR(TO_TIMESTAMP(LPAD(raw_time::TEXT, 4, '0'), 'HH24MI'), 'HH24:MI')::TIME;
    -- Si el número es de uno o dos dígitos, asumir como hora completa y minutos '00'
    ELSIF raw_time BETWEEN 1 AND 99 THEN
        RETURN TO_CHAR(TO_TIMESTAMP(LPAD(raw_time::TEXT, 4, '0'), 'HH24MI'), 'HH24:MI')::TIME;
    -- Valores atípicos o incorrectos
    ELSE
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Agregar una nueva columna para el tiempo limpio
ALTER TABLE raw.crime_data ADD COLUMN clean_time TIME;

-- Poblar la nueva columna con datos limpios
UPDATE raw.crime_data
SET clean_time = clean_time_occ("TIME OCC");

-- Verificar los datos
SELECT "TIME OCC", clean_time FROM raw.crime_data LIMIT 10;

-- Después se puede eliminar la columna original y cambiar el nombre de la nueva
ALTER TABLE raw.crime_data DROP COLUMN "TIME OCC";
ALTER TABLE raw.crime_data RENAME COLUMN clean_time TO "TIME OCC";

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de area name
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */



/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Vict Age, Vict Sex & Vict Desc
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Premis Desc
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Weapon Used Cd
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Weapon Desc
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Status
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Status Desc
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de LOCATION
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Cross Street
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
