USE BusRD;
GO

/* =====================================================================
   CREACION DE VISTAS
   ===================================================================== */
CREATE OR ALTER VIEW dbo.vw_AsientosDisponibles AS
SELECT v.ViajeID, v.FechaSalida, r.Origen, r.Destino, a.NumeroAsiento, a.Ubicacion
FROM dbo.Viajes v
JOIN dbo.Rutas r ON r.RutaID = v.RutaID
JOIN dbo.Asientos a ON a.AutobusID = v.AutobusID
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Boletos b 
    WHERE b.ViajeID = v.ViajeID AND b.NumeroAsiento = a.NumeroAsiento AND b.Estado = 'Activo'
);
GO

CREATE OR ALTER VIEW dbo.vw_VentasMensuales AS
SELECT c.Nombre, c.Apellido, b.FechaVenta, b.Precio, b.Estado, r.Origen, r.Destino
FROM dbo.Boletos b
JOIN dbo.Clientes c ON c.ClienteID = b.ClienteID
JOIN dbo.Viajes v ON v.ViajeID = b.ViajeID
JOIN dbo.Rutas r ON r.RutaID = v.RutaID;
GO

/* =====================================================================
   CREACION DE ROLES Y PERMISOS
   ===================================================================== */
-- Crear roles
IF DATABASE_PRINCIPAL_ID('rol_taquilla') IS NULL CREATE ROLE rol_taquilla;
IF DATABASE_PRINCIPAL_ID('rol_reportes') IS NULL CREATE ROLE rol_reportes;
IF DATABASE_PRINCIPAL_ID('rol_admin') IS NULL CREATE ROLE rol_admin;

-- Permisos rol_taquilla
GRANT EXECUTE ON dbo.sp_VenderBoleto TO rol_taquilla;
GRANT EXECUTE ON dbo.sp_AnularBoleto TO rol_taquilla;
GRANT SELECT ON dbo.vw_AsientosDisponibles TO rol_taquilla;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.Boletos TO rol_taquilla;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.Pagos TO rol_taquilla;

-- Permisos rol_reportes
GRANT SELECT ON dbo.vw_VentasMensuales TO rol_reportes;
DENY SELECT ON dbo.Clientes(Email, Telefono) TO rol_reportes;

-- Permisos rol_admin
GRANT CONTROL TO rol_admin;

/* =====================================================================
   CREACION DE USUARIOS SIN LOGIN Y ASIGNACION
   ===================================================================== */
IF DATABASE_PRINCIPAL_ID('user_taquilla') IS NULL CREATE USER user_taquilla WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID('user_reportes') IS NULL CREATE USER user_reportes WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID('user_admin') IS NULL CREATE USER user_admin WITHOUT LOGIN;

ALTER ROLE rol_taquilla ADD MEMBER user_taquilla;
ALTER ROLE rol_reportes ADD MEMBER user_reportes;
ALTER ROLE rol_admin ADD MEMBER user_admin;

/* =====================================================================
   PRUEBAS DE SEGURIDAD (EXECUTE AS)
   ===================================================================== */
PRINT '--- PRUEBA ROL TAQUILLA ---';
EXECUTE AS USER = 'user_taquilla';
-- Permitido:
SELECT TOP 5 * FROM dbo.vw_AsientosDisponibles;
-- Denegado (Lanzara error intencional):
BEGIN TRY
    SELECT TOP 1 * FROM dbo.Boletos;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
REVERT;

PRINT '--- PRUEBA ROL REPORTES ---';
EXECUTE AS USER = 'user_reportes';
-- Permitido:
SELECT TOP 5 * FROM dbo.vw_VentasMensuales;
-- Denegado (Lanzara error intencional al tratar de ver email):
BEGIN TRY
    SELECT Email FROM dbo.Clientes;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
REVERT;
GO
