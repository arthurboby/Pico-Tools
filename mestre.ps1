# mestre.ps1 - GitHub Explorer (CORRIGIDO)
$u = "arthurboby"
$r = "Pico-Tools"
$b = "main"

Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# 👇 URL CORRETA da API do GitHub
$api = "https://api.github.com/repos/$u/$r/git/trees/$b?recursive=1"

try {
    Write-Host "Conectando ao GitHub..." -ForegroundColor Cyan
    $res = Invoke-RestMethod -Uri $api -Method Get -UseBasicParsing
    
    # Filtra apenas arquivos .ps1
    $files = $res.tree | Where-Object { $_.path -like "*.ps1" -and $_.type -eq "blob" }
    
    if ($files.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Nenhum arquivo .ps1 encontrado no repositorio!", "Erro")
        exit
    }
} catch {
    [System.Windows.Forms.MessageBox]::Show("Erro ao conectar ao GitHub: $_", "Erro")
    exit
}

# Interface
$f = New-Object System.Windows.Forms.Form
$f.Text = "GitHub Explorer - Pico-Tools"
$f.Size = New-Object System.Drawing.Size(550, 500)
$f.StartPosition = "CenterScreen"

$label = New-Object System.Windows.Forms.Label
$label.Text = "Selecione um script para executar:"
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Size = New-Object System.Drawing.Size(500, 25)
$f.Controls.Add($label)

$lb = New-Object System.Windows.Forms.ListBox
$lb.Location = New-Object System.Drawing.Point(20, 55)
$lb.Size = New-Object System.Drawing.Size(490, 300)
foreach ($i in $files) {
    [void]$lb.Items.Add($i.path)
}
$f.Controls.Add($lb)

$btn = New-Object System.Windows.Forms.Button
$btn.Text = "BAIXAR E EXECUTAR"
$btn.Location = New-Object System.Drawing.Point(20, 370)
$btn.Size = New-Object System.Drawing.Size(490, 40)
$btn.Add_Click({
    if ($lb.SelectedItem) {
        $p = $lb.SelectedItem
        $dl = "https://raw.githubusercontent.com/$u/$r/$b/$p"
        $tmp = "$env:TEMP\$([System.IO.Path]::GetFileName($p))"
        
        $result = [System.Windows.Forms.MessageBox]::Show("Baixar e executar '$p'?", "Confirmar", "YesNo")
        if ($result -eq "Yes") {
            Invoke-WebRequest -Uri $dl -OutFile $tmp -UseBasicParsing
            & $tmp
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Selecione um script primeiro!", "Aviso")
    }
})
$f.Controls.Add($btn)

$f.ShowDialog()
