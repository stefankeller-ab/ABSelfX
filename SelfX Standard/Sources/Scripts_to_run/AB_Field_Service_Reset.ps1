# App Name
$appName = "MicrosoftCorporationII.FieldServiceDynamics365"

# App holen
$package = Get-AppxPackage $appName

if (-not $package) {
    Write-Host "Field Service App nicht gefunden"
    exit
}

Write-Host "Setze App zurück..."

# Reset durchführen
try {
    $package | Reset-AppxPackage
    Write-Host "Reset erfolgreich"
} catch {
    Write-Host "Fehler beim Reset"
    exit
}

# kleiner Delay (wichtig, damit Reset sauber durch ist)
Start-Sleep -Seconds 2

Write-Host "Starte Field Service..."

# App starten
Start-Process "shell:AppsFolder\MicrosoftCorporationII.FieldServiceDynamics365_8wekyb3d8bbwe!App"

Write-Host "Fertig"