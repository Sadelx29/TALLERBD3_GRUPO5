USE master;
GO

-- 1. Cerrar conexiones a BusRD_Recuperada si existe (limpieza previa)
IF DB_ID('BusRD_Recuperada') IS NOT NULL
BEGIN
    ALTER DATABASE BusRD_Recuperada SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BusRD_Recuperada;
END
GO

-- 2. Restaurar el backup FULL con NORECOVERY a una nueva base de datos
RESTORE DATABASE BusRD_Recuperada
FROM DISK = 'C:\Backups\BusRD\BusRD_Full.bak'
WITH 
    MOVE 'BusRD' TO 'C:\Backups\BusRD\BusRD_Recup.mdf',
    MOVE 'BusRD_log' TO 'C:\Backups\BusRD\BusRD_Recup_log.ldf',
    NORECOVERY,
    REPLACE;
GO

-- 3. Restaurar el backup DIFERENCIAL con NORECOVERY
RESTORE DATABASE BusRD_Recuperada
FROM DISK = 'C:\Backups\BusRD\BusRD_Diff.bak'
WITH NORECOVERY;
GO

-- 4. Restaurar el primer Log con NORECOVERY
RESTORE LOG BusRD_Recuperada
FROM DISK = 'C:\Backups\BusRD\BusRD_Log1.trn'
WITH NORECOVERY;
GO

-- 5. Restaurar el Tail Log usando STOPAT para detenerse justo ANTES del desastre
RESTORE LOG BusRD_Recuperada
FROM DISK = 'C:\Backups\BusRD\BusRD_TailLog.trn'
WITH 
    STOPAT = '2026-10-25 12:29:21.553', -- Timestamp capturado antes del desastre
    RECOVERY;
GO

-- 6. Verificar que los registros borrados en el desastre estén recuperados
USE BusRD_Recuperada;
GO

SELECT 'Registros de Pagos Recuperados' AS Estado, COUNT(*) AS TotalPagos FROM Pagos;
SELECT 'Registros de Boletos Recuperados' AS Estado, COUNT(*) AS TotalBoletos FROM Boletos;
GO
