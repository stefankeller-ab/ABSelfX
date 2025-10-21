$Excel_Process_Status = Get-WmiObject win32_process | Where-Object { $_.Name -like "*excel*" }

If ($Excel_Process_Status -ne $null) {
    $Excel_Path = $Excel_Process_Status.Path
    try {
        $Excel_Process_Status.Terminate() | Out-Null
        $Kill_Status = $True
    } catch {
        $Kill_Status = $False
    }
}

Start-Sleep -Seconds 10
If ($Kill_Status -eq $True) {
    Start-Process -FilePath $Excel_Path
}

# Optional: Benachrichtigungsskript starten (wenn vorhanden)
# $Global:Current_Folder = Split-Path $MyInvocation.MyCommand.Path
# $Args = "$Current_Folder\AutoDepannage_Notification.ps1", "-Category 'Excel'"
# Start-Process -WindowStyle Hidden "powershell.exe" -ArgumentList $Args
