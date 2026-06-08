# mestre.ps1 - GitHub Explorer (API de CONTEÚDO - FUNCIONA!)
$u = "arthurboby"
$r = "Pico-Tools"

Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# Função para listar todos os .ps1 (incluindo dentro de pastas)
function Buscar-PS1 {
    param($itens, $caminho = "")
    $resultados = @()
    foreach ($item in $itens) {
        if ($item.type -eq "file" -and $item.name -like "*.ps1") {
            $resultados += [PSCustomObject]@{path = if ($caminho) { "$caminho/$($item.name)" } else { $item.name } }
        }
        elseif ($item.type -eq "dir") {
            $subApi = "https://api.github.com/repos/$u/$r/contents/$($item.path)"
            $subItens = Invoke-RestMethod -Uri $subApi -Method Get -UseBasicParsing
            $resultados += Buscar-PS1 -itens $subItens -caminho $item.path
        }
    }
    return $resultados
}

try {
    Write-Host "Conectando ao GitHub..." -ForegroundColor Cyan
    $api = "https://api.github.com/repos/$u/$r/contents"
    $res = Invoke-RestMethod -Uri $api -Method Get -UseBasicParsing
    $files = Buscar-PS1 -itens $res
    
    if ($files.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Nenhum arquivo .ps1 encontrado!", "Erro")
        exit
    }
} catch {
    [System.Windows.Forms.MessageBox]::Show("Erro ao conectar: $_", "Erro")
    exit
}

# Interface gráfica
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
        $dl = "https://raw.githubusercontent.com/$u/$r/main/$p"
        $tmp = "$env:TEMP\$([System.IO.Path]::GetFileName($p))"
        
        $result = [System.Windows.Forms.MessageBox]::Show("Baixar e executar '$p'?", "Confirmar", "YesNo")
        if ($result -eq "Yes") {
            try {
                Invoke-WebRequest -Uri $dl -OutFile $tmp -UseBasicParsing
                & $tmp
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Erro ao executar: $_", "Erro")
            }
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Selecione um script primeiro!", "Aviso")
    }
})
$f.Controls.Add($btn)

$f.ShowDialog()
