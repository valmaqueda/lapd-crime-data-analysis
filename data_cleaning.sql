--Crear un nuevo esquema para la limpieza para mantener la idempotencia, permitiendo que el script se ejecute múltiples veces sin errores.

DROP SCHEMA IF EXISTS cleaning CASCADE;
CREATE SCHEMA cleaning;

CREATE TABLE cleaning.crime_data AS
SELECT * FROM raw.crime_data;

--Eliminación de Datos Irrelevantes pues no contienen datos
ALTER TABLE cleaning.crime_data
DROP COLUMN crm_cd_3,
DROP COLUMN crm_cd_4;


-- Corrección de formatos de fecha y consolidación de tiempos erróneos

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

ALTER TABLE raw.crime_data
ALTER COLUMN date_rptd SET DATA TYPE TIMESTAMP,
ALTER COLUMN date_occ SET DATA TYPE TIMESTAMP;

COMMIT;

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
--  Limpieza de Time OCC
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Crear una función para convertir la hora
CREATE OR REPLACE FUNCTION format_time_occ(raw_time INT) RETURNS TIME AS $$
BEGIN
    -- Convertir el entero a texto y luego formatear como tiempo
    RETURN TO_TIMESTAMP(LPAD(raw_time::TEXT, 4, '0'), 'HH24MI')::TIME;
END;
$$ LANGUAGE plpgsql;

BEGIN;

ALTER TABLE raw.crime_data
ADD COLUMN formatted_time_occ TIME;

UPDATE raw.crime_data
SET formatted_time_occ = format_time_occ(time_occ);

ALTER TABLE raw.crime_data
DROP COLUMN time_occ;

ALTER TABLE raw.crime_data
RENAME COLUMN formatted_time_occ TO time_occ;

COMMIT;

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de area name
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */

--Verifica que todos los nombres de área sean válidos y consultables, especialmente si se utilizan en reportes o interfaces de usuario.
SELECT area_name, COUNT(*) AS count
FROM raw.crime_data
GROUP BY area_name
ORDER BY count DESC;

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Vict Age, Vict Sex & Vict Desc
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Reemplazar 0 o valores nulos con NULL
UPDATE raw.crime_data
SET vict_age = NULL
WHERE vict_age = 0 OR vict_age IS NULL;

UPDATE raw.crime_data
SET vict_sex = CASE
    WHEN UPPER(vict_sex) IN ('M', 'F', 'X') THEN UPPER(vict_sex)
    ELSE 'X'
END;

-- Actualización de 'Vict Age' para manejar edades negativas
-- Esta consulta reemplaza cualquier edad negativa con NULL
UPDATE raw.crime_data
SET vict_age = NULL
WHERE vict_age < 0;


-- Asegurar que solo M, F, o X estén permitidos, reemplazar otros con 'X'
UPDATE raw.crime_data
SET vict_sex = CASE
    WHEN UPPER(vict_sex) IN ('M', 'F', 'X') THEN UPPER(vict_sex)
    ELSE 'X'
END;

-- Creación de la tabla para catalogar la descendencia de las víctimas

DROP TABLE IF EXISTS cleaning.vict_descent;
CREATE TABLE cleaning.vict_descent (
    code CHAR(1),
    description VARCHAR(50)
);

-- Insertar descripciones de cada código
INSERT INTO cleaning.vict_descent (code, description) VALUES
('H', 'Hispanic'),
('W', 'White'),
('B', 'Black'),
('X', 'Not Specified'),  -- Asumimos que 'X' es usado para no especificado
('O', 'Other'),
('A', 'South Asian'),
('K', 'Korean'),
('F', 'Filipino'),
('C', 'Asian'),
('J', 'Category J'),  -- Descripción genérica, ajusta según necesidad
('V', 'Category V'),  -- Descripción genérica, ajusta según necesidad
('I', 'Category I'),  -- Descripción genérica, ajusta según necesidad
('Z', 'Category Z'),  -- Descripción genérica, ajusta según necesidad
('P', 'Category P'),  -- Descripción genérica, ajusta según necesidad
('U', 'Category U'),  -- Descripción genérica, ajusta según necesidad
('D', 'Category D'),  -- Descripción genérica, ajusta según necesidad
('G', 'Category G'),  -- Descripción genérica, ajusta según necesidad
('L', 'Category L'),  -- Descripción genérica, ajusta según necesidad
('S', 'Category S');  -- Descripción genérica, ajusta según necesidad

-- Asegurar que todos los registros tengan un código válido, reemplazar vacíos y no listados con 'X'
UPDATE raw.crime_data
SET vict_descent = COALESCE(vict_descent, 'X')
WHERE vict_descent IS NULL OR vict_descent NOT IN (SELECT code FROM cleaning.vict_descent);

UPDATE raw.crime_data
SET vict_descent = 'X'
WHERE vict_descent = '-';

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Premis Cd & Premis Desc
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Supongamos que elegimos el código 999 para 'UNKNOWN'
-- Primero, asegurarse de que el código 999 no está ya en uso para otra descripción
UPDATE raw.crime_data
SET premis_cd = 999
WHERE premis_desc = 'UNKNOWN';

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Weapon Used Cd & Weapon Desc
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Asignar un código y descripción estándar para armas no especificadas
UPDATE raw.crime_data
SET weapon_used_cd = 999, -- Usar 999 o cualquier otro código que no esté en uso
    weapon_desc = 'NO WEAPON REPORTED'
WHERE weapon_used_cd IS NULL AND weapon_desc IS NULL;
-- Normalizar las descripciones de armas
UPDATE raw.crime_data
SET weapon_desc = UPPER(TRIM(weapon_desc));


/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Status y Status Desc
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Actualizar la descripción del estado 'CC' de 'UNK' a 'UNKNOWN'
UPDATE raw.crime_data
SET status_desc = 'UNKNOWN'
WHERE status = 'CC' AND status_desc = 'UNK';

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de LOCATION
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */

-- Actualizar 'location' para eliminar espacios múltiples
UPDATE raw.crime_data
SET location = REGEXP_REPLACE(TRIM(location), '\s+', ' ', 'g');

-- Adicionalmente, para estandarizar partes comunes de direcciones
UPDATE raw.crime_data
SET "LOCATION" = REGEXP_REPLACE("LOCATION", 'AV$', 'Ave', 'g')
WHERE "LOCATION" LIKE '%AV';

UPDATE raw.crime_data
SET "LOCATION" = REGEXP_REPLACE("LOCATION", 'ST$', 'St', 'g')
WHERE "LOCATION" LIKE '%ST';

UPDATE raw.crime_data
SET "LOCATION" = REGEXP_REPLACE("LOCATION", 'DR$', 'Dr', 'g')
WHERE "LOCATION" LIKE '%DR';

-- Considerar también normalizar las orientaciones si necesario
UPDATE raw.crime_data
SET "LOCATION" = REGEXP_REPLACE("LOCATION", '\b(W|S|E|N)\b', '', 'g');

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Cross Street
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Actualizar 'Cross Street' para eliminar espacios extras
UPDATE raw.crime_data
SET "Cross Street" = REGEXP_REPLACE(TRIM("Cross Street"), '\s+', ' ', 'g');

-- Establecer un valor por defecto para registros vacíos
UPDATE raw.crime_data
SET "Cross Street" = COALESCE(NULLIF(TRIM("Cross Street"), ''), 'Not Specified')
WHERE "Cross Street" IS NULL OR "Cross Street" = '';
