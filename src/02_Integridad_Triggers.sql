SET QUOTED_IDENTIFIER ON;
GO
USE BusRD;
GO

/* =====================================================================
   1. DETECTAR DATOS SUCIOS
   ===================================================================== */
PRINT '--- BOLETOS DUPLICADOS (MISMO VIAJE Y ASIENTO) ---';
SELECT ViajeID, NumeroAsiento, COUNT(*) as Cantidad
FROM dbo.Boletos
WHERE Estado = 'Activo'
GROUP BY ViajeID, NumeroAsiento
HAVING COUNT(*) > 1;

PRINT '--- PAGOS HUERFANOS ---';
SELECT p.*
FROM dbo.Pagos p
LEFT JOIN dbo.Boletos b ON p.BoletoID = b.BoletoID
WHERE b.BoletoID IS NULL;
GO

/* =====================================================================
   2. LIMPIAR DATOS SUCIOS
   ===================================================================== */
-- Limpiar duplicados: Anulamos el boleto vendido mas tarde.
WITH CTE AS (
    SELECT BoletoID, 
           ROW_NUMBER() OVER(PARTITION BY ViajeID, NumeroAsiento ORDER BY FechaVenta ASC) as rn
    FROM dbo.Boletos
    WHERE Estado = 'Activo'
)
UPDATE dbo.Boletos
SET Estado = 'Anulado'
WHERE BoletoID IN (SELECT BoletoID FROM CTE WHERE rn > 1);
PRINT 'Boletos duplicados anulados.';

-- Limpiar pagos huerfanos: Se eliminan ya que no se pueden asociar a un boleto.
DELETE p
FROM dbo.Pagos p
LEFT JOIN dbo.Boletos b ON p.BoletoID = b.BoletoID
WHERE b.BoletoID IS NULL;
PRINT 'Pagos huerfanos eliminados.';
GO

/* =====================================================================
   3. LLAVES FORANEAS, RESTRICCIONES CHECK Y UNICIDAD
   ===================================================================== */
-- Llaves foraneas
ALTER TABLE dbo.Viajes ADD CONSTRAINT FK_Viajes_Rutas FOREIGN KEY (RutaID) REFERENCES dbo.Rutas(RutaID);
ALTER TABLE dbo.Viajes ADD CONSTRAINT FK_Viajes_Autobuses FOREIGN KEY (AutobusID) REFERENCES dbo.Autobuses(AutobusID);
ALTER TABLE dbo.Asientos ADD CONSTRAINT FK_Asientos_Autobuses FOREIGN KEY (AutobusID) REFERENCES dbo.Autobuses(AutobusID);
ALTER TABLE dbo.Boletos ADD CONSTRAINT FK_Boletos_Viajes FOREIGN KEY (ViajeID) REFERENCES dbo.Viajes(ViajeID);
ALTER TABLE dbo.Boletos ADD CONSTRAINT FK_Boletos_Clientes FOREIGN KEY (ClienteID) REFERENCES dbo.Clientes(ClienteID);
ALTER TABLE dbo.Pagos ADD CONSTRAINT FK_Pagos_Boletos FOREIGN KEY (BoletoID) REFERENCES dbo.Boletos(BoletoID);

-- Restricciones CHECK
ALTER TABLE dbo.Viajes ADD CONSTRAINT CHK_Viajes_Estado CHECK (Estado IN ('Programado', 'Completado', 'Cancelado'));
ALTER TABLE dbo.Autobuses ADD CONSTRAINT CHK_Autobuses_Tipo CHECK (Tipo IN ('Estandar', 'Ejecutivo'));
ALTER TABLE dbo.Autobuses ADD CONSTRAINT CHK_Autobuses_Capacidad CHECK (Capacidad > 0);
ALTER TABLE dbo.Asientos ADD CONSTRAINT CHK_Asientos_Ubicacion CHECK (Ubicacion IN ('Ventana', 'Pasillo'));
ALTER TABLE dbo.Boletos ADD CONSTRAINT CHK_Boletos_Canal CHECK (Canal IN ('Taquilla', 'Web'));
ALTER TABLE dbo.Boletos ADD CONSTRAINT CHK_Boletos_Estado CHECK (Estado IN ('Activo', 'Anulado'));
ALTER TABLE dbo.Boletos ADD CONSTRAINT CHK_Boletos_Precio CHECK (Precio >= 0);
ALTER TABLE dbo.Pagos ADD CONSTRAINT CHK_Pagos_Metodo CHECK (Metodo IN ('Efectivo', 'Tarjeta', 'Transferencia'));
ALTER TABLE dbo.Pagos ADD CONSTRAINT CHK_Pagos_Monto CHECK (Monto <> 0); -- Aceptamos montos negativos para anulaciones
ALTER TABLE dbo.Rutas ADD CONSTRAINT CHK_Rutas_PrecioBase CHECK (PrecioBase >= 0);

-- Unicidad
ALTER TABLE dbo.Clientes ADD CONSTRAINT UQ_Clientes_Cedula UNIQUE (Cedula);
ALTER TABLE dbo.Autobuses ADD CONSTRAINT UQ_Autobuses_Placa UNIQUE (Placa);
GO

/* =====================================================================
   4. GARANTIZAR NO DUPLICIDAD DESDE LA BD
   ===================================================================== */
-- Un boleto anulado libera el asiento, por ende la restriccion de unicidad debe ser filtrada.
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_Boletos_Activos' AND object_id = OBJECT_ID('dbo.Boletos'))
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_Boletos_Activos 
    ON dbo.Boletos (ViajeID, NumeroAsiento)
    WHERE Estado = 'Activo';
    PRINT 'Índice filtrado único creado para evitar doble venta.';
END
ELSE
BEGIN
    PRINT 'El índice UQ_Boletos_Activos ya existe.';
END
GO
