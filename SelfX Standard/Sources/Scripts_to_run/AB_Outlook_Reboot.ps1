# Logs sammeln
$Log = ""

function Add-Log($text) {
    $global:Log += "$text`r`n"
    Write-Host $text
}

# Namen der ausführbaren Dateien
$classicOutlook = "OUTLOOK.EXE"
$newOutlook = "NewOutlook.exe"

function Is-ProcessRunning($processName) {
    Get-Process -Name $processName -ErrorAction SilentlyContinue
}

function Kill-Process($processName) {
    Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue
}

$runningVersion = $null
if (Is-ProcessRunning $classicOutlook) {
    $runningVersion = $classicOutlook
} elseif (Is-ProcessRunning $newOutlook) {
    $runningVersion = $newOutlook
}

if ($runningVersion) {
    Add-Log "$runningVersion wird geschlossen..."
    Kill-Process $runningVersion
    Start-Sleep -Seconds 3

    $exePath = (Get-Command $runningVersion).Source
    if ($exePath) {
        Add-Log "$runningVersion wird neu gestartet..."
        Start-Process $exePath
    } else {
        Add-Log "Fehler: $runningVersion konnte nicht gefunden werden."
    }
} else {
    Add-Log "Keine Outlook-Version läuft derzeit."
}

# Notification aufrufen und Logs übergeben
$Current_Folder = Split-Path $MyInvocation.MyCommand.Path
$CurrentScript = Split-Path -Leaf $MyInvocation.MyCommand.Path
Start-Process -WindowStyle Hidden "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$Current_Folder\Notification.ps1`" -Script `"$CurrentScript`" -Logs `"$Log`""