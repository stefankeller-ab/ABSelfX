# Logs sammeln
$Log = ""

function Add-Log($text) {
    $global:Log += "$text`r`n"
    Write-Host $text
}

Clear-RecycleBin -confirm:$false -force
Add-Log("Papierkorb geloescht")
Get-ChildItem "$env:temp\*" -recurse | remove-item -recurse -force -ea silentlycontinue
Add-Log("$env:tmp geloescht")
Add-Log("Neustart in 5s")

# Notification aufrufen und Logs übergeben
$Current_Folder = Split-Path $MyInvocation.MyCommand.Path
$CurrentScript = Split-Path -Leaf $MyInvocation.MyCommand.Path
Start-Process -WindowStyle Hidden "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$Current_Folder\Notification.ps1`" -Script `"$CurrentScript`" -Logs `"$Log`""

Start-Sleep -Seconds 5
Restart-Computer -Force