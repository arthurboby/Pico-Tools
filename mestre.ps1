# Configurações do seu Repo (BitRun.OS)
$user = "arthurboby"
$repo = "Pico-Tools"
# ABAIXO: O link completo que estava faltando!
$urlApi = "https://github.com"

# Forçar segurança para o GitHub não bloquear o PC da escola
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Log-Pico($texto, $porcentagem) {
    try {
        $portName = (Get-PnpDevice -FriendlyName "*USB Serial Port*" -Status OK).Caption -replace ".*\(|\)"
        $port = New-Object System.IO.Ports.SerialPort $portName, 9600, None, 8, one
        $port.Open()
        $port.WriteLine("$($texto):$($porcentagem)")
        $port.Close()
    } catch {}
}

function Mostrar-Menu-Dinamico($caminho) {
    Log-Pico "Lendo Pasta" 30
    # O segredo está no "$urlApi/$caminho"
    $arquivos = Invoke-RestMethod -Uri "$urlApi/$caminho"
    $lista = $arquivos | Where-Object { $_.type -eq "file" }

    Clear-Host
    Write-Host "=== BitRun.OS // $caminho ===" -ForegroundColor Cyan
    if ($lista.Count -eq 0) { 
        Write-Host "Pasta vazia ou link da API incorreto." -ForegroundColor Red 
    } else {
        for ($i=0; $i -lt $lista.Count; $i++) {
            Write-Host "($($i+1)) $($lista[$i].name)"
        }
    }
    Write-Host "(0) Voltar"

    $opc = Read-Host "`nEscolha uma opção"
    if ($opc -eq "0" -or $opc -eq "") { return }

    $escolhido = $lista[[int]$opc - 1]
    Log-Pico "Baixando..." 60
    
    $conteudo = iwr -useb $escolhido.download_url
    Log-Pico "Executando" 90
    
    if ($escolhido.name.EndsWith(".ps1")) {
        iex $conteudo
    } else {
        $destino = "$home\Desktop\$($escolhido.name)"
        iwr -useb $escolhido.download_url -OutFile $destino
        Write-Host "Arquivo salvo na Área de Trabalho!" -ForegroundColor Green
    }
    Log-Pico "Concluido" 100
    pause
}

# Menu Principal no Terminal
do {
    Log-Pico "Menu Inicial" 10
    Clear-Host
    Write-Host "=== PICO-FLIPPER TERMINAL INTERFACE ===" -ForegroundColor Green
    Write-Host "(1) Pessoal"
    Write-Host "(2) Escola"
    Write-Host "(3) Coleta"
    Write-Host "(4) Limpar Rastros e Sair"
    $base = Read-Host "`nOpção"

    switch ($base) {
        "1" { Mostrar-Menu-Dinamico "pessoal" }
        "2" { Mostrar-Menu-Dinamico "escola" }
        "3" { Mostrar-Menu-Dinamico "coleta" }
        "4" { 
            Log-Pico "Limpando..." 50
            Clear-History
            Log-Pico "Adeus" 100
            exit 
        }
    }
} while ($true)
