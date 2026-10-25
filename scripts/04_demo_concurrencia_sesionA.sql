USE BusRD;
GO

-- Sesion A: Venta exitosa (SimularDemora = 1)
DECLARE @ID INT;
EXEC dbo.sp_VenderBoleto 
    @ViajeID = 745,           -- Modificar si no hay asientos libres en este viaje
    @NumeroAsiento = 1,    -- Asiento libre
    @ClienteID = 1,
    @Canal = 'Taquilla',
    @Metodo = 'Efectivo',
    @SimularDemora = 1,
    @BoletoID_Generado = @ID OUTPUT;

SELECT @ID AS BoletoGenerado_SesionA;
