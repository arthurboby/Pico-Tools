# Mestre.ps1 - GitHub Explorer para Pico-Tools
$u = "arthurboby"
$r = "Pico-Tools"
$b = "main"

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# API do GitHub para buscar arquivos
$api = "https://api.github.com/repos/$u/$r/git/trees/$b?recursive=1"

try {
    Write-Host "Conectando ao GitHub..." -ForegroundColor Cyan
    $res = Invoke-RestMethod -Uri $api -Method Get
    $files = $res.tree | Where-Object { $_.path -like "*.ps1" -and $_.type -eq "blob" }
    
    if ($files.Count -eq 0) {
        Write-Host "Nenhum arquivo .ps1 encontrado!" -ForegroundColor Red
        Read-Host "Pressione Enter para sair"
        exit
    }
} catch {
    Write-Host "Erro ao conectar ao GitHub: $_" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit
}

# Criar formulário
$form = New-Object System.Windows.Forms.Form
$form.Text = "GitHub Explorer - Pico-Tools"
$form.Size = New-Object System.Drawing.Size(550, 500)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

# Título
$label = New-Object System.Windows.Forms.Label
$label.Text = "Selecione um script PowerShell para executar:"
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Size = New-Object System.Drawing.Size(500, 25)
$label.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($label)

# Lista de scripts
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20, 55)
$listBox.Size = New-Object System.Drawing.Size(490, 300)
$listBox.Font = New-Object System.Drawing.Font("Consolas", 10)

foreach ($file in $files) {
    [void]$listBox.Items.Add($file.path)
}

$form.Controls.Add($listBox)

# Botão Executar
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "▶ EXECUTAR SCRIPT SELECIONADO"
$btnRun.Location = New-Object System.Drawing.Point(20, 370)
$btnRun.Size = New-Object System.Drawing.Size(240, 40)
$btnRun.BackColor = [System.Drawing.Color]::FromArgb(50, 200, 50)
$btnRun.ForeColor = [System.Drawing.Color]::White
$btnRun.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)

$btnRun.Add_Click({
    if ($listBox.SelectedItem) {
        $selected = $listBox.SelectedItem
        $url = "https://raw.githubusercontent.com/$u/$r/$b/$selected"
        $tempFile = [System.IO.Path]::Combine($env:TEMP, [System.IO.Path]::GetFileName($selected))
        
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Deseja baixar e executar '$selected'?`n`nURL: $url",
            "Confirmar Execução",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            try {
                Write-Host "Baixando $selected..." -ForegroundColor Yellow
                Invoke-WebRequest -Uri $url -OutFile $tempFile
                Write-Host "Executando $selected..." -ForegroundColor Green
                & $tempFile
            } catch {
                [System.Windows.Forms.MessageBox]::Show(
                    "Erro ao executar: $_",
                    "Erro",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            }
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "Selecione um script primeiro!",
            "Aviso",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
    }
})

$form.Controls.Add($btnRun)

# Botão Cancelar
$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "✖ CANCELAR"
$btnCancel.Location = New-Object System.Drawing.Point(280, 370)
$btnCancel.Size = New-Object System.Drawing.Size(240, 40)
$btnCancel.BackColor = [System.Drawing.Color]::FromArgb(200, 50, 50)
$btnCancel.ForeColor = [System.Drawing.Color]::White
$btnCancel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)

$btnCancel.Add_Click({
    $form.Close()
})

$form.Controls.Add($btnCancel)

# Informações
$info = New-Object System.Windows.Forms.Label
$info.Text = "Repositório: $u/$r | Branch: $b | Total: $($files.Count) scripts"
$info.Location = New-Object System.Drawing.Point(20, 430)
$info.Size = New-Object System.Drawing.Size(500, 25)
$info.Font = New-Object System.Drawing.Font("Arial", 8)
$info.ForeColor = [System.Drawing.Color]::Gray
$form.Controls.Add($info)

# Mostrar formulário
$form.ShowDialog() | Out-Null
