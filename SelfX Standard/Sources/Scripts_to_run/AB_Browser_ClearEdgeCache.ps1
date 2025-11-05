# Logs sammeln
$Log = ""
function Add-Log($text) {
    $global:Log += "$text`r`n"
    Write-Host $text
}

# Wer bin ich?
Add-Log ("Running as: " + [Security.Principal.WindowsIdentity]::GetCurrent().Name)

# 1) Edge beenden (CIM statt WMI)
try {
    Get-CimInstance Win32_Process -Filter "name LIKE '%msedge%'" | ForEach-Object {
        $_ | Invoke-CimMethod -MethodName Terminate | Out-Null
    }
    Add-Log "Edge-Prozesse beendet."
}
catch { Add-Log "Fehler beim Beenden von Edge: $($_.Exception.Message)" }

# 2) Angemeldeten Benutzer und dessen Profilpfad ermitteln
function Get-LoggedOnUserProfilePath {
    # Nimm den Owner von explorer.exe (interaktive Sitzung)
    $explorer = Get-Process -Name explorer -IncludeUserName -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $explorer -or -not $explorer.UserName) { return $null }

    $nt = New-Object System.Security.Principal.NTAccount($explorer.UserName)
    $sid = $nt.Translate([System.Security.Principal.SecurityIdentifier]).Value
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid"
        $profile = (Get-ItemProperty -Path $regPath -ErrorAction Stop).ProfileImagePath
        return $profile
    } catch {
        return $null
    }
}

$targetProfile = $env:USERPROFILE
# Falls wir als SYSTEM/Admin laufen, überschreibe mit interaktivem Profil
if ([Security.Principal.WindowsIdentity]::GetCurrent().IsSystem -or
    -not (Test-Path (Join-Path $env:LOCALAPPDATA '.'))) {
    $alt = Get-LoggedOnUserProfilePath
    if ($alt) { $targetProfile = $alt }
}

Add-Log "Ziel-Profil: $targetProfile"

if (-not $targetProfile -or -not (Test-Path $targetProfile)) {
    Add-Log "Kein gültiges Zielprofil gefunden. Abbruch."
    exit 1
}

# 3) Edge-Pfade
$edgeRoot = Join-Path $targetProfile 'AppData\Local\Microsoft\Edge\User Data'
if (-not (Test-Path $edgeRoot)) {
    Add-Log "Edge User Data nicht gefunden: $edgeRoot"
    exit 0
}

# Optional: alle Profile ('Default' + 'Profile *') bearbeiten
$profiles = @('Default')
$profiles += (Get-ChildItem -Path $edgeRoot -Directory -Filter 'Profile *' -ErrorAction SilentlyContinue).Name
$profiles = $profiles | Select-Object -Unique

$possibleCachePaths = @(
    'Cache', 'Cache2\entries', 'Cookies', 'Cookies-Journal', 'History', 
    'Top Sites', 'VisitedLinks', 'Web Data', 'Media Cache', 'EdgeDWriteFontCache'
)

foreach ($p in $profiles) {
    $edgeAppData = Join-Path $edgeRoot $p
    if (Test-Path $edgeAppData) {
        Add-Log "Bereinige Profil: $p  ($edgeAppData)"
        foreach ($cachePath in $possibleCachePaths) {
            $target = Join-Path $edgeAppData $cachePath
            try {
                if (Test-Path $target) {
                    Remove-Item $target -Force -Recurse -ErrorAction Stop
                    Add-Log "OK: $p -> $cachePath"
                } else {
                    Add-Log "Fehlt: $p -> $cachePath"
                }
            } catch {
                Add-Log "FEHLER: $p -> $cachePath : $($_.Exception.Message)"
            }
        }
    }
}

# 4) Notification starten – benutze $PSScriptRoot statt $MyInvocation
try {
    $Current_Folder = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Path $MyInvocation.MyCommand.Path -Parent }
    $CurrentScript  = if ($MyInvocation.MyCommand.Path) { Split-Path -Leaf $MyInvocation.MyCommand.Path } else { $null }

    if ($Current_Folder -and (Test-Path (Join-Path $Current_Folder 'Notification.ps1'))) {
        Start-Process -WindowStyle Hidden "powershell.exe" -ArgumentList @(
            '-ExecutionPolicy','Bypass',
            '-File', (Join-Path $Current_Folder 'Notification.ps1'),
            '-Script', $CurrentScript,
            '-Logs',   $Log
        )
        Add-Log "Notification.ps1 gestartet."
    } else {
        Add-Log "Notification.ps1 nicht gefunden."
    }
} catch {
    Add-Log "Fehler beim Start der Notification: $($_.Exception.Message)"
}