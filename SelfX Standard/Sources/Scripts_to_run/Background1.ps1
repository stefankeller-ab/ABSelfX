<#
.SYNOPSIS
  Setzt ein festes Desktop-Hintergrundbild (HKCU) und wendet es sofort an.

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

# --- Standardpfad, falls keiner angegeben
if (-not $ImagePath) {
    $ImagePath = Join-Path $PSScriptRoot 'Backgrounds\Desktop-Hintergrund.jpg'
}

# --- Bild prüfen
if (-not (Test-Path -LiteralPath $ImagePath -PathType Leaf)) {
    Write-Host "Bild nicht gefunden: $ImagePath"
    exit 1
}

# --- Style-Mapping
$styleMap = @{
    'Fill'    = @{ WallpaperStyle = '10'; TileWallpaper = '0' }
    'Fit'     = @{ WallpaperStyle = '6';  TileWallpaper = '0' }
    'Stretch' = @{ WallpaperStyle = '2';  TileWallpaper = '0' }
    'Tile'    = @{ WallpaperStyle = '0';  TileWallpaper = '1' }
    'Center'  = @{ WallpaperStyle = '0';  TileWallpaper = '0' }
    'Span'    = @{ WallpaperStyle = '22'; TileWallpaper = '0' }
}
$sel = $styleMap[$Style]

# --- Registry (HKCU) setzen
$regPath = 'HKCU:\Control Panel\Desktop'
Set-ItemProperty -Path $regPath -Name WallpaperStyle -Value $sel.WallpaperStyle
Set-ItemProperty -Path $regPath -Name TileWallpaper   -Value $sel.TileWallpaper
Set-ItemProperty -Path $regPath -Name Wallpaper       -Value $ImagePath

# --- Zuverlässig anwenden via SystemParametersInfo (PS 5.1-kompatibel)
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class NativeMethods {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

$SPI_SETDESKWALLPAPER = 20;
$SPIF_UPDATEINIFILE   = 0x01;
$SPIF_SENDCHANGE      = 0x02;

$ok = [NativeMethods]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $ImagePath, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
if (-not $ok) {
    $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    Write-Warning "SystemParametersInfo schlug fehl (Win32Error=$err). Ab-/Anmeldung könnte nötig sein."
}

Write-Host "Hintergrundbild gesetzt:`n  Datei: $ImagePath`n  Stil: $Style"