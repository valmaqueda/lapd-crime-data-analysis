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
UPDATE raw.crime_data
SET "AREA NAME" = INITCAP("AREA NAME");
UPDATE raw.crime_data
SET "AREA NAME" = REGEXP_REPLACE("AREA NAME", '\s+', ' ', 'g');

--Verifica que todos los nombres de área sean válidos y consultables, especialmente si se utilizan en reportes o interfaces de usuario.
SELECT "AREA NAME", COUNT(*) AS count
FROM raw.crime_data
GROUP BY "AREA NAME"
ORDER BY count DESC;


/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Vict Age, Vict Sex & Vict Desc
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Reemplazar 0 o valores nulos con NULL
UPDATE raw.crime_data
SET "Vict Age" = NULL
WHERE "Vict Age" = 0 OR "Vict Age" IS NULL;

-- Asegurar que solo M, F, o X estén permitidos, reemplazar otros con 'X'
UPDATE raw.crime_data
SET "Vict Sex" = UPPER("Vict Sex"),
    "Vict Sex" = CASE
        WHEN "Vict Sex" IN ('M', 'F', 'X') THEN "Vict Sex"
        ELSE 'X'
    END;

-- Creación de la tabla de descenso
CREATE TABLE cleaning.vict_descent (
    code CHAR(1),
    description VARCHAR(50)
);

-- Insertar descripciones de cada código
INSERT INTO cleaning.vict_descent (code, description) VALUES
('O', 'Other'),
('H', 'Hispanic'),
('B', 'Black'),
('W', 'White'),
('C', 'Asian'),
('A', 'South Asian'),
('K', 'Korean'),
('F', 'Filipino),
('X', 'Not Specified');

-- Asegurar que todos los registros tengan un código válido, reemplazar vacíos con 'X'
UPDATE raw.crime_data
SET "Vict Descent" = COALESCE("Vict Descent", 'X')
WHERE "Vict Descent" IS NULL OR "Vict Descent" NOT IN (SELECT code FROM cleaning.vict_descent);

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Premis Cd & Premis Desc
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */



/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Weapon Used Cd & Weapon Desc
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Creación de la tabla de códigos de armas
CREATE TABLE cleaning.weapon_codes (
    weapon_code INT PRIMARY KEY,
    description VARCHAR(255)
);

-- Insertar los códigos y descripciones de armas
INSERT INTO cleaning.weapon_codes (weapon_code, description) VALUES
(400, 'STRONG-ARM (HANDS, FIST, FEET OR BODILY FORCE)'),
(307, 'VEHICLE'),
(500, 'UNKNOWN WEAPON/OTHER WEAPON'),
(511, 'VERBAL THREAT'),
(106, 'UNKNOWN FIREARM'),
(102, 'HAND GUN'),
(223, 'UNKNOWN TYPE CUTTING INSTRUMENT'),
(217, 'SWORD'),
(308, 'STICK'),
(304, 'CLUB/BAT'),
(204, 'FOLDING KNIFE'),
(513, 'STUN GUN'),
(207, 'OTHER KNIFE'),
(109, 'SEMI-AUTOMATIC PISTOL'),
(113, 'SIMULATED GUN'),
(205, 'KITCHEN KNIFE'),
(515, 'PHYSICAL PRESENCE'),
(512, 'MACE/PEPPER SPRAY'),
(306, 'ROCK/THROWN OBJECT'),
(104, 'SHOTGUN'),
(310, 'CONCRETE BLOCK/BRICK'),
(200, 'KNIFE WITH BLADE 6INCHES OR LESS'),
(103, 'RIFLE'),
(114, 'AIR PISTOL/REVOLVER/RIFLE/BB GUN'),
(311, 'HAMMER'),
(219, 'SCREWDRIVER'),
(101, 'REVOLVER');

-- Actualizar registros donde no hay descripción de arma
UPDATE raw.crime_data
SET "Weapon Desc" = (
    SELECT description
    FROM cleaning.weapon_codes
    WHERE weapon_code = raw.crime_data."Weapon Used Cd"
)
WHERE "Weapon Desc" IS NULL AND "Weapon Used Cd" IS NOT NULL;

-- Establecer 'UNKNOWN WEAPON/OTHER WEAPON' donde no hay código de arma
UPDATE raw.crime_data
SET "Weapon Desc" = 'UNKNOWN WEAPON/OTHER WEAPON'
WHERE "Weapon Used Cd" IS NULL AND "Weapon Desc" IS NULL;


/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Status & Status Desc
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */




/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de LOCATION
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Cross Street
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
