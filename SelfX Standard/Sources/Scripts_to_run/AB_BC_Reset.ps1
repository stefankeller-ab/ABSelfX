# BC App automatisch finden
$package = Get-AppxPackage | Where-Object {
    $_.Name -like "*BusinessCentral*" -or $_.Name -like "*Dynamics*Business*"
}

if (-not $package) {
    Write-Host "Business Central App nicht gefunden"
    exit
}

Write-Host "Gefundene App:" $package.Name

# Reset durchführen
try {
    Write-Host "Setze App zurück..."
    $package | Reset-AppxPackage
    Write-Host "Reset erfolgreich"
} catch {
    Write-Host "Fehler beim Reset"
    exit
}

# kurzer Delay
Start-Sleep -Seconds 2

# App starten (dynamisch)
$appId = (Get-StartApps | Where-Object {
    $_.Name -like "*Business Central*"
}).AppID

if (-not $appId) {
    Write-Host "AppID nicht gefunden"
    exit
}

Write-Host "Starte Business Central..."

Start-Process "shell:AppsFolder\$appId"

Write-Host "Fertig"