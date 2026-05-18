Add-Type -AssemblyName System.Windows.Forms
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$centerX = $screen.Width / 2
$centerY = $screen.Height / 2

Write-Host "Inversão de eixos ativada! Pressione CTRL+C para parar." -ForegroundColor Red

# Loop que dura 30 segundos (para não travar o PC pra sempre)
$timer = [System.Diagnostics.Stopwatch]::StartNew()
while($timer.Elapsed.TotalSeconds -lt 30) {
    $currentPos = [System.Windows.Forms.Cursor]::Position
    
    # Calcula a distância do centro e inverte
    $diffX = $currentPos.X - $centerX
    $diffY = $currentPos.Y - $centerY
    
    # Define a nova posição oposta
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(($centerX - $diffX), ($centerY - $diffY))
    
    Start-Sleep -Milliseconds 10
}
