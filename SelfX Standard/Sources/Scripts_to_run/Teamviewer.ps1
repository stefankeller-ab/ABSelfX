# Stoppt QuickSupport und TeamViewer, dann startet QS neu
$procNames = @('TeamViewerQS','TeamViewer')

foreach ($name in $procNames) {
    $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($procs) {
        Write-Host "Beende $name ..."
        $procs | Stop-Process -Force
    }
}

Start-Sleep -Seconds 2

# Starte Teamviewer
& "$PSScriptRoot\TeamViewerQS_x64.exe"