param(
  # Si el DNS de tu red no resuelve el dominio, pasa la IP publica: -ResolveIp 104.41.63.108
  [string]$ResolveIp = ""
)

$hostName = "fibonacci-lab-hs2026.azurewebsites.net"
$url = "https://$hostName/api/FibonacciMemo"
$bodyFile = Join-Path $env:TEMP "fibo_body.json"

# Secuencia de la demo (subida gradual + repetido + salto grande)
$values = @(40, 100, 1000, 5000, 7000, 7000, 8000, 20000)

$resolveArgs = @()
if ($ResolveIp -ne "") { $resolveArgs = @("--resolve", "${hostName}:443:${ResolveIp}") }

$rows = foreach ($n in $values) {
  "{`"nth`": $n}" | Set-Content $bodyFile -NoNewline -Encoding ascii
  $out = & curl.exe @resolveArgs -sS -m 120 -w "|%{http_code}|%{time_total}" -X POST $url `
        -H "Content-Type: application/json" --data-binary "@$bodyFile" 2>&1
  $raw = ($out -join "")
  $parts = $raw -split "\|"
  $code = $parts[1]
  $time = $parts[2]
  $obj = $null
  try { $obj = $parts[0] | ConvertFrom-Json } catch {}

  [pscustomobject]@{
    nth       = $n
    HTTP      = $code
    wasCached = if ($obj) { $obj.wasCached } else { "-" }
    cacheSize = if ($obj) { $obj.cacheSize } else { "-" }
    tiempo    = "$time s"
    resultado = if ($obj -and $obj.error) { "STACK OVERFLOW" }
                elseif ($obj) { "OK ($($obj.result.Length) digitos)" }
                else { "?" }
  }
}

$rows | Format-Table -AutoSize
