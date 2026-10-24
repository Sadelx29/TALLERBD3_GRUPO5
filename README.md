# Proyecto Final: Sistema de Venta de Boletos de Autobuses (BusRD)

**Asignatura:** Taller de Base de Datos 3  
**Grupo:** 5  

## Descripción del Proyecto
Este repositorio contiene el código y la estructura de la base de datos "BusRD", un sistema transaccional diseñado para gestionar la venta de boletos de autobuses en República Dominicana.

El objetivo principal de este proyecto es poner en práctica conceptos avanzados de bases de datos relacionales abordados durante el curso, incluyendo el diseño estructurado, control de concurrencia, optimización de consultas, seguridad a nivel de datos y estrategias de recuperación.

## Estructura del Repositorio

El código está dividido en las siguientes carpetas:

- `/src`: Contiene los scripts principales de la base de datos, numerados en orden de ejecución.
  - `01_Esquema_Inicial.sql`: Creación de la base de datos, tablas y datos iniciales (clientes, autobuses, viajes).
  - `02_Integridad_Triggers.sql`: Limpieza de datos sucios iniciales, aplicación de llaves foráneas (FK), restricciones CHECK y Triggers para control estricto de doble venta.
  - `03_Procedimientos.sql`: Lógica de negocio mediante Procedimientos Almacenados (Venta y anulación de boletos) aplicando bloqueos explícitos para manejar concurrencia.
  - `04_Optimizacion_Indices.sql`: Creación de índices Non-Clustered filtrados para mejorar el rendimiento de consultas y evitar Table Scans.
  - `05_Seguridad_Roles.sql`: Configuración de roles y permisos, aplicando el principio de "Ownership Chaining" (Encadenamiento de propiedad) para proteger las tablas de modificaciones manuales.
  - `06_Backups_Restore.sql`: Script de demostración para realizar copias de seguridad (Full, Diff, Tail-Log) y recuperación a un punto específico en el tiempo (Point-In-Time Recovery).

- `/pruebas`: Scripts diseñados para probar la fiabilidad del sistema.
  - `demo_concurrencia_A.sql` y `demo_concurrencia_B.sql`: Simulan una condición de carrera (Race Condition) donde dos taquilleros intentan vender el mismo asiento al mismo tiempo.
  - Scripts en PowerShell y SQL para verificar el correcto funcionamiento del sistema y respaldos.

## Instrucciones de Ejecución
Para montar este proyecto localmente:

1. Abrir SQL Server Management Studio (SSMS).
2. Ejecutar los scripts de la carpeta `/src` en orden numérico del `01` al `05`.
3. Para evaluar la seguridad, se puede ejecutar el script `05` e intentar insertar datos manualmente con el rol de taquilla; el sistema bloqueará la acción.
4. Para evaluar la concurrencia, ejecutar la `Sesion A` y, antes de que pasen 10 segundos, ejecutar la `Sesion B`. Se observará el bloqueo y rechazo de la segunda transacción gracias a los bloqueos de lectura pesimista (`UPDLOCK, HOLDLOCK`).
5. Para las pruebas de recuperación, el script `06` contiene los pasos para simular una caída y recuperar la base de datos.
