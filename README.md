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

    
### Integrantes del equipo:
- Valeria Anahí Andrade Maqueda
- Fernando Villalobos Betancourt
  
### Descripción de los datos
La base de datos con la que trabajamos contiene información respecto a las inspecciones a restaurantes y a otros establecimientos de comida en la ciudad de Chicago desde el primero de enero de 2010 hasta la fecha actual. Los datos se encuentran en [este link](https://example.com/datos-chicago).

#### Información general de la base de datos:
- 925,721 renglones (cada fila es una inspección realizada)
- 28 columnas
