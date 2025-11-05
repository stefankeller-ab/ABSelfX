# Logs sammeln
$Log = ""

function Add-Log($text) {
    $global:Log += "$text`r`n"
    Write-Host $text
}

# Namen der ausführbaren Dateien
$classicOutlook = "OUTLOOK"
$newOutlook = "olk"

# Pfade ermitteln
$classicPath = "C:\Program Files (x86)\Microsoft Office\root\Office16\OUTLOOK.EXE"
$newPath = (Get-Command $newOutlook -ErrorAction SilentlyContinue).Source

# Prüfen, welche Version läuft
$runningVersion = $null
if (Get-Process -Name $classicOutlook -ErrorAction SilentlyContinue) {
    $runningVersion = $classicOutlook
} elseif (Get-Process -Name $newOutlook -ErrorAction SilentlyContinue) {
    $runningVersion = $newOutlook
}

if ($runningVersion) {
    Add-Log("Beende $runningVersion...")
    Start-Process -FilePath "taskkill.exe" -ArgumentList "/IM $runningVersion.exe /F" -NoNewWindow -Wait
    Add-Log("Warte 3 Sekunden...")
    Start-Sleep -Seconds 3

    # Outlook neu starten
    $exePath = if ($runningVersion -eq $classicOutlook) { $classicPath } else { $newPath }
    if ($exePath -and (Test-Path $exePath)) {
        Add-Log("Starte $runningVersion erneut...")
        Start-Process -FilePath $exePath -WindowStyle Normal
        Add-Log("$runningVersion wurde erfolgreich neu gestartet.")
    } else {
        Add-Log("Fehler: Pfad für $runningVersion nicht gefunden.")
    }
} else {
    Add-Log("Keine Outlook-Version läuft derzeit.")
}

# Notification aufrufen und Logs übergeben
$Global:Current_Folder = Split-Path $MyInvocation.MyCommand.Path
$CurrentScript = Split-Path -Leaf $MyInvocation.MyCommand.Path
Start-Process -WindowStyle Hidden "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$Current_Folder\Notification.ps1`" -Script `"$CurrentScript`" -Logs `"$Log`""