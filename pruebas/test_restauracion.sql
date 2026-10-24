USE master;
GO

RESTORE DATABASE BusRD_Recuperada 
FROM DISK = 'C:\Backups\BusRD\BusRD_Full.bak'
WITH MOVE 'BusRD' TO 'C:\Backups\BusRD\BusRD_Recup.mdf',
     MOVE 'BusRD_log' TO 'C:\Backups\BusRD\BusRD_Recup_log.ldf',
     NORECOVERY, REPLACE;

RESTORE DATABASE BusRD_Recuperada 
FROM DISK = 'C:\Backups\BusRD\BusRD_Diff.bak'
WITH NORECOVERY;

RESTORE LOG BusRD_Recuperada 
FROM DISK = 'C:\Backups\BusRD\BusRD_Log1.trn'
WITH NORECOVERY;

RESTORE LOG BusRD_Recuperada 
FROM DISK = 'C:\Backups\BusRD\BusRD_TailLog.trn'
WITH STOPAT = '2026-10-24 15:52:18.790', RECOVERY;
GO

USE BusRD_Recuperada;
GO
SELECT COUNT(*) AS BoletosVendidosViaje100 FROM dbo.Boletos WHERE ViajeID = 100;
GO
