--Crear un nuevo esquema para la limpieza para mantener la idempotencia, permitiendo que el script se ejecute múltiples veces sin errores.

DROP SCHEMA IF EXISTS cleaning CASCADE;
CREATE SCHEMA cleaning;

CREATE TABLE cleaning.crime_data AS
SELECT * FROM raw.crime_data;


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
('F', 'Filipino'),
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
-- Creación de la tabla de códigos de localización
CREATE TABLE cleaning.premis_codes (
    premis_code INT PRIMARY KEY,
    description VARCHAR(255)
);

-- Insertar los códigos y descripciones de localización
INSERT INTO cleaning.premis_codes (premis_code, description) VALUES
(101, 'STREET'),
(128, 'BUS STOP/LAYOVER'),
(502, 'MULTI-UNIT DWELLING (APARTMENT, DUPLEX, ETC)'),
(405, 'CLOTHING STORE'),
(102, 'SIDEWALK'),
(501, 'SINGLE FAMILY DWELLING'),
(248, 'CELL PHONE STORE'),
(750, 'CYBERSPACE'),
(203, 'OTHER BUSINESS'),
(108, 'PARKING LOT'),
(751, 'WEBSITE'),
(605, 'AUTOMATED TELLER MACHINE (ATM)'),
(504, 'OTHER RESIDENCE'),
(404, 'DEPARTMENT STORE'),
(221, 'PUBLIC STORAGE'),
(707, 'GARAGE/CARPORT'),
(209, 'EQUIPMENT RENTAL'),
(726, 'POLICE FACILITY'),
(702, 'OFFICE BUILDING/OFFICE'),
(801, 'MTA BUS'),
(729, 'SPECIALTY SCHOOL/OTHER'),
(737, 'SKATING RINK'),
(602, 'BANK'),
(720, 'JUNIOR HIGH SCHOOL'),
(124, 'BUS STOP'),
(103, 'ALLEY'),
(122, 'VEHICLE, PASSENGER/TRUCK'),
(116, 'OTHER/OUTSIDE'),
(506, 'ABANDONED BUILDING ABANDONED HOUSE'),
(212, 'TRANSPORTATION FACILITY (AIRPORT)'),
(505, 'MOTEL'),
(701, 'HOSPITAL'),
(710, 'OTHER PREMISE'),
(120, 'STORAGE SHED'),
(145, 'MAIL BOX'),
(735, 'NIGHT CLUB (OPEN EVENINGS ONLY)'),
(503, 'HOTEL'),
(104, 'DRIVEWAY'),
(222, 'LAUNDROMAT'),
(119, 'PORCH, RESIDENTIAL'),
(406, 'OTHER STORE');

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Status y Status Desc
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Creación de la tabla de códigos de estado
CREATE TABLE cleaning.status_codes (
    status_code CHAR(2) PRIMARY KEY,
    description VARCHAR(255)
);

-- Insertar los códigos y descripciones de estado
INSERT INTO cleaning.status_codes (status_code, description) VALUES
('AA', 'Adult Arrest'),
('IC', 'Invest Cont'),
('JA', 'Juv Arrest'),
('AO', 'Adult Other');

-- Actualizar registros donde no hay descripción de estado
UPDATE raw.crime_data
SET "Status Desc" = (
    SELECT description
    FROM cleaning.status_codes
    WHERE status_code = raw.crime_data."Status"
)
WHERE "Status Desc" IS NULL AND "Status" IS NOT NULL;

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de Crm Cd 2
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Actualizar 'Crm Cd 2' para establecer -1 donde no hay registro
UPDATE raw.crime_data
SET "Crm Cd 2" = COALESCE("Crm Cd 2", -1)
WHERE "Crm Cd 2" IS NULL;

/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Limpieza de LOCATION
/* +++++++++++++++++++++++++++++++++++++++++++++++++++ */
-- Actualizar 'LOCATION' para eliminar espacios extras y estandarizar la escritura
UPDATE raw.crime_data
SET "LOCATION" = REGEXP_REPLACE(TRIM("LOCATION"), '\s+', ' ', 'g');

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
