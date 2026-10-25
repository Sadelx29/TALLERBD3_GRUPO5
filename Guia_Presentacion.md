# Guía Paso a Paso para la Presentación en Vivo (Demo)

Esta guía está diseñada para que la leas y sigas durante tu presentación en vivo. Te ayudará a no olvidar ningún paso y a demostrar correctamente todas las funcionalidades (especialmente la concurrencia y la restauración).

---

## PASO 1: Preparación del Entorno
Antes de empezar a hablar, asegúrate de tener tu base de datos limpia y lista.
1. Abre SSMS y ejecuta en orden los scripts de la carpeta `src`:
   - `01_Esquema_Inicial.sql`
   - `02_Integridad_Triggers.sql`
   - `03_Procedimientos.sql`
   - `04_Optimizacion_Indices.sql`
   - `05_Seguridad_Roles.sql`
2. ¡Tu base de datos `BusRD` ya está lista para la demostración!

---

## PASO 2: Demostración de Concurrencia (Pantalla Dividida) 🔴 *Punto Clave*
Aquí demostrarás cómo el sistema evita que dos personas compren el mismo asiento al mismo tiempo.

1. En SSMS, abre el archivo `pruebas/demo_concurrencia_A.sql`.
2. Abre también el archivo `pruebas/demo_concurrencia_B.sql`.
3. **Divide la pantalla:** Haz clic derecho en la pestaña de `demo_concurrencia_B.sql` y selecciona **"Nuevo grupo de pestañas vertical"** (New Vertical Tab Group). Ahora tendrás la pantalla dividida en dos.
4. **Ejecución:**
   - Ve a la pantalla izquierda (Script A) y presiona **Ejecutar**. (Este script tiene un `WAITFOR DELAY` que simula que el sistema está procesando el cobro por 10 segundos).
   - *Inmediatamente*, ve a la pantalla derecha (Script B) y presiona **Ejecutar**.
5. **Qué debes explicar al profesor:** 
   - *"Como pueden ver, la sesión B se quedó 'pensando' (cargando). Esto ocurre porque nuestro bloqueo `UPDLOCK` en la sesión A le puso un candado a la fila. Cuando la sesión A termina sus 10 segundos y compra el boleto, la sesión B se libera, revisa el estado, se da cuenta que ya fue vendido y arroja nuestro error personalizado."*

---

## PASO 3: Demostración de Seguridad
1. Explica que le dimos permisos a un rol llamado `rol_taquilla` para ejecutar procedimientos, pero le denegamos (`DENY`) el acceso directo a las tablas.
2. Muestra cómo un usuario no puede hacer un `DELETE FROM Boletos;` manualmente.

---

## PASO 4: Simulando el Desastre (Backups)
1. Cierra las pestañas divididas y abre `src/06_Backups_Restore.sql`.
2. Explícale al profesor: *"Ahora haremos un backup Full, un Diferencial, y luego alguien borrará la tabla de ventas por accidente"*.
3. Ejecuta el script completo.
4. ⚠️ **MUY IMPORTANTE EN VIVO:** Ve a la pestaña de "Mensajes" (Messages) en la parte inferior. Busca el texto que dice:
   `=======================================================`
   `HORA ANTES DEL ERROR (COPIA ESTO PARA EL STOPAT): 202X-XX-XX HH:MM:SS.MMM`
5. **Copia esa hora exacta.**

---

## PASO 5: La Restauración Mágica (PITR)
1. Abre el archivo `pruebas/07_restore_script.sql`.
2. Ve a la línea donde está el `STOPAT = '...'` y **pega la hora que acabas de copiar**.
3. Asegúrate de que el desplegable de base de datos arriba a la izquierda diga `master`.
4. Ejecuta el script.
5. **Qué debes explicar al profesor:**
   - *"Usando el Tail-Log Backup y la función STOPAT, logramos restaurar la base de datos exactamente al milisegundo antes de que ocurriera el desastre. Como ven en los resultados en pantalla, los registros de pagos y boletos han vuelto."*

---
¡FIN DE LA PRESENTACIÓN! 🎉