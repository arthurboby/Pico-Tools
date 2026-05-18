Add-Type -AssemblyName System.Windows.Forms
$voice = New-Object -ComObject SpVoice

Write-Host "Iniciando modo instável..." -ForegroundColor Red

$timer = [System.Diagnostics.Stopwatch]::StartNew()
while($timer.Elapsed.TotalSeconds -lt 30) {
    $acao = Get-Random -Minimum 1 -Maximum 6

    switch ($acao) {
        1 { Start-Process "calc.exe" } # Abre a calculadora
        2 { Start-Process "notepad.exe" } # Abre o bloco de notas
        3 { (New-Object -ComObject Shell.Application).MinimizeAll() } # Minimiza tudo
        4 { $voice.Speak("I am watching you") } # Fala algo (em inglês funciona melhor)
        5 { Start-Process "https://google.com" } # Abre o navegador
    }

    Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 4)
}

# Ao final, fecha as calculadoras pra limpar a bagunça
Stop-Process -Name "calculator", "notepad" -ErrorAction SilentlyContinue
