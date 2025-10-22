# Logs sammeln
$Log = ""

function Add-Log($text) {
    $global:Log += "$text`r`n"
    Write-Host $text
}

$Get_Edge_Process = Get-WmiObject win32_process | Where-Object { $_.Name -like "*msedge*" }
If ($Get_Edge_Process -ne $null) {
    $Get_Edge_Process.Terminate() | Out-Null
}

$user = $env:USERNAME
$edgeAppData = "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\Default"
If (Test-Path $edgeAppData) {
    $possibleCachePaths = @('Cache','Cache2\entries\','Cookies','History','Top Sites','VisitedLinks','Web Data','Media Cache','Cookies-Journal','EdgeDWriteFontCache')
    ForEach ($cachePath in $possibleCachePaths) {
        Remove-Item "$edgeAppData\$cachePath" -Force -Recurse -ErrorAction SilentlyContinue
        Add-Log("$cachePath")
    }

    $Global:Current_Folder = Split-Path $MyInvocation.MyCommand.Path
    $CurrentScript = Split-Path -Leaf $MyInvocation.MyCommand.Path
    Start-Process -WindowStyle Hidden "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$Current_Folder\Notification.ps1`" -Script `"$CurrentScript`" -Logs `"$Log`""
}