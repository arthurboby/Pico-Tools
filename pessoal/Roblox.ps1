$destino = "$home\Desktop\Instalar_Roblox.exe"
Write-Host "Baixando para a Área de Trabalho..." -ForegroundColor Cyan
iwr -useb "https://rbxcdn.com" -OutFile $destino
Start-Process $destino
