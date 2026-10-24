USE BusRD;
GO

-- Sesion B: Intentar venta del mismo asiento (Deberia quedarse esperando y luego fallar)
DECLARE @ID INT;
EXEC dbo.sp_VenderBoleto 
    @ViajeID = 745,           
    @NumeroAsiento = 1,    
    @ClienteID = 2,
    @Canal = 'Web',
    @Metodo = 'Tarjeta',
    @SimularDemora = 0,
    @BoletoID_Generado = @ID OUTPUT;

SELECT @ID AS BoletoGenerado_SesionB;
