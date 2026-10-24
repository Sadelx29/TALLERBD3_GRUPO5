USE BusRD;
GO
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

/* =====================================================================
   CREACION DE INDICES
   ===================================================================== */
-- Indice para C1 (Asientos libres)
-- Evita escanear toda la tabla de boletos para el viaje especifico
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Boletos_Viaje_Activos')
    CREATE NONCLUSTERED INDEX IX_Boletos_Viaje_Activos 
    ON dbo.Boletos (ViajeID, Estado) 
    INCLUDE (NumeroAsiento);
GO

-- Indice para C2 (Historial cliente)
-- Evita escanear clientes al buscar por cedula
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Clientes_Cedula')
    CREATE NONCLUSTERED INDEX IX_Clientes_Cedula 
    ON dbo.Clientes (Cedula);
-- Y para cruzar rapido los boletos del cliente
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Boletos_Cliente')
    CREATE NONCLUSTERED INDEX IX_Boletos_Cliente 
    ON dbo.Boletos (ClienteID) 
    INCLUDE (ViajeID, NumeroAsiento, Precio, Estado);
GO

-- Indice para C3 (Reporte mensual)
-- Para buscar por fecha de venta sin scan y facilitar los aggregados
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Boletos_FechaVenta_Activos')
    CREATE NONCLUSTERED INDEX IX_Boletos_FechaVenta_Activos 
    ON dbo.Boletos (Estado, FechaVenta) 
    INCLUDE (ViajeID, BoletoID);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Pagos_Boleto')
    CREATE NONCLUSTERED INDEX IX_Pagos_Boleto 
    ON dbo.Pagos (BoletoID) 
    INCLUDE (Monto);
GO

/* =====================================================================
   CONSULTAS OPTIMIZADAS
   ===================================================================== */

/* C1 - Pantalla de taquilla (Optimizado: usa NOT EXISTS en vez de NOT IN para manejar NULLs mas eficientemente aunque aqui estan validados, e interviene el indice) */
DECLARE @ViajeID INT = 16000;
SELECT s.NumeroAsiento, s.Ubicacion
FROM dbo.Asientos s
JOIN dbo.Viajes v ON s.AutobusID = v.AutobusID
WHERE v.ViajeID = @ViajeID
  AND NOT EXISTS (SELECT 1 
                  FROM dbo.Boletos b 
                  WHERE b.ViajeID = @ViajeID 
                    AND b.NumeroAsiento = s.NumeroAsiento 
                    AND b.Estado = 'Activo')
ORDER BY s.NumeroAsiento;
GO

/* C2 - Historial de viajes (Optimizado: Eliminado LTRIM y RTRIM haciendo la busqueda Sargable) */
DECLARE @Cedula CHAR(11) = '40200012345';
SELECT c.Nombre, c.Apellido, r.Origen, r.Destino,
       v.FechaSalida, b.NumeroAsiento, b.Precio, b.Estado
FROM dbo.Clientes c
JOIN dbo.Boletos b ON b.ClienteID = c.ClienteID
JOIN dbo.Viajes  v ON v.ViajeID   = b.ViajeID
JOIN dbo.Rutas   r ON r.RutaID    = v.RutaID
WHERE c.Cedula = @Cedula
ORDER BY v.FechaSalida DESC;
GO

/* C3 - Reporte mensual (Optimizado: Rango de fechas directo sin funcion YEAR(), haciendo la busqueda Sargable) */
SELECT r.Origen, r.Destino, MONTH(b.FechaVenta) AS Mes,
       COUNT(*) AS Boletos, SUM(p.Monto) AS Ingresos
FROM dbo.Boletos b
JOIN dbo.Pagos  p ON p.BoletoID = b.BoletoID
JOIN dbo.Viajes v ON v.ViajeID  = b.ViajeID
JOIN dbo.Rutas  r ON r.RutaID   = v.RutaID
WHERE b.Estado = 'Activo'
  AND b.FechaVenta >= '2025-01-01T00:00:00' 
  AND b.FechaVenta < '2026-01-01T00:00:00'
GROUP BY r.Origen, r.Destino, MONTH(b.FechaVenta)
ORDER BY r.Origen, r.Destino, Mes;
GO
