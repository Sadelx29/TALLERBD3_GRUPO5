$server = "(localdb)\MSSQLLocalDB"
$baseDir = "C:\Users\s.fortunato\Documents\antigravity\lucid-nobel\BusRD-Grupo1\scripts"
$scriptA = Join-Path $baseDir "04_demo_concurrencia_sesionA.sql"
$scriptB = Join-Path $baseDir "05_demo_concurrencia_sesionB.sql"

Write-Host "Iniciando prueba de concurrencia..."
Write-Host "Ejecutando Sesion A (Tardara 10 segundos en confirmar el cobro)..."

$jobA = Start-Job -ScriptBlock {
    param($srv, $script)
    sqlcmd -S $srv -E -i $script
} -ArgumentList $server, $scriptA

Start-Sleep -Milliseconds 500

Write-Host "Ejecutando Sesion B (Intentando comprar el mismo asiento al mismo tiempo)..."
$jobB = Start-Job -ScriptBlock {
    param($srv, $script)
    sqlcmd -S $srv -E -i $script
} -ArgumentList $server, $scriptB

Write-Host "Esperando a que ambas sesiones terminen..."
Wait-Job -Job $jobA, $jobB | Out-Null

$outputA = Receive-Job -Job $jobA
$outputB = Receive-Job -Job $jobB

Write-Host "`n=================================================="
Write-Host "RESULTADO SESION A (Primera Transaccion)"
Write-Host "=================================================="
$outputA | ForEach-Object { Write-Host $_ }

Write-Host "`n=================================================="
Write-Host "RESULTADO SESION B (Segunda Transaccion Concurrente)"
Write-Host "=================================================="
$outputB | ForEach-Object { Write-Host $_ }
Write-Host "=================================================="

# Limpieza de jobs
Remove-Job -Job $jobA, $jobB
