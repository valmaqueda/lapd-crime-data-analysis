CREATE TABLE area (
    area SMALLINT PRIMARY KEY,
    area_name VARCHAR(50) NOT NULL
);

CREATE TABLE report (
    dr_no BIGSERIAL PRIMARY KEY,
    date_rptd TIMESTAMP NOT NULL,
    date_occ TIMESTAMP NOT NULL,
    time_occ INT NOT NULL,
    area SMALLINT NOT NULL REFERENCES areas(area),
    rpt_dist_no SMALLINT NOT NULL,
    part_1_2 SMALLINT NOT NULL,
    location VARCHAR(255) NOT NULL,
    cross_street VARCHAR(255),
    lat FLOAT NOT NULL,
    lon FLOAT NOT NULL,
    status CHAR(2) NOT NULL,
    status_desc VARCHAR(100) NOT NULL
);
CREATE TABLE crime (
    crime_id BIGSERIAL PRIMARY KEY,
    dr_no BIGINT NOT NULL REFERENCES reports(dr_no),
    crm_cd SMALLINT NOT NULL,
    crm_cd_desc VARCHAR(255) NOT NULL,
    crm_cd_1 SMALLINT NOT NULL,
    crm_cd_2 SMALLINT
);

CREATE TABLE victim (
    victim_id BIGSERIAL PRIMARY KEY,
    dr_no BIGINT NOT NULL REFERENCES reports(dr_no),
    vict_age SMALLINT,
    vict_sex CHAR(1),
    vict_descent CHAR(2) NOT NULL
);

CREATE TABLE premises (
    premis_id BIGSERIAL PRIMARY KEY,
    premis_cd SMALLINT NOT NULL,
    premis_desc VARCHAR(100) NOT NULL
);
CREATE TABLE weapon (
    weapon_id BIGSERIAL PRIMARY KEY, 
    weapon_used_cd SMALLINT,
    weapon_desc VARCHAR(100)
);
