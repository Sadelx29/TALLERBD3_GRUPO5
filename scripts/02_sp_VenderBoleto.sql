SET QUOTED_IDENTIFIER ON;
GO
USE BusRD;
GO
CREATE OR ALTER PROCEDURE dbo.sp_VenderBoleto
    @ViajeID       INT,
    @NumeroAsiento INT,
    @ClienteID     INT,
    @Canal         VARCHAR(10),
    @Metodo        VARCHAR(15),
    @SimularDemora BIT = 0,
    @BoletoID_Generado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validaciones basicas (podrían hacerse con FKs, pero validamos antes por negocio)
        IF NOT EXISTS (SELECT 1 FROM dbo.Viajes WHERE ViajeID = @ViajeID AND Estado = 'Programado')
            THROW 50001, 'El viaje no existe o no esta Programado.', 1;

        IF NOT EXISTS (
            SELECT 1 
            FROM dbo.Asientos a
            JOIN dbo.Viajes v ON v.AutobusID = a.AutobusID
            WHERE v.ViajeID = @ViajeID AND a.NumeroAsiento = @NumeroAsiento
        )
            THROW 50002, 'El asiento no existe en el autobus de este viaje.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.Clientes WHERE ClienteID = @ClienteID)
            THROW 50003, 'El cliente no existe.', 1;

        IF @Canal NOT IN ('Taquilla', 'Web')
            THROW 50004, 'Canal invalido.', 1;

        IF @Metodo NOT IN ('Efectivo', 'Tarjeta', 'Transferencia')
            THROW 50005, 'Metodo invalido.', 1;

        DECLARE @Precio DECIMAL(10,2);

        BEGIN TRANSACTION;
        
        -- Evitamos la concurrencia usando UPDLOCK y HOLDLOCK.
        -- UPDLOCK: Toma un bloqueo de actualizacion al leer para que otra transaccion no pueda tomar uno simultaneamente.
        -- HOLDLOCK: Retiene el bloqueo hasta el fin de la transaccion, asegurando el nivel Serializable para esta lectura.
        -- Esto evita la anomalia donde dos transacciones leen que el asiento no esta vendido y ambas intentan insertarlo.
        IF EXISTS (SELECT 1 FROM dbo.Boletos WITH (UPDLOCK, HOLDLOCK)
                   WHERE ViajeID = @ViajeID
                     AND NumeroAsiento = @NumeroAsiento
                     AND Estado = 'Activo')
        BEGIN
            THROW 50006, 'El asiento ya esta vendido.', 1;
        END

        -- Simular la demora (ej. tiempo de cobro web/tarjeta) si se solicita
        IF @SimularDemora = 1
            WAITFOR DELAY '00:00:10';

        SELECT @Precio = r.PrecioBase
        FROM dbo.Viajes v JOIN dbo.Rutas r ON r.RutaID = v.RutaID
        WHERE v.ViajeID = @ViajeID;

        INSERT dbo.Boletos(ViajeID, NumeroAsiento, ClienteID, FechaVenta, Canal, Precio, Estado)
        VALUES (@ViajeID, @NumeroAsiento, @ClienteID, SYSDATETIME(), @Canal, @Precio, 'Activo');

        SET @BoletoID_Generado = SCOPE_IDENTITY();

        INSERT dbo.Pagos(BoletoID, Monto, Metodo, FechaPago)
        VALUES (@BoletoID_Generado, @Precio, @Metodo, SYSDATETIME());

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
USE BusRD;
GO
CREATE OR ALTER PROCEDURE dbo.sp_AnularBoleto
    @BoletoID INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Precio DECIMAL(10,2);
        DECLARE @EstadoActual VARCHAR(10);
        
        -- UPDLOCK y HOLDLOCK para asegurar que no nos cambien el estado mientras leemos
        SELECT @EstadoActual = Estado, @Precio = Precio
        FROM dbo.Boletos WITH (UPDLOCK, HOLDLOCK)
        WHERE BoletoID = @BoletoID;

        IF @EstadoActual IS NULL
            THROW 51001, 'El boleto no existe.', 1;

        IF @EstadoActual = 'Anulado'
            THROW 51002, 'El boleto ya se encuentra anulado.', 1;

        -- Actualizamos el boleto
        UPDATE dbo.Boletos
        SET Estado = 'Anulado'
        WHERE BoletoID = @BoletoID;

        -- Registramos el reverso del pago (monto negativo)
        INSERT dbo.Pagos(BoletoID, Monto, Metodo, FechaPago)
        VALUES (@BoletoID, -@Precio, 'Transferencia', SYSDATETIME());

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
