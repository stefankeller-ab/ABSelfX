# Sophos VPN-Client neu starten (nur mit taskkill)
$vpnGuiExe = "scgui.exe"
$vpnGuiPath = "C:\Program Files (x86)\Sophos\Connect\GUI\scgui.exe"

Write-Host "Beende Sophos VPN GUI..."
Start-Process -FilePath "taskkill.exe" -ArgumentList "/IM $vpnGuiExe /F" -NoNewWindow -Wait

Write-Host "Warte 2 Sekunden..."
Start-Sleep -Seconds 2

# Sophos Connect GUI starten
if (Test-Path $vpnGuiPath) {
    Write-Host "Starte Sophos VPN GUI..."
    Start-Process -FilePath $vpnGuiPath -WindowStyle Normal
    Write-Host "Sophos VPN-Client wurde erfolgreich gestartet."
} else {
    Write-Host "Sophos VPN GUI-Pfad nicht gefunden: $vpnGuiPath"
}