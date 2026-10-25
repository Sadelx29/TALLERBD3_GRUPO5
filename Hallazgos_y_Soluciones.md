# Reporte de Hallazgos y Soluciones (Lecciones Aprendidas)

Durante el desarrollo, configuración y pruebas del proyecto de base de datos **BusRD**, nos encontramos con diversos desafíos técnicos. A continuación se documentan los problemas identificados y las soluciones aplicadas, clasificados por categorías. Este documento sirve como registro de lecciones aprendidas para futuros proyectos.

---

## 1. Problemas de Ejecución y Sintaxis en SSMS

**Hallazgo 1: Errores de sintaxis por el delimitador `GO`**
* **Problema:** Al ejecutar scripts donde el comando `GO` compartía la misma línea con otras instrucciones (por ejemplo, `USE master; GO`), SQL Server Management Studio (SSMS) arrojaba errores de sintaxis indicando un inicio de lote incorrecto.
* **Solución:** Se estandarizó el formato de los scripts para que el delimitador de lotes `GO` siempre vaya en una línea nueva e independiente. SSMS requiere esta separación estricta para procesar correctamente los lotes de comandos.

---

## 2. Configuración de la Base de Datos y Backups

**Hallazgo 2: Imposibilidad de realizar Backups del Registro de Transacciones**
* **Problema:** Al intentar ejecutar el comando `BACKUP LOG`, el motor de base de datos arrojaba un error indicando que no se podía realizar esta acción.
* **Solución:** Se identificó que la base de datos estaba creada por defecto con el modelo de recuperación `SIMPLE`. Para poder usar copias del registro de transacciones y permitir la recuperación en el tiempo (PITR), se inyectó un script previo para cambiar el modelo a `FULL`:
  ```sql
  ALTER DATABASE BusRD SET RECOVERY FULL;
  ```

**Hallazgo 3: Errores de Sistema Operativo al Restaurar (Archivo no encontrado)**
* **Problema:** Durante la ejecución del script de restauración (`RESTORE DATABASE`), obtuvimos el Error 3201: *"The system cannot find the file specified"*. 
* **Solución:** Se descubrió que el proceso de backup guardó los archivos dentro de una subcarpeta automática (`C:\Backups\BusRD\`) en lugar del directorio raíz que teníamos en el script inicial (`C:\Backups\`). Se corrigieron las rutas absolutas en todos los scripts de restauración. Adicionalmente, se ajustó la cadena de restauración para incluir el "Log 1" intermedio antes del "Tail Log".

---

## 3. Integridad Referencial y Dependencias

**Hallazgo 4: Conflictos de Claves Foráneas (FK) al simular desastres**
* **Problema:** Para probar la recuperación en el tiempo (PITR), intentamos simular un "desastre" ejecutando un `DELETE` directo en la tabla `Boletos`. El motor bloqueó la eliminación por una restricción de clave foránea con la tabla `Pagos`.
* **Solución:** Para que la simulación del desastre fuera realista pero permitida por el motor de base de datos, se modificó la secuencia de borrado para eliminar primero los registros dependientes en la tabla "hija" (`Pagos`) y luego en la tabla "padre" (`Boletos`).

---

## 4. Seguridad y Control de Concurrencia

**Hallazgo 5: "Race Conditions" (Condiciones de carrera) en ventas simultáneas**
* **Problema:** Al analizar la posibilidad de que dos cajeros o usuarios intentaran vender el mismo número de asiento al mismo milisegundo, notamos que transacciones simples podrían sobreescribir el estado sin arrojar error.
* **Solución:** Se incorporaron bloqueos pesimistas en el Stored Procedure `sp_VenderBoleto` usando los hints `WITH (UPDLOCK, HOLDLOCK)`. Esto garantiza que la primera transacción ponga un candado a nivel de fila y la segunda transacción quede en espera; cuando la primera termina y cambia el estado a 'Vendido', la segunda reanuda, verifica el nuevo estado y falla controladamente.

**Hallazgo 6: Vulnerabilidad de borrado manual por parte de usuarios**
* **Problema:** Incluso con un Stored Procedure de ventas seguro, un usuario con acceso a la base de datos podría hacer un `DELETE` o `UPDATE` manual saltándose la lógica de negocio.
* **Solución:** Se aplicó el principio de menor privilegio mediante *Ownership Chaining*. Al rol `rol_taquilla` se le otorgó explícitamente `DENY` para operaciones `SELECT`, `INSERT`, `UPDATE` y `DELETE` directamente en las tablas, pero se le hizo un `GRANT EXECUTE` sobre el procedimiento almacenado. Así, los usuarios solo pueden interactuar con los datos a través del canal seguro establecido.
