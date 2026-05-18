$destino = "$home\Desktop\Jogar_Minecraft.exe"
Write-Host "Baixando Minecraft..." -ForegroundColor Green
iwr -useb "https://github.com" -OutFile $destino
Start-Process $destino
