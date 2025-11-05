# Logs sammeln
$Log = ""

function Add-Log($text) {
    $global:Log += "$text`r`n"
    Write-Host $text
}

# Sophos VPN-Client neu starten (nur mit taskkill)
$vpnGuiExe = "scgui.exe"
$vpnGuiPath = "C:\Program Files (x86)\Sophos\Connect\GUI\scgui.exe"

Add-Log("Beende Sophos VPN GUI...")
Start-Process -FilePath "taskkill.exe" -ArgumentList "/IM $vpnGuiExe /F" -NoNewWindow -Wait

Add-Log("Warte 2 Sekunden...")
Start-Sleep -Seconds 2

# Sophos Connect GUI starten
if (Test-Path $vpnGuiPath) {
    Add-Log("Starte Sophos VPN GUI...")
    Start-Process -FilePath $vpnGuiPath -WindowStyle Normal
    Add-Log("Sophos VPN-Client wurde erfolgreich gestartet.")
} else {
    Add-Log("Sophos VPN GUI-Pfad nicht gefunden: $vpnGuiPath")
}

# Notification aufrufen und Logs übergeben
$Current_Folder = Split-Path $MyInvocation.MyCommand.Path
$CurrentScript = Split-Path -Leaf $MyInvocation.MyCommand.Path
Start-Process -WindowStyle Hidden "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$Current_Folder\Notification.ps1`" -Script `"$CurrentScript`" -Logs `"$Log`""