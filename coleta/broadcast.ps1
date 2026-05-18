# SCRIPT DE MENSAGEM EM MASSA (VIA MSG COMMAND)
Clear-Host
$texto = Read-Host "O que deseja dizer para a rede?"
$titulo = "ALERTA DO SISTEMA"

# 1. DISFARCE (SPOOFING)
# O 'msg *' mostra o nome do computador que enviou. 
# Vamos mudar o nome do SEU pc na rede temporariamente para algo oficial.
$nomeAntigo = $env:COMPUTERNAME
$novoNome = "SERVIDOR-REDE-SALA01" # Nome fake
# Nota: Mudar o nome real exige reiniciar, então vamos focar no disfarce do Título.

Write-Host "Enviando mensagem para todos os terminais..." -ForegroundColor Cyan

# 2. VARREDURA DE REDE
# Pega o IP local e tenta enviar para todos os endereços da sub-rede
$ipBase = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127*" }).IPAddress.SubString(0,10)

1..254 | ForEach-Object {
    $target = "$ipBase.$_"
    # O '*' envia para todas as sessões do IP alvo
    # Usamos o 'cmd /c' para garantir que o comando legado rode sem erro
    Start-Process cmd -ArgumentList "/c msg /server:$target * /time:60 $texto" -WindowStyle Hidden
}

Write-Host "Transmissão concluída." -ForegroundColor Green
pause
