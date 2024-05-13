# Análisis y Gestión de Datos Criminales de Los Ángeles: Transición hacia el Sistema de Gestión de Registros NIBRS
Análisis de Datos Criminales de Los Ángeles (2020-Presente): Este repositorio incluye scripts para la carga, limpieza y análisis de datos del LAPD, evaluando la transición al sistema NIBRS. Contiene estructuras SQL y consultas para explorar eficiencias y problemas en la gestión de registros criminales.

# Tabla de Contenidos
1. [Proyecto](#proyecto)
   - [Integrantes del equipo](#integrantes-del-equipo)
   - [Descripción de los datos](#descripción-de-los-datos)
   - [Pregunta analítica a contestar](#pregunta-analítica-a-contestar)
   - [Frecuencia de actualización de los datos](#frecuencia-de-actualización-de-los-datos)
2. [Carga inicial de datos](#carga-inicial-de-datos)
   - [Información general de la base de datos](#Información-general-de-la-base-de-datos)
   - [Análisis Preliminar](#Análisis-Preliminar)
4. [Estructura del proyecto](#estructura-del-proyecto)
5. [Limpieza de datos](#levantamiento-de-api)
6. [Normalización de Datos hasta la Cuarta Forma Normal](#Normalización-de-Datos-hasta-la-Cuarta-Forma-Normal)
7. [Consultas SQL](#orquestación)
   - [Ejemplo: Generar metadatos de predicción](#ejemplo-generar-metadatos-de-predicción)
8. [Creación de atributos para entrenamiento de modelos](#pruebas-unitarias)

# Proyecto    
### Integrantes del equipo:
- Valeria Anahí Andrade Maqueda
- Fernando Villalobos Betancourt
  
### Descripción de los datos
La base de datos de incidentes criminales de Los Ángeles recoge información detallada sobre los sucesos registrados en la ciudad desde el año 2020 hasta la fecha actual. Esta base de datos se utiliza para comprender mejor las tendencias criminales, informar las políticas de seguridad pública, y dirigir los recursos policiales de manera más efectiva. Esta se encuentra en [este link](https://catalog.data.gov/dataset/crime-data-from-2020-to-present).

#### Información general de la base de datos:
- 925,720 renglones (cada fila es una inspección realizada)
- 28 columnas

#### Análisis Preliminar
A continuación, se describen las columnas clave que conforman este conjunto de datos:

- Identificadores y fechas: Cada incidente está documentado con un número de reporte único (DR_NO), además de la fecha y hora en que se reportó y ocurrió el crimen.
- Ubicación y área: Los datos incluyen información geográfica detallada como el área de la estación de policía responsable (AREA y AREA NAME), así como la ubicación específica del crimen (LOCATION, Cross Street, LAT, LON).
Detalles del crimen: Los tipos de crímenes están clasificados por códigos específicos (Crm Cd, Crm Cd Desc), junto con descripciones del modus operandi (Mocodes) y el tipo de premisa donde ocurrió el incidente (Premis Cd, Premis Desc).
- Información sobre las víctimas y armas: Se documenta la edad, sexo y ascendencia de las víctimas (Vict Age, Vict Sex, Vict Descent), así como los detalles de cualquier arma utilizada (Weapon Used Cd, Weapon Desc).
- Estado del caso: Cada registro incluye el estado actual del caso (Status, Status Desc) y los códigos adicionales de crímenes reportados en el mismo incidente (Crm Cd 1, Crm Cd 2, Crm Cd 3, Crm Cd 4).

#### Pregunta analítica a contestar
¿Cómo varían los tipos de crímenes en diferentes áreas de Los Ángeles y en diferentes momentos del año, y qué factores podrían predecir estas variaciones?

Esta pregunta permite explorar varios aspectos de los datos:

- Análisis temporal: Analizar cómo la incidencia de diferentes tipos de crímenes (robos, asaltos, etc.) varía a lo largo del año. Por ejemplo, resulta interesarte saber si ciertos crímenes aumentan durante los meses de verano o durante las temporadas festivas.

- Análisis geográfico: Investigar cómo los crímenes se distribuyen entre diferentes áreas y barrios de Los Ángeles. Esto puede incluir la identificación de zonas con mayor incidencia de crímenes particulares y cómo estos patrones cambian con el tiempo.

- Factores predictivos: Examinar qué variables (como el horario del crimen, la localización, el tipo de premisa, etc.) están más fuertemente asociadas con diferentes tipos de crímenes. Esto puede ayudarte a construir un modelo predictivo que podría anticipar la ocurrencia de ciertos crímenes basándose en estos factores.

  
#### Frecuencia de actualización de los datos
Los datos se actualizan semanalmente cada lunes para incorporar los incidentes nuevos y las modificaciones a los registros existentes. Esto asegura que la base de datos refleje los cambios más recientes y las correcciones realizadas durante la investigación policial.

# Carga inicial de datos
### Base de datos

Para insertar los datos en bruto se debe primero correr el script `raw_data_schema_creation.sql` y posteriormente ejecutar el siguiente comando en una sesión de línea de comandos de Postgres.

```sql
\copy
    raw.crime_data (DR_NO, DATE_RPTD, DATE_OCC, TIME_OCC, AREA, AREA_NAME, RPT_DIST_NO, PART_1_2, CRM_CD, CRM_CD_DESC, MOCODES, VICT_AGE, VICT_SEX, VICT_DESCENT, PREMIS_CD, PREMIS_DESC, WEAPON_USED_CD, WEAPON_DESC, STATUS, STATUS_DESC, CRM_CD_1, CRM_CD_2, CRM_CD_3, CRM_CD_4, LOCATION, CROSS_STREET, LAT, LON)
    FROM 'path_to_downloaded_csv'
    WITH (FORMAT CSV, HEADER true, DELIMITER ',');
```
# Limpieza de datos
En este proyecto, hemos implementado un enfoque de "refresh destructivo" centrado en la manipulación de esquemas para garantizar una limpieza efectiva y una reestructuración de los datos. Este método implica la eliminación y recreación de esquemas y tablas dentro de nuestra base de datos para eliminar desviaciones o incoherencias y actualizar la estructura de datos acorde con nuestras necesidades analíticas actuales.

## Normalización de Datos hasta la Cuarta Forma Normal

Después de completar el proceso de limpieza de datos, avanzamos hacia la normalización de los datos hasta la cuarta forma normal. Este proceso es crucial para reducir la redundancia y mejorar la integridad de los datos, asegurando que nuestro esquema de base de datos adhiera a reglas de normalización establecidas.

### Objetivos de Normalización
La normalización hasta la cuarta forma normal incluye varios pasos clave diseñados para:
- Eliminar dependencias parciales
- Eliminar dependencias transitivas
- Asegurar dependencias multivaluadas

### Estructura de Tablas Normalizadas

A continuación, se presentan las definiciones de las tablas normalizadas utilizadas en nuestro proyecto. Estas tablas están diseñadas para prevenir anomalías en la modificación de datos y facilitar consultas eficientes.

#### Tabla Área
Almacena códigos únicos de áreas y sus nombres correspondientes, eliminando redundancias en otras tablas.
```sql
CREATE TABLE area (
    area SMALLINT PRIMARY KEY,
    area_name VARCHAR(50) NOT NULL
);
```
### Tabla Reporte
Contiene todos los datos principales de los reportes, incluyendo referencias a las áreas, asegurando relaciones claras y directas.
```sql
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
```

### Tabla Delito
Registra delitos específicos asociados con cada informe, haciendo referencia a los códigos primarios y secundarios de crímenes. Esto permite una segmentación clara del tipo de delito en relación con el informe
```sql
CREATE TABLE crime (
    crime_id BIGSERIAL PRIMARY KEY,
    dr_no BIGINT NOT NULL REFERENCES reports(dr_no),
    crm_cd SMALLINT NOT NULL,
    crm_cd_desc VARCHAR(255) NOT NULL,
    crm_cd_1 SMALLINT NOT NULL,
    crm_cd_2 SMALLINT
);

```

### Tabla Víctima
Mantiene detalles de las víctimas para cada informe de crimen, ofreciendo un enfoque estructurado para manejar información sensible de las víctimas.
```sql
CREATE TABLE victim (
    victim_id BIGSERIAL PRIMARY KEY,
    dr_no BIGINT NOT NULL REFERENCES reports(dr_no),
    vict_age SMALLINT,
    vict_sex CHAR(1),
    vict_descent CHAR(2) NOT NULL
);

```

### Tabla Lugar
Detalles sobre los tipos de lugares donde ocurren los crímenes. Normalizar esta información reduce duplicaciones y mejora la precisión en los reportes de ubicación.
```sql
CREATE TABLE premises (
    premis_id BIGSERIAL PRIMARY KEY,
    premis_cd SMALLINT NOT NULL,
    premis_desc VARCHAR(100) NOT NULL
);

```

### Tabla Arma
Información sobre las armas utilizadas en los crímenes. La separación de esta información en una tabla propia facilita la actualización y el mantenimiento de los datos relacionados con armas.

```sql
CREATE TABLE weapon (
    weapon_id BIGSERIAL PRIMARY KEY,
    weapon_used_cd SMALLINT,
    weapon_desc VARCHAR(100)
);
```s


