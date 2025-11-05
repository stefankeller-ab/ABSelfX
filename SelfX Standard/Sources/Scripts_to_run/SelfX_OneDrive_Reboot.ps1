# Logs sammeln
$Log = ""

function Add-Log($text) {
    $global:Log += "$text`r`n"
    Write-Host $text
}

$Get_Current_user = (gwmi win32_computersystem).username
$Get_Current_user_Name = $Get_Current_user.Split("\")[1]
$OneDrive_Kill_Status = $False

$OneDrive_Process_Status = gwmi win32_process | where {$_.Name -eq "onedrive.exe"}
If($OneDrive_Process_Status -ne $null)
	{
		try
			{
				$OneDrive_Process_Status.Terminate() | out-null	
				$OneDrive_Kill_Status = $True
				Add-Log("OneDrive wurde beendet")
			}
		catch
			{
				$OneDrive_Kill_Status = $False
				Add-Log("OneDrive_Kill_Status: $OneDrive_Kill_Status = $False")	
			}
	}
	
Sleep 5

If($OneDrive_Kill_Status -eq $True)
	{
		$User_Profil_Path = "C:\Program Files\Microsoft OneDrive\OneDrive.exe"
		Start-Process -FilePath $User_Profil_Path /background
		Add-Log("OneDrive wurde neugestartet")
	}
			
# Notification aufrufen und Logs übergeben
$Current_Folder = Split-Path $MyInvocation.MyCommand.Path
$CurrentScript = Split-Path -Leaf $MyInvocation.MyCommand.Path
Start-Process -WindowStyle Hidden "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$Current_Folder\Notification.ps1`" -Script `"$CurrentScript`" -Logs `"$Log`""