# Namen der ausführbaren Dateien
$classicOutlook = "OUTLOOK.EXE"
$newOutlook = "NewOutlook.exe"

# Funktion: Prüfen, ob Prozess läuft
function Is-ProcessRunning($processName) {
    Get-Process -Name $processName -ErrorAction SilentlyContinue
}

# Funktion: Prozess beenden
function Kill-Process($processName) {
    Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue
}

# Ermitteln, welche Version läuft
$runningVersion = $null
if (Is-ProcessRunning $classicOutlook) {
    $runningVersion = $classicOutlook
} elseif (Is-ProcessRunning $newOutlook) {
    $runningVersion = $newOutlook
}

if ($runningVersion) {
    Write-Host "$runningVersion wird geschlossen..."
    Kill-Process $runningVersion
    Start-Sleep -Seconds 3

    # Pfad zur EXE ermitteln und neu starten
    $exePath = (Get-Command $runningVersion).Source
    if ($exePath) {
        Write-Host "$runningVersion wird neu gestartet..."
        Start-Process $exePath
    } else {
        Write-Host "Fehler: $runningVersion konnte nicht gefunden werden."
    }
} else {
    Write-Host "Keine Outlook-Version läuft derzeit."
}