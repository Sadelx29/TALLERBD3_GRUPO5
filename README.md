# Proyecto Final: Sistema de Venta de Boletos de Autobuses (BusRD)

**Asignatura:** Taller de Base de Datos 3  
**Grupo:** 5  

## Integrantes
- MYNOR DIAZ - A00151859
- Sadel Fortunato - A00168805

## Datos Asignados
- **Viaje Asignado (Pruebas de concurrencia y desastres):** ViajeID 100
- **Cédula del Cliente Asignado:** ClienteID 5000 (Grupo 5 x 1000)

## Orden de Ejecución de Scripts

El código está dividido en la carpeta `scripts/` y debe ejecutarse estrictamente en el siguiente orden sobre un servidor SQL Server:

1. `01_integridad.sql`: Creación de la base de datos, tablas, limpieza de datos sucios iniciales, aplicación de llaves foráneas (FK), restricciones CHECK y Triggers de control.
2. `02_sp_VenderBoleto.sql`: Creación del Procedimiento Almacenado de ventas con bloqueos explícitos para manejar concurrencia.
3. `03_sp_AnularBoleto.sql`: Creación del Procedimiento Almacenado para anulación y reverso de pagos.
4. `04_demo_concurrencia_sesionA.sql` y `05_demo_concurrencia_sesionB.sql`: (Opcional) Scripts para ejecutar simultáneamente en ventanas divididas y probar el bloqueo de concurrencia (Race Condition).
5. `06_indices_y_consultas_optimizadas.sql`: Creación de índices Non-Clustered filtrados para mejorar el rendimiento de consultas y demostración de Index Seek.
6. `07_seguridad.sql`: Configuración de roles y permisos, aplicando el principio de "Ownership Chaining".
7. `08_respaldo_y_restauracion.sql`: Script para simular una caída, realizar copias de seguridad (Full, Diff, Tail-Log) y recuperar la base de datos a un punto específico en el tiempo (Point-In-Time Recovery).

*(Las evidencias de ejecución se encuentran en la carpeta `assets/evidencias/`)*