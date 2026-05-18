$cpu = (Get-WmiObject Win32_Processor).Name
$mobo = (Get-WmiObject Win32_BaseBoard).Product
$fab = (Get-WmiObject Win32_Bios).Manufacturer
$ram = [math]::round((Get-WmiObject Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB)

Write-Host "--- INFO DO HARDWARE ---" -ForegroundColor Cyan
Write-Host "Fabricante: $fab"
Write-Host "Placa-Mãe: $mobo"
Write-Host "CPU: $cpu"
Write-Host "RAM: $ram GB"
pause
