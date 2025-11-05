# Logs sammeln
$Log = ""

function Add-Log($text) {
    $global:Log += "$text`r`n"
    Write-Host $text
}

$Word_Process_Status = gwmi win32_process | where {$_.Name -like "*word*"}
If($Word_Process_Status -ne $null)	
	{
		$Word_Path = $Word_Process_Status.Path 
		try
			{
				$Word_Process_Status.Terminate() | out-null	
				$Kill_Status = $True
				Add-Log("Word wurde beendet")
			}
		catch
			{
				$Kill_Status = $False			
			}		
	}
	
Sleep 5

If($Kill_Status -eq $True)
	{
		Start-Process -FilePath $Word_Path
		Add-Log("Word wurde neugestartet") 	
	}	

# Notification aufrufen und Logs übergeben
$Current_Folder = Split-Path $MyInvocation.MyCommand.Path
$CurrentScript = Split-Path -Leaf $MyInvocation.MyCommand.Path
Start-Process -WindowStyle Hidden "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$Current_Folder\Notification.ps1`" -Script `"$CurrentScript`" -Logs `"$Log`""	