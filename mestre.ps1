# mestre.ps1 - GitHub Explorer (VERSÃO QUE FUNCIONA)
$u = "arthurboby"
$r = "Pico-Tools"

Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# Busca todos os arquivos .ps1 do repositório
$api = "https://api.github.com/repos/$u/$r/contents"
$res = Invoke-RestMethod -Uri $api -Method Get -UseBasicParsing

# Função para buscar arquivos recursivamente
$todosArquivos = @()
foreach ($item in $res) {
    if ($item.type -eq "file" -and $item.name -like "*.ps1") {
        $todosArquivos += $item
    }
    elseif ($item.type -eq "dir") {
        $subApi = "https://api.github.com/repos/$u/$r/contents/$($item.path)"
        $subRes = Invoke-RestMethod -Uri $subApi -Method Get -UseBasicParsing
        foreach ($subItem in $subRes) {
            if ($subItem.type -eq "file" -and $subItem.name -like "*.ps1") {
                $todosArquivos += $subItem
            }
        }
    }
}

if ($todosArquivos.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("Nenhum script .ps1 encontrado!", "Erro")
    exit
}

# Criar a interface gráfica
$form = New-Object System.Windows.Forms.Form
$form.Text = "GitHub Explorer - Pico-Tools"
$form.Size = New-Object System.Drawing.Size(550, 500)
$form.StartPosition = "CenterScreen"

$label = New-Object System.Windows.Forms.Label
$label.Text = "Selecione um script PowerShell para executar:"
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Size = New-Object System.Drawing.Size(500, 30)
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20, 60)
$listBox.Size = New-Object System.Drawing.Size(490, 320)
foreach ($arquivo in $todosArquivos) {
    [void]$listBox.Items.Add($arquivo.path)
}
$form.Controls.Add($listBox)

$button = New-Object System.Windows.Forms.Button
$button.Text = "▶ EXECUTAR SCRIPT SELECIONADO"
$button.Location = New-Object System.Drawing.Point(20, 400)
$button.Size = New-Object System.Drawing.Size(490, 50)
$button.Add_Click({
    if ($listBox.SelectedItem) {
        $caminho = $listBox.SelectedItem
        $url = "https://raw.githubusercontent.com/$u/$r/main/$caminho"
        $tempFile = "$env:TEMP\$([System.IO.Path]::GetFileName($caminho))"
        
        $confirmar = [System.Windows.Forms.MessageBox]::Show("Baixar e executar '$caminho'?", "Confirmar", "YesNo")
        if ($confirmar -eq "Yes") {
            Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing
            & $tempFile
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Selecione um script primeiro!", "Aviso")
    }
})
$form.Controls.Add($button)

$form.ShowDialog()
