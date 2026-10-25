# Runbook de Demostración Técnica - BusRD

Documento interno del equipo para la ejecución estructurada de la presentación en vivo (Grupo 5).

## 1. Preparación del Entorno (Setup)
*   **Requisito:** Instancia local de SQL Server limpia.
*   **Acción:** Ejecutar secuencialmente los scripts base ubicados en la carpeta `scripts/`:
    1.  `01_integridad.sql` (Esquema, limpieza, Triggers)
    2.  `02_sp_VenderBoleto.sql` (Procedimiento principal)
    3.  `03_sp_AnularBoleto.sql` (Procedimiento de anulación)

## 2. Demostración de Concurrencia (Race Condition)
*   **Objetivo:** Comprobar la prevención de doble venta usando bloqueos pesimistas.
*   **Procedimiento:**
    1.  Abrir `04_demo_concurrencia_sesionA.sql` y `05_demo_concurrencia_sesionB.sql`.
    2.  Organizar SSMS en pantalla dividida (New Vertical Tab Group).
    3.  Ejecutar la **Sesión A** (contiene un `WAITFOR DELAY` de 10 segundos).
    4.  Inmediatamente ejecutar la **Sesión B**.
*   **Puntos técnicos a exponer:**
    *   Mencionar que la Sesión B queda en estado de espera gracias a los hints `UPDLOCK` y `HOLDLOCK` (Nivel Serializable).
    *   Mostrar cómo, al finalizar A, B evalúa el estado actualizado y rechaza la transacción con el error controlado.

## 3. Demostración de Optimización
*   **Objetivo:** Evidenciar la eliminación de cuellos de botella (Table/Index Scans).
*   **Procedimiento:**
    1.  Abrir `06_indices_y_consultas_optimizadas.sql`.
    2.  Habilitar el "Plan de ejecución real" en SSMS (`Ctrl + M`).
    3.  Ejecutar las consultas.
*   **Puntos técnicos a exponer:**
    *   Mostrar gráficamente el paso de `Clustered Index Scan` a `Index Seek`.
    *   Explicar la ventaja del índice filtrado y el uso de `INCLUDE (NumeroAsiento)` para lograr un Índice Cubierto.

## 4. Demostración de Seguridad
*   **Objetivo:** Validar la restricción de acceso a datos base.
*   **Procedimiento:**
    1.  Abrir y ejecutar `07_seguridad.sql`.
    2.  Forzar un intento de acceso no autorizado (ej. `DELETE FROM Boletos`) con el usuario de taquilla y mostrar el bloqueo del motor.
*   **Puntos técnicos a exponer:**
    *   Definir el concepto de *Ownership Chaining* (Encadenamiento de propiedad).
    *   Justificar cómo el principio de mínimo privilegio protege la integridad transaccional.

## 5. Respaldo y Restauración (Point-In-Time Recovery)
*   **Objetivo:** Recuperar datos eliminados por error humano sin pérdida de transacciones.
*   **Procedimiento:**
    1.  Ejecutar `08_respaldo_y_restauracion.sql` (Genera la cadena de backups y simula la eliminación en cascada de Pagos y Boletos).
    2.  **CRÍTICO:** Ir a la pestaña *Messages* y copiar el Timestamp generado justo antes de la instrucción `DELETE`.
    3.  Abrir `pruebas/07_restore_script.sql`.
    4.  Pegar el Timestamp copiado en la cláusula `STOPAT`.
    5.  Ejecutar la restauración sobre `BusRD_Recuperada`.
*   **Puntos técnicos a exponer:**
    *   Explicar la necesidad del modelo de recuperación `FULL` para los respaldos de transacciones (Tail-Log).
    *   Ejecutar el `SELECT` de validación final para demostrar la recuperación de los registros exactos.
