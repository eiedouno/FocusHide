$appName = Read-Host "Enter the name of the application to monitor (e.g., 'notepad')"
if (-not $appName) { exit }

# Path to your monitoring script file
$scriptPath = ".\bin\engine.ps1"

Write-Host "You can find me in the system tray. Right-click the icon to exit." -ForegroundColor Cyan
Start-Sleep -Milliseconds 3000

# Start a new classic console-hosted PowerShell process, hidden
Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -WindowStyle Hidden -File `"$scriptPath`" -appName `"$appName`"" -WindowStyle Hidden
