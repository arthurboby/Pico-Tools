# mestre.ps1 - Versão ULTRA SIMPLES (abre o script no Bloco de Notas para você executar manualmente)
$u = "arthurboby"
$r = "Pico-Tools"

Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# Busca arquivos .ps1
$api = "https://api.github.com/repos/$u/$r/contents"
$res = Invoke-RestMethod -Uri $api -Method Get -UseBasicParsing

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

$form = New-Object System.Windows.Forms.Form
$form.Text = "GitHub Explorer"
$form.Size = "550,500"

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = "20,20"
$listBox.Size = "490,380"
foreach ($arquivo in $todosArquivos) {
    [void]$listBox.Items.Add($arquivo.path)
}
$form.Controls.Add($listBox)

$button = New-Object System.Windows.Forms.Button
$button.Text = "ABRIR SCRIPT (para executar manualmente)"
$button.Location = "20,420"
$button.Size = "490,40"
$button.Add_Click({
    if ($listBox.SelectedItem) {
        $caminho = $listBox.SelectedItem
        $url = "https://raw.githubusercontent.com/$u/$r/main/$caminho"
        $tempFile = "$env:TEMP\$([System.IO.Path]::GetFileName($caminho))"
        Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing
        Invoke-Item $tempFile  # Abre o script no editor padrão
    }
})
$form.Controls.Add($button)

$form.ShowDialog()
