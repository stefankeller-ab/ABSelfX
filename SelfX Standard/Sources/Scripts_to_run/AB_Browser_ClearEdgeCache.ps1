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
    }
}