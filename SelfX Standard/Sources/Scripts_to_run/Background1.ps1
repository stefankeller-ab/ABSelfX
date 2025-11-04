<#
.SYNOPSIS
  Setzt ein festes Desktop-Hintergrundbild (HKCU) und aktualisiert es sofort.

.PARAMETER ImagePath
  Optionaler Pfad zur Bilddatei (JPG/PNG/BMP).
  Wenn nicht angegeben, wird .\Backgrounds\Desktop-Hintergrund.jpg (relativ zum Skript) verwendet.

.PARAMETER Style
  Fill | Fit | Stretch | Tile | Center | Span
#>

param(
    [string]$ImagePath,
    [ValidateSet('Fill','Fit','Stretch','Tile','Center','Span')]
    [string]$Style = 'Fill'
)

# --- Standardpfad sicher bestimmen ---
if (-not $ImagePath) {
    $scriptDir = $PSScriptRoot
    if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
    $ImagePath = Join-Path $scriptDir 'Backgrounds\Desktop-Hintergrund.jpg'
}

# --- Bild prüfen ---
if (-not (Test-Path -LiteralPath $ImagePath -PathType Leaf)) {
    Write-Host "Bild nicht gefunden: $ImagePath"
    exit 1
}

# --- Style-Mapping (HKCU\Control Panel\Desktop) ---
$styleMap = @{
    'Fill'    = @{ WallpaperStyle = '10'; TileWallpaper = '0' }
    'Fit'     = @{ WallpaperStyle = '6';  TileWallpaper = '0' }
    'Stretch' = @{ WallpaperStyle = '2';  TileWallpaper = '0' }
    'Tile'    = @{ WallpaperStyle = '0';  TileWallpaper = '1' }
    'Center'  = @{ WallpaperStyle = '0';  TileWallpaper = '0' }
    'Span'    = @{ WallpaperStyle = '22'; TileWallpaper = '0' }
}
$sel = $styleMap[$Style]

# --- Registry (HKCU) setzen ---
$regPath = 'HKCU:\Control Panel\Desktop'
Set-ItemProperty -Path $regPath -Name WallpaperStyle -Value $sel.WallpaperStyle
Set-ItemProperty -Path $regPath -Name TileWallpaper   -Value $sel.TileWallpaper
Set-ItemProperty -Path $regPath -Name Wallpaper       -Value $ImagePath

# --- Zuverlässig anwenden via SystemParametersInfo (ohne Here-String/using) ---
Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition '
[System.Runtime.InteropServices.DllImport("user32.dll", SetLastError=true, CharSet=System.Runtime.InteropServices.CharSet.Auto)]
public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
'

$SPI_SETDESKWALLPAPER = 20
$SPIF_UPDATEINIFILE   = 0x01
$SPIF_SENDCHANGE      = 0x02

[void][Win32.NativeMethods]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $ImagePath, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)

Write-Host "Hintergrundbild gesetzt:`n  Datei: $ImagePath`n  Stil: $Style"