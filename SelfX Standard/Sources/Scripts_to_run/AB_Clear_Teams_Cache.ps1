<#
.SYNOPSIS
    Clear Teams (neues MSIX) Cache "sicher": loescht nur volatile Caches,
    bewahrt Hintergruende UND die zuletzt gewaehlte Hintergrund-Auswahl.

.PARAMETER Mode
    'Interactive' (Default) zeigt Dialog, 'Silent' laeuft ohne UI (Intune-tauglich).

.PARAMETER LogPath
    Zielpfad fuer Transcript/Log. Fallbacks: %ProgramData% -> %TEMP%

.PARAMETER ProcessName
    Teams-Prozessname (neues Teams: 'ms-teams').

.PARAMETER TeamsPackageId
    MSIX-Package-ID (Default: 'MSTeams_8wekyb3d8bbwe').

.EXITCODES
    0 = Erfolg, 1 = Benutzer abgebrochen, 2 = Fehler beim Clear, 3 = unerwarteter Fehler.
#>

# Logs sammeln
$Log = ""

function Add-Log($text) {
    $global:Log += "$text`r`n"
    Write-Host $Text
}

[CmdletBinding()]
param(
    [ValidateSet('Interactive','Silent')]
    [string]$Mode = 'Silent',

    [string]$ProcessName = 'ms-teams',

    [string]$TeamsPackageId = 'MSTeams_8wekyb3d8bbwe',

    [string]$LogPath = "C:\Temp\Logs\ClearTeams2.log"
)

# --- Option C: Self-Hide Bootstrap ------------------------------------------
# Wenn im sichtbaren ConsoleHost gestartet und noch nicht "hidden" -> neu starten versteckt
if ($Host.Name -eq 'ConsoleHost' -and $env:__CTS_HIDDEN -ne '1') {
    $env:__CTS_HIDDEN = '1'  # an Kindprozess vererbt
    try {
        $psExe = (Get-Command powershell.exe).Source
    } catch {
        $psExe = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
    }

    # Argumente zusammenbauen – vorhandene Parameter weiterreichen
    $args = @(
        '-NoProfile','-NoLogo','-NonInteractive','-ExecutionPolicy','Bypass',
        '-WindowStyle','Hidden','-File',"`"$PSCommandPath`""
    )
    foreach ($kvp in $PSBoundParameters.GetEnumerator()) {
        $name  = $kvp.Key
        $value = $kvp.Value
        switch ($name.ToLower()) {
            'mode'           { $args += @('-Mode', $value) }
            'logpath'        { $args += @('-LogPath', "`"$value`"") }
            'processname'    { $args += @('-ProcessName', $value) }
            'teamspackageid' { $args += @('-TeamsPackageId', $value) }
        }
    }

    Start-Process -FilePath $psExe -ArgumentList $args -WindowStyle Hidden | Out-Null
    exit
}
# -----------------------------------------------------------------------------


# --- Grundeinstellungen / Pfade ---
$ProgressPreference = 'SilentlyContinue'

$script:ProcessName     = $ProcessName
$script:TeamsCacheRoot  = Join-Path $env:LocalAppData ("Packages\" + $TeamsPackageId)
$script:MsTeamsLocal    = Join-Path $script:TeamsCacheRoot "LocalCache\Microsoft\MSTeams"
$script:BackgroundsPath = Join-Path $script:MsTeamsLocal  "Backgrounds"

$script:WV2Profile      = Join-Path $script:MsTeamsLocal "EBWebView\WV2Profile_tfw"
$script:KeepDirs        = @(
    (Join-Path $script:WV2Profile "IndexedDB"),
    (Join-Path $script:WV2Profile "Local Storage")
)
$script:KeepFile        = (Join-Path $script:WV2Profile "Preferences")  # Datei

# --- Exit/Transcript State ---
$script:ExitCode           = 0
$script:TranscriptStarted  = $false
$script:TranscriptPath     = $null

function Start-SafeTranscript {
    param([string]$PreferredPath)

    try {
        if ($PreferredPath) {
            $dir = Split-Path -Path $PreferredPath -Parent
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            Start-Transcript -Path $PreferredPath -Append | Out-Null
            $script:TranscriptStarted = $true
            $script:TranscriptPath    = $PreferredPath
            return
        }
    } catch {
        Write-Warning "Transcript (Primaer) fehlgeschlagen: $($_.Exception.Message)"
    }

    try {
        $companyDir = Join-Path $env:ProgramData "AllgaeuBatterie\Logs"
        if (-not (Test-Path $companyDir)) { New-Item -ItemType Directory -Path $companyDir -Force | Out-Null }
        $file = Join-Path $companyDir ("ClearTeams2_" + $env:USERNAME + "_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".log")
        Start-Transcript -Path $file -Append | Out-Null
        $script:TranscriptStarted = $true
        $script:TranscriptPath    = $file
        return
    } catch {
        Write-Warning "Transcript (ProgramData) fehlgeschlagen: $($_.Exception.Message)"
    }

    try {
        $temp = Join-Path $env:TEMP ("ClearTeams2_" + $env:USERNAME + "_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".log")
        Start-Transcript -Path $temp -Append | Out-Null
        $script:TranscriptStarted = $true
        $script:TranscriptPath    = $temp
    } catch {
        Write-Warning "Transcript (TEMP) fehlgeschlagen: $($_.Exception.Message)"
    }
}

function Stop-SafeTranscript {
    if ($script:TranscriptStarted) {
        try { Stop-Transcript | Out-Null } catch { }
    }
}

# Hilfsfunktionen
function Resolve-FullPath([string]$p) { [IO.Path]::GetFullPath($p).TrimEnd('\') }
function Test-IsUnder([string]$child, [string]$parent) {
    if ([string]::IsNullOrWhiteSpace($child) -or [string]::IsNullOrWhiteSpace($parent)) { return $false }
    $c = Resolve-FullPath $child; $p = Resolve-FullPath $parent
    return ($c.Length -gt $p.Length) -and $c.StartsWith($p, [System.StringComparison]::OrdinalIgnoreCase)
}

# --- Kern: "Safe" Cache-Clear ---
function Clear-TeamsCacheSafe {
    param(
        [Parameter(Mandatory=$true)][string]$MsTeamsLocalPath,  # ...\LocalCache\Microsoft\MSTeams
        [Parameter(Mandatory=$true)][string]$BackgroundsDir,    # ...\Backgrounds
        [Parameter(Mandatory=$false)][string]$WV2ProfilePath,   # ...\EBWebView\WV2Profile_tfw
        [string[]]$KeepDirs = @(),
        [string]$KeepFile = $null
    )

    if (-not (Test-Path -LiteralPath $MsTeamsLocalPath)) {
        Add-Log("Teams LocalCache nicht gefunden: $MsTeamsLocalPath")
        return
    }

    $MsTeamsLocalPath = Resolve-FullPath $MsTeamsLocalPath
    $BackgroundsDir   = Resolve-FullPath $BackgroundsDir

    Add-Log("Bereinige 'safe': $MsTeamsLocalPath")
    if (Test-Path $WV2ProfilePath) {
        Add-Log("Schuetze Persistenz: IndexedDB, Local Storage, Preferences") 
    }

    # 1) Definierte Cache-/Log-Ordner, die sicher geloescht werden koennen
    $DeleteList = @(
        "Logs",
        "PerfLog",
        "EBWebView\WV2Profile_tfw\GPUCache",
        "EBWebView\WV2Profile_tfw\Cache",
        "EBWebView\WV2Profile_tfw\Code Cache",
        "EBWebView\WV2Profile_tfw\Service Worker\CacheStorage",
        "EBWebView\Crashpad"
        # Optional, falls vorhanden:
        # "EBWebView\WV2Profile_tfw\GrShaderCache"
    )

    foreach ($rel in $DeleteList) {
        $p = Join-Path $MsTeamsLocalPath $rel
        if (Test-Path $p) {
            try {
                Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue -Confirm:$false
            } catch { }
        }
    }

    # 2) Nichts außerhalb davon loeschen – insb. NICHT:
    #    - ...\Backgrounds (inkl. Uploads)
    #    - WV2 'IndexedDB', 'Local Storage' (Ordner) und 'Preferences' (Datei)
    #    => deshalb KEIN globales Get-ChildItem -Recurse mehr hier.
    
    # 3) Optional: Leere Ordner unterhalb MsTeamsLocal bereinigen,
    #    aber niemals Backgrounds oder geschuetzte WV2-Dirs/Preferences anfassen.
    try {
        $protected = @()
        if (Test-Path $BackgroundsDir) {
            $protected += (Resolve-FullPath $BackgroundsDir)
        }
        foreach ($d in $KeepDirs) {
            if (Test-Path $d) { $protected += (Resolve-FullPath $d) }
        }

        Get-ChildItem -Path $MsTeamsLocalPath -Recurse -Force -Directory -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending |
            Where-Object {
                $p = Resolve-FullPath $_.FullName
                # Backgrounds / Uploads schuetzen
                if ($protected | Where-Object { ($p -eq $_) -or (Test-IsUnder $p $_) }) { return $false }
                return $true
            } |
            ForEach-Object {
                try {
                    # nur leere Ordner entfernen
                    $children = Get-ChildItem -Force -LiteralPath $_.FullName -ErrorAction SilentlyContinue
                    if (-not $children) {
                        Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue -Confirm:$false
                    }
                } catch { }
            }
    } catch { }
}

# --- Interaktive UI (nur wenn Mode=Interactive & Teams laeuft) ---
function Show-ClearCacheDialog {
    Add-Type -AssemblyName PresentationFramework

    $MessageHeader = "Allgaeu Batterie IT - Teams aufraeumen"
    $MessageText   = "Dieses Programm raeumt Teams automatisch auf und startet Teams neu. Es dauert ca. 1 Minute."

    [XML]$xaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="IntuneWin32 Deployer" 
    Height="200" Width="420"
    WindowStartupLocation="CenterScreen" WindowStyle="None" 
    ShowInTaskbar="False" 
    ResizeMode="NoResize" Background="#FF1B1A19" Foreground="white">
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto" />
            <ColumnDefinition Width="*" />
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="*" />
        </Grid.RowDefinitions>
        <Grid Grid.Column="1" Margin="10">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <TextBlock Name="TextMessageHeader" Text="$MessageHeader" FontSize="20" VerticalAlignment="Top" HorizontalAlignment="Left"/>
            <TextBlock Name="TextMessageBody" Text="$MessageText" Grid.Row="1" VerticalAlignment="Center" HorizontalAlignment="Left" TextWrapping="Wrap"/>
            <StackPanel x:Name="Buttons" Grid.Row="2" Orientation="Horizontal">
                <Button x:Name="ButtonAbort" Content="ABRECHEN" Background="#504c49" Foreground="white" HorizontalAlignment="Left" Margin="10,0,0,0" Height="28" BorderThickness="1" Width="90"/>
                <Button x:Name="ButtonClear" Content="Ok" Background="#46a049" Foreground="white" HorizontalAlignment="Left" Margin="10,0,0,0" Height="28" BorderThickness="0" Width="90"/>
            </StackPanel>
        </Grid>
    </Grid>
</Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $Window = [Windows.Markup.XamlReader]::Load($reader)

    $Window.FindName("ButtonClear").Add_Click({
        try {
            $Window.Close()

            Add-Log "Stoppe Teams-Prozess(e)..."
            Stop-Process -Name $script:ProcessName -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3

            Clear-TeamsCacheSafe -MsTeamsLocalPath $script:MsTeamsLocal `
                                 -BackgroundsDir   $script:BackgroundsPath `
                                 -WV2ProfilePath   $script:WV2Profile `
                                 -KeepDirs         $script:KeepDirs `
                                 -KeepFile         $script:KeepFile

            Add-Log("Starte Teams neu...") 
            Start-Process $script:ProcessName -ErrorAction SilentlyContinue

            Add-Log("Teams aufgeraeumt fuer $env:USERNAME")
            $script:ExitCode = 0
        } catch {
            Add-Log("Fehler beim Clear: $($_.Exception.Message)")
            $script:ExitCode = 2
        }
    })

    $Window.FindName("ButtonAbort").Add_Click({
        $Window.Close()
        Add-Log("Benutzer ($env:USERNAME) hat abgebrochen")
        $script:ExitCode = 1
    })

    $null = $Window.ShowDialog()
}

# ----------------- MAIN -----------------
try {
    Start-SafeTranscript -PreferredPath $LogPath
    if ($script:TranscriptStarted -and $script:TranscriptPath) {
        Add-Log("Transcript gestartet: $($script:TranscriptPath)")
    }

    $teamsProcs = Get-Process -Name $script:ProcessName -ErrorAction SilentlyContinue

    if ($Mode -eq 'Interactive' -and $teamsProcs) {
        Show-ClearCacheDialog
    }
    else {
        if ($teamsProcs) {
            Add-Log("Silent/Auto: Stoppe Teams...")
            Stop-Process -Name $script:ProcessName -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
        }

        Clear-TeamsCacheSafe -MsTeamsLocalPath $script:MsTeamsLocal `
                             -BackgroundsDir   $script:BackgroundsPath `
                             -WV2ProfilePath   $script:WV2Profile `
                             -KeepDirs         $script:KeepDirs `
                             -KeepFile         $script:KeepFile

        Add-Log("Starte Teams...") 
        Start-Process $script:ProcessName -ErrorAction SilentlyContinue

        Add-Log("Teams aufgeraeumt fuer $env:USERNAME")
        $script:ExitCode = 0
    }
}
catch {
    Add-Log("Unerwarteter Fehler: $($_.Exception.Message)")
    $script:ExitCode = 3
}
finally {
    Stop-SafeTranscript
    $Global:Current_Folder = Split-Path $MyInvocation.MyCommand.Path
    $CurrentScript = Split-Path -Leaf $MyInvocation.MyCommand.Path
    Start-Process -WindowStyle Hidden "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$Current_Folder\Notification.ps1`" -Script `"$CurrentScript`" -Logs `"$Log`""

    exit $script:ExitCode
}