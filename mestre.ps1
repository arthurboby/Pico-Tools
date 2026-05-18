# Configurações do seu Repo
$user = "arthurboby"
$repo = "Pico-Tools"
$urlApi = "https://api.github.com"

function Mostrar-Menu-Dinamico($caminho) {
    Clear-Host
    Write-Host "=== SELECIONE O ARQUIVO EM: $caminho ===" -ForegroundColor Cyan
    
    # Busca a lista de arquivos via API do GitHub
    $arquivos = Invoke-RestMethod -Uri "$urlApi/$caminho"
    $lista = $arquivos | Where-Object { $_.type -eq "file" }

    for ($i=0; $i -lt $lista.Count; $i++) {
        Write-Host "($($i+1)) $($lista[$i].name)"
    }
    Write-Host "(0) Voltar"

    $opc = Read-Host "`nEscolha uma opção"
    if ($opc -eq "0") { return }

    $escolhido = $lista[[int]$opc - 1]
    Write-Host "Baixando e Executando: $($escolhido.name)..." -ForegroundColor Yellow
    
    # Baixa o conteúdo do arquivo escolhido e executa (se for .ps1)
    $conteudo = Invoke-RestMethod -Uri $escolhido.download_url
    if ($escolhido.name.EndsWith(".ps1")) {
        ExecutionContext.InvokeCommand.InvokeScript($conteudo)
    } else {
        $destino = "$env:USERPROFILE\Desktop\$($escolhido.name)"
        Invoke-WebRequest -Uri $escolhido.download_url -OutFile $destino
        Write-Host "Arquivo salvo na Área de Trabalho!" -ForegroundColor Green
    }
    pause
}

# Menu Principal no Terminal do PC
do {
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
        "3" { # Aqui você pode rodar o seu script de coleta direto
             iwr -useb "LINK_RAW_DO_COLETA.PS1" | iex 
        }
        "4" { 
            Clear-History
            exit 
        }
    }
} while ($true)
