<#
.SYNOPSIS
  Aktiviert eine Desktop-Slideshow aus einem Ordner, mit "Füllen" pro Monitor (kein Span),
  ohne dauerhaft das Windows-Design (Hell/Dunkel) zu ändern.

.PARAMETER ImagesFolder
  Ordner mit Bildern. Standard: .\Backgrounds\Rotation (relativ zum Skript)

.PARAMETER IntervalMinutes
  Wechselintervall in Minuten (Standard 30)

.PARAMETER Shuffle
  1 = zufällig, 0 = der Reihenfolge nach

.PARAMETER ThemeName
  Anzeigename/Dateiname des Themas (Standard "Company-Slideshow")
#>

[CmdletBinding()]
param(
    [string]$ImagesFolder,
    [int]$IntervalMinutes = 30,
    [ValidateSet(0,1)]
    [int]$Shuffle = 1,
    [string]$ThemeName = "Company-Slideshow"
)

# --- 1) Standardordner bestimmen (relativ zum Skript) ---
if (-not $ImagesFolder) {
    $scriptDir = $PSScriptRoot
    if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
    $ImagesFolder = Join-Path $scriptDir 'Backgrounds\Rotation'
}

# --- 2) Ordner prüfen / absolut machen / trailing backslash entfernen ---
if (-not (Test-Path -LiteralPath $ImagesFolder -PathType Container)) {
    Write-Host "Bilderordner nicht gefunden: $ImagesFolder"
    exit 1
}
try { $ImagesFolder = (Resolve-Path -Path $ImagesFolder -ErrorAction Stop).Path } catch {}
$ImagesFolder = $ImagesFolder.TrimEnd('\')

# --- 3) Bilder ermitteln (unterstützte Formate) ---
$exts = @('*.jpg','*.jpeg','*.png','*.bmp')
$imgs = Get-ChildItem -Path $ImagesFolder -Recurse -File -ErrorAction SilentlyContinue -Include $exts
if (-not $imgs -or $imgs.Count -eq 0) {
    Write-Host "Im Ordner wurden keine unterstützten Bilder gefunden: $ImagesFolder"
    exit 1
}
$firstImage = $imgs[0].FullName

# --- 4) Theme-Datei (minimal) vorbereiten ---
$themeDir  = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Themes"
New-Item -Path $themeDir -ItemType Directory -Force | Out-Null
$themePath = Join-Path $themeDir ($ThemeName.Trim() + ".theme")

# --- 5) Intervall (ms) ---
$intervalMs = int

# --- 6) Minimalen Theme-Inhalt (copy-safe, kein Here-String) schreiben ---
$themeLines = @()
$themeLines += "[Theme]"
$themeLines += "DisplayName=$ThemeName"
$themeLines += ""
$themeLines += "[Control Panel\Desktop]"
$themeLines += "Wallpaper=$firstImage"
$themeLines += "WallpaperStyle=10"   # 10 = Fill
$themeLines += "TileWallpaper=0"
$themeLines += ""
$themeLines += "[Slideshow]"
$themeLines += "ImagesRootPath=$ImagesFolder"
$themeLines += "Interval=$intervalMs"
$themeLines += "Shuffle=$Shuffle"
$themeLines += ""
$themeLines += "[VisualStyles]"
$themeLines += "Path=%SystemRoot%\resources\Themes\Aero\Aero.msstyles"
$themeLines | Set-Content -Path $themePath -Encoding Unicode

# --- 7) Dark/Light-Setting sichern (und später wiederherstellen) ---
$persKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
$appsWas   = (Get-ItemProperty -Path $persKey -Name 'AppsUseLightTheme'   -ErrorAction SilentlyContinue).AppsUseLightTheme
$systemWas = (Get-ItemProperty -Path $persKey -Name 'SystemUsesLightTheme' -ErrorAction SilentlyContinue).SystemUsesLightTheme

# --- 8) Slideshow-Registry hinweise setzen (robuster) ---
try {
    New-Item -Path 'HKCU:\Control Panel\Desktop' -Force | Out-Null
    Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name 'SlideshowEnabled' -Value '1' -Force

    New-Item -Path 'HKCU:\Control Panel\Personalization\Desktop Slideshow' -Force | Out-Null
    New-ItemProperty 'HKCU:\Control Panel\Personalization\Desktop Slideshow' -Name 'Interval'       -PropertyType DWord -Value $intervalMs  -Force | Out-Null
    New-ItemProperty 'HKCU:\Control Panel\Personalization\Desktop Slideshow' -Name 'Shuffle'        -PropertyType DWord -Value $Shuffle     -Force | Out-Null
    New-ItemProperty 'HKCU:\Control Panel\Personalization\Desktop Slideshow' -Name 'ImagesRootPath' -PropertyType String -Value $ImagesFolder -Force | Out-Null
} catch { }

# --- 9) Theme anwenden ---
Start-Process -FilePath $themePath
Start-Sleep -Milliseconds 800  # kurzen Moment geben

# --- 10) "Füllen" pro Monitor erzwingen (kein Span) ---
try {
    # DESKTOP_WALLPAPER_POSITION: Center=0, Tile=1, Stretch=2, Fit=3, Fill=4, Span=5
    $dw = New-Object -ComObject DesktopWallpaper
    $dw.SetPosition(4)  # Fill
} catch {
    # Fallback: Stil in HKCU sicherstellen + Refresh
    try {
        Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name 'WallpaperStyle' -Value '10' -Force
        Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name 'TileWallpaper'  -Value '0'  -Force
        rundll32.exe user32.dll, UpdatePerUserSystemParameters 1, True | Out-Null
    } catch { }
}

# --- 11) Dark/Light-Mode wiederherstellen (wie der User es hatte) ---
try {
    if ($null -ne $appsWas)   { New-ItemProperty -Path $persKey -Name 'AppsUseLightTheme'    -PropertyType DWord -Value $appsWas   -Force | Out-Null }
    if ($null -ne $systemWas) { New-ItemProperty -Path $persKey -Name 'SystemUsesLightTheme' -PropertyType DWord -Value $systemWas -Force | Out-Null }
} catch { }

Write-Host "Slideshow aktiviert (Fill pro Monitor):`n  Ordner: $ImagesFolder`n  Bilder: $($imgs.Count)`n  Startbild: $firstImage`n  Intervall: $IntervalMinutes min`n  Shuffle: $Shuffle`n  Theme: $themePath"