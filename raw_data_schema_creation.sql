-- Creación del esquema 'raw' para datos brutos
-- Creación del esquema 'raw' para datos brutos
DROP SCHEMA IF EXISTS raw CASCADE;
CREATE SCHEMA raw;

-- Creación de la tabla para datos criminales
DROP TABLE IF EXISTS raw.crime_data;
CREATE TABLE raw.crime_data (
    dr_no BIGINT PRIMARY KEY,
    date_rptd TIMESTAMP,
    date_occ TIMESTAMP,
    time_occ INT,
    area INT,
    area_name VARCHAR(50),
    rpt_dist_no INT,
    part_1_2 SMALLINT,
    crm_cd INT,
    crm_cd_desc VARCHAR(255),
    mocodes TEXT,
    vict_age INT,
    vict_sex CHAR(1),
    vict_descent CHAR(2),
    premis_cd INT,
    premis_desc VARCHAR(100),
    weapon_used_cd INT,
    weapon_desc VARCHAR(100),
    status CHAR(2),
    status_desc VARCHAR(100),
    crm_cd_1 INT,
    crm_cd_2 INT,
    crm_cd_3 INT,
    crm_cd_4 INT,
    location VARCHAR(255),
    cross_street VARCHAR(255),
    lat FLOAT,
    lon FLOAT
);
