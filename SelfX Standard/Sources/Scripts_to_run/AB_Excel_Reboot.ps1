# Logs sammeln
$Log = ""

function Add-Log($text) {
    $global:Log += "$text`r`n"
    Write-Host $text
}

$Excel_Process_Status = Get-WmiObject win32_process | Where-Object { $_.Name -like "*excel*" }
Add-Log("Excel_Process_Status: $Excel_Process_Status")

If ($Excel_Process_Status -ne $null) {
    $Excel_Path = $Excel_Process_Status.Path
    try {
        $Excel_Process_Status.Terminate() | Out-Null
        $Kill_Status = $True
    } catch {
        $Kill_Status = $False
    }
}

Start-Sleep -Seconds 5
If ($Kill_Status -eq $True) {
    Start-Process -FilePath $Excel_Path

    $Global:Current_Folder = Split-Path $MyInvocation.MyCommand.Path
    $CurrentScript = Split-Path -Leaf $MyInvocation.MyCommand.Path
    Start-Process -WindowStyle Hidden "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$Current_Folder\Notification.ps1`" -Script `"$CurrentScript`" -Logs `"$Log`""
}