param(
  [int]$Requests = 10,
  [string]$Collection = "$PSScriptRoot\fibonacci.postman_collection.json",
  [string]$OutDir = "$PSScriptRoot\_results"
)

# --- Verificar DNS (Newman usa el DNS del sistema) ---
$baseUrl = ""
try {
  $collJson = Get-Content $Collection -Raw | ConvertFrom-Json
  $baseUrl = ($collJson.variable | Where-Object { $_.key -eq 'baseUrl' }).value
} catch {}
if (-not $baseUrl) { $baseUrl = "https://fibonacci-lab-hs2026.azurewebsites.net" }
$hostName = ([System.Uri]$baseUrl).Host
try {
  $ipCheck = [System.Net.Dns]::GetHostAddresses($hostName) | Select-Object -First 1
  Write-Host "DNS OK: $hostName -> $ipCheck" -ForegroundColor Green
} catch {
  Write-Host "ERROR: No se puede resolver '$hostName' (DNS)." -ForegroundColor Red
  Write-Host "Cambia el DNS a 1.1.1.1 / 8.8.8.8 o usa hotspot, y reintenta." -ForegroundColor Yellow
  return
}

# Lanza N instancias de Newman EN PARALELO (Newman por si solo es secuencial).
# Cada instancia dispara 1 peticion -> N peticiones concurrentes.

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
Get-ChildItem $OutDir -Filter "run-*.json" -ErrorAction SilentlyContinue | Remove-Item -Force

$collectionPath = (Resolve-Path $Collection).Path
Write-Host "Lanzando $Requests peticiones concurrentes con Newman..." -ForegroundColor Cyan

$jobs = 1..$Requests | ForEach-Object {
  $idx = $_
  Start-Job -ScriptBlock {
    param($coll, $idx, $outDir)
    $export = Join-Path $outDir ("run-{0:D2}.json" -f $idx)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $null = newman run $coll --reporters json --reporter-json-export $export 2>&1
    $sw.Stop()
    [pscustomobject]@{ Idx = $idx; ExitCode = $LASTEXITCODE; ElapsedMs = $sw.ElapsedMilliseconds; Export = $export }
  } -ArgumentList $collectionPath, $idx, $OutDir
}

$jobResults = $jobs | Wait-Job | Receive-Job
$jobs | Remove-Job

$rows = foreach ($jr in $jobResults) {
  if (Test-Path $jr.Export) {
    $j = Get-Content $jr.Export -Raw | ConvertFrom-Json
    $exec = $j.run.executions[0]
    [pscustomobject]@{
      Peticion   = $jr.Idx
      EstadoHTTP = $exec.response.code
      TiempoMs   = [int]$exec.response.responseTime
      Ok         = ($exec.response.code -eq 200)
    }
  } else {
    [pscustomobject]@{ Peticion = $jr.Idx; EstadoHTTP = "ERR"; TiempoMs = $jr.ElapsedMs; Ok = $false }
  }
}

$rows = $rows | Sort-Object Peticion
$rows | Format-Table -AutoSize

$total = @($rows).Count
$ok = @($rows | Where-Object { $_.Ok }).Count
$fail = $total - $ok
$times = @($rows | Where-Object { $_.Ok } | Select-Object -ExpandProperty TiempoMs)
$min = 0; $max = 0; $avg = 0
if ($times.Count -gt 0) {
  $min = ($times | Measure-Object -Minimum).Minimum
  $max = ($times | Measure-Object -Maximum).Maximum
  $avg = [math]::Round(($times | Measure-Object -Average).Average, 0)
}

Write-Host ""
Write-Host "================ INFORME ================" -ForegroundColor Green
Write-Host "Peticiones concurrentes : $Requests"
Write-Host "Exitosas (HTTP 200)     : $ok"
Write-Host "Fallidas                : $fail"
Write-Host "Tiempo min / prom / max : $min ms / $avg ms / $max ms"
Write-Host "========================================" -ForegroundColor Green
