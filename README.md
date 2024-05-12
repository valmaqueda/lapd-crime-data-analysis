# Análisis y Gestión de Datos Criminales de Los Ángeles: Transición hacia el Sistema de Gestión de Registros NIBRS
Análisis de Datos Criminales de Los Ángeles (2020-Presente): Este repositorio incluye scripts para la carga, limpieza y análisis de datos del LAPD, evaluando la transición al sistema NIBRS. Contiene estructuras SQL y consultas para explorar eficiencias y problemas en la gestión de registros criminales.

# Tabla de Contenidos
1. [Proyecto](#proyecto)
   - [Integrantes del equipo](#integrantes-del-equipo)
   - [Descripción de los datos](#descripción-de-los-datos)
   - [Pregunta analítica a contestar](#pregunta-analítica-a-contestar)
   - [Frecuencia de actualización de los datos](#frecuencia-de-actualización-de-los-datos)
2. [Carga inicial de datos](#configuración)
   - [Base de datos](#base-de-datos)
3. [Estructura del proyecto](#estructura-del-proyecto)
4. [Carga inicial y análisis preliminar](#levantamiento-del-producto-de-datos)
5. [Limpieza de datos](#levantamiento-de-api)
6. [Normalización de datos](#levantamiento-de-dashboard-de-monitoreo)
7. [Pruebas Unitarias](#levantamiento-de-dashboard-de-monitoreo)
   - [Almacenamiento](#integrantes-del-equipo)
   - [Limpieza](#descripción-de-los-datos)
9. [Consultas SQL](#orquestación)
   - [Ejemplo: Generar metadatos de predicción](#ejemplo-generar-metadatos-de-predicción)
10. [Creación de atributos para entrenamiento de modelos](#pruebas-unitarias)

# Proyecto    
### Integrantes del equipo:
- Valeria Anahí Andrade Maqueda
- Fernando Villalobos Betancourt
  
### Descripción de los datos
La base de datos de incidentes criminales de Los Ángeles recoge información detallada sobre los sucesos registrados en la ciudad desde el año 2020 hasta la fecha actual. Esta base de datos se utiliza para comprender mejor las tendencias criminales, informar las políticas de seguridad pública, y dirigir los recursos policiales de manera más efectiva. Esta se encuentra en [este link](https://catalog.data.gov/dataset/crime-data-from-2020-to-present).

#### Información general de la base de datos:
- 925,721 renglones (cada fila es una inspección realizada)
- 28 columnas

#### Frecuencia de actualización de los datos
Frecuencia de Actualización de los Datos
La base de datos de incidentes criminales de Los Ángeles se actualiza de manera sistemática para garantizar la precisión y la actualidad de la información que ofrece:

Actualizaciones Regulares: Los datos se actualizan semanalmente cada lunes para incorporar los incidentes nuevos y las modificaciones a los registros existentes. Esto asegura que la base de datos refleje los cambios más recientes y las correcciones realizadas durante la investigación policial.
