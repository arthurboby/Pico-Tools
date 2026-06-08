# mestre.ps1 - GitHub Explorer
$u="arthurboby"
$r="Pico-Tools"
$b="main"

Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# Busca arquivos .ps1 do GitHub
$api="https://api.github.com/repos/$u/$r/git/trees/$b?recursive=1"
$res=Invoke-RestMethod -Uri $api -Method Get -UseBasicParsing
$files=$res.tree|Where-Object{$_.path -like "*.ps1"}

# Interface
$f=New-Object System.Windows.Forms.Form
$f.Text="GitHub Explorer - Pico-Tools"
$f.Size="550,500"

$lb=New-Object System.Windows.Forms.ListBox
$lb.Location="20,40"
$lb.Size="490,300"
foreach($i in $files){[void]$lb.Items.Add($i.path)}
$f.Controls.Add($lb)

$btn=New-Object System.Windows.Forms.Button
$btn.Text="BAIXAR E EXECUTAR"
$btn.Location="20,360"
$btn.Size="490,40"
$btn.Add_Click({
    if($lb.SelectedItem){
        $p=$lb.SelectedItem
        $dl="https://raw.githubusercontent.com/$u/$r/$b/$p"
        $tmp="$env:TEMP\$([System.IO.Path]::GetFileName($p))"
        Invoke-WebRequest -Uri $dl -OutFile $tmp -UseBasicParsing
        & $tmp
    }
})
$f.Controls.Add($btn)

$f.ShowDialog()
