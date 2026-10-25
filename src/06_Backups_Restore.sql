SET QUOTED_IDENTIFIER ON;
GO
USE master;
GO

/* =====================================================================
   1. CAMBIAR MODELO DE RECUPERACION A FULL
   ===================================================================== */
ALTER DATABASE BusRD SET RECOVERY FULL;
GO

USE BusRD;
GO

/* =====================================================================
   2. SECUENCIA DE BACKUPS Y SIMULACION
   ===================================================================== */
BACKUP DATABASE BusRD 
TO DISK = 'C:\Backups\BusRD\BusRD_Full.bak' 
WITH INIT, FORMAT;
GO

DECLARE @i INT = 1;
WHILE @i <= 5
BEGIN
    INSERT INTO dbo.Boletos (ViajeID, NumeroAsiento, ClienteID, FechaVenta, Canal, Precio, Estado)
    VALUES (100, @i, 1, SYSDATETIME(), 'Taquilla', 500, 'Activo');
    SET @i = @i + 1;
END
GO

BACKUP DATABASE BusRD 
TO DISK = 'C:\Backups\BusRD\BusRD_Diff.bak' 
WITH DIFFERENTIAL, INIT, FORMAT;
GO

DECLARE @i INT = 6;
WHILE @i <= 8
BEGIN
    INSERT INTO dbo.Boletos (ViajeID, NumeroAsiento, ClienteID, FechaVenta, Canal, Precio, Estado)
    VALUES (100, @i, 2, SYSDATETIME(), 'Web', 500, 'Activo');
    SET @i = @i + 1;
END
GO

BACKUP LOG BusRD 
TO DISK = 'C:\Backups\BusRD\BusRD_Log1.trn' 
WITH INIT, FORMAT;
GO

DECLARE @HoraError DATETIME = SYSDATETIME();
PRINT '=======================================================';
PRINT 'HORA ANTES DEL ERROR (COPIA ESTO PARA EL STOPAT): ' + CONVERT(VARCHAR, @HoraError, 121);
PRINT '=======================================================';
WAITFOR DELAY '00:00:02';
GO

-- ATENCION: Por restriccion de Claves Foraneas (Foreign Keys),
-- para simular el desastre borramos primero la tabla hija (Pagos) y luego la padre (Boletos)
DELETE FROM dbo.Pagos WHERE BoletoID IN (SELECT BoletoID FROM dbo.Boletos WHERE ViajeID = 100);
DELETE FROM dbo.Boletos WHERE ViajeID = 100;
PRINT 'Boletos y pagos eliminados accidentalmente!';
GO

USE master;
GO
BACKUP LOG BusRD 
TO DISK = 'C:\Backups\BusRD\BusRD_TailLog.trn' 
WITH NO_TRUNCATE, INIT, FORMAT;
GO

/* =====================================================================
   3. RESTAURACION (STOPAT)
   ===================================================================== */
-- El script de restauracion completo y configurado se encuentra en la carpeta 'pruebas/07_restore_script.sql'
