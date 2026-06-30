# =============================================
# MESTRE.PS1 - Orquestrador de Scripts Pico-Tools
# =============================================

# Configurações do Repositório
$Dono = "arthurboby"
$Repo = "Pico-Tools"
$Branch = "main"
$UrlBase = "https://raw.githubusercontent.com/$Dono/$Repo/$Branch"

# Cores para o Menu
$CorTitulo = "Cyan"
$CorMenu = "Yellow"
$CorDestaque = "Green"

function Mostrar-Menu {
    Clear-Host
    Write-Host "=========================================" -ForegroundColor $CorTitulo
    Write-Host "  GERENCIADOR PICO-TOOLS - LABORATÓRIO" -ForegroundColor $CorTitulo
    Write-Host "=========================================" -ForegroundColor $CorTitulo
    Write-Host ""
    Write-Host "Selecione a categoria:" -ForegroundColor $CorMenu
    Write-Host "[1] 🛠️  Ferramentas da Escola (Produtividade)" -ForegroundColor White
    Write-Host "[2] 💻 Ferramentas Pessoais (Dev & Automação)" -ForegroundColor White
    Write-Host "[3] 📊 Coleta de Dados (Diagnóstico)" -ForegroundColor White
    Write-Host "[0] Sair" -ForegroundColor Red
    Write-Host ""
}

function Listar-Scripts {
    param($Categoria)
    
    # Lista de scripts por categoria (mapeamento manual baseado na estrutura)
    $scripts = @{
        "escola" = @(
            @{Nome="Tradutor.ps1"; Desc="Tradução rápida de textos"},
            @{Nome="Foco.ps1"; Desc="Ferramenta para manter o foco"}
        )
        "pessoal" = @(
            @{Nome="Deploy_IDE.ps1"; Desc="Instalação de IDEs e ferramentas"},
            @{Nome="Setup_Ambiente.ps1"; Desc="Configuração do ambiente dev"}
        )
        "coleta" = @(
            @{Nome="Troll_mouse.ps1"; Desc="Diagnóstico de mouse (efeito visual)"},
            @{Nome="Info_System.ps1"; Desc="Coleta de informações do sistema"}
        )
    }
    
    return $scripts[$Categoria]
}

function Executar-Script {
    param($Categoria, $NomeScript)
    
    $UrlScript = "$UrlBase/$Categoria/$NomeScript"
    $PastaTemp = [System.IO.Path]::GetTempPath()
    $CaminhoTemp = Join-Path $PastaTemp $NomeScript
    
    try {
        Write-Host "`n⬇️  Baixando script: $NomeScript ..." -ForegroundColor $CorDestaque
        Invoke-WebRequest -Uri $UrlScript -OutFile $CaminhoTemp -ErrorAction Stop
        
        Write-Host "✅ Script baixado com sucesso!" -ForegroundColor $CorDestaque
        
        # Mostra o código para verificação rápida
        Write-Host "`n--- CÓDIGO DO SCRIPT ---" -ForegroundColor Cyan
        Get-Content $CaminhoTemp -Head 10
        Write-Host "... (script truncado para visualização)" -ForegroundColor DarkGray
        Write-Host "--- FIM DA VISUALIZAÇÃO ---`n" -ForegroundColor Cyan
        
        $confirmacao = Read-Host "Executar este script? (S/N)"
        if ($confirmacao -eq 'S') {
            Write-Host "`n🚀 Executando script..." -ForegroundColor $CorDestaque
            & $CaminhoTemp
            Write-Host "`n✅ Execução finalizada!" -ForegroundColor $CorDestaque
        } else {
            Write-Host "⏹️  Execução cancelada." -ForegroundColor Yellow
        }
        
        Read-Host "`nPressione Enter para continuar"
    }
    catch {
        Write-Host "❌ Erro ao processar script: $_" -ForegroundColor Red
        Read-Host "`nPressione Enter para continuar"
    }
    finally {
        if (Test-Path $CaminhoTemp) {
            Remove-Item $CaminhoTemp -Force -ErrorAction SilentlyContinue
        }
    }
}

# =============================================
# LOOP PRINCIPAL DO PROGRAMA
# =============================================
do {
    Mostrar-Menu
    $opcao = Read-Host "Digite a opção desejada"
    
    switch ($opcao) {
        "1" { 
            $categoria = "escola"
            $scripts = Listar-Scripts -Categoria $categoria
            if ($scripts) {
                Write-Host "`nScripts disponíveis:" -ForegroundColor $CorMenu
                for ($i=0; $i -lt $scripts.Count; $i++) {
                    Write-Host "[$($i+1)] $($scripts[$i].Nome) - $($scripts[$i].Desc)"
                }
                $escolha = Read-Host "`nSelecione o número do script (0 para voltar)"
                if ($escolha -ne "0" -and [int]$escolha -le $scripts.Count) {
                    $indice = [int]$escolha - 1
                    Executar-Script -Categoria $categoria -NomeScript $scripts[$indice].Nome
                }
            }
        }
        "2" { 
            $categoria = "pessoal"
            # Lógica similar à opção 1
            Write-Host "`n🔧 Funcionalidade em desenvolvimento..." -ForegroundColor Yellow
            Read-Host "`nPressione Enter para continuar"
        }
        "3" { 
            $categoria = "coleta"
            # Lógica similar à opção 1
            Write-Host "`n📊 Funcionalidade em desenvolvimento..." -ForegroundColor Yellow
            Read-Host "`nPressione Enter para continuar"
        }
        "0" { 
            Write-Host "`n👋 Saindo... Até logo!" -ForegroundColor $CorDestaque
        }
        default { 
            Write-Host "`n❌ Opção inválida!" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($opcao -ne "0")
