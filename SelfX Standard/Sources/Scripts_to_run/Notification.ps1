param(
    [Parameter(Mandatory = $true)]
    [string]$Script,
    [string]$Logs
)

function Send-NotificationEmail {
    param(
        [string]$Script,
        [string]$Logs,
        [string]$Recipient = "abit@allgaeubatterie.de",
        [string]$Sender = "SelfX@allgaeubatterie.de",
        [string]$SmtpServer = "allgaeubatterie-de.mail.protection.outlook.com",
        [int]$Port = 25
    )

    $username = $env:USERNAME
    $hostname = $env:COMPUTERNAME
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $subject = "SelfX: Skript '$Script' wurde ausgefuehrt"
    $body = @"
Das Skript '$Script' wurde ausgefuehrt.

Benutzer: $username
Hostname: $hostname
Zeitpunkt: $timestamp

--- Logs ---
$Logs
"@

    try {
        Send-MailMessage -To $Recipient -From $Sender -Subject $subject `
                         -Body $body -SmtpServer $SmtpServer -Port $Port
        Write-Host "✅ E-Mail wurde erfolgreich versendet."
    } catch {
        Write-Warning "Fehler beim E-Mail-Versand: $($_.Exception.Message)"
    }
}

Send-NotificationEmail -Script $Script -Logs $Logs