param(
    [Parameter(Mandatory = $true)]
    [string]$Script,
    [string]$Logs,
    [string]$Recipient = "abit@allgaeubatterie.de"
)

# Microsoft Graph Modul laden
Import-Module Microsoft.Graph -ErrorAction Stop

# Mit integriertem Token anmelden (funktioniert auf Entra-ID-joined Geräten)
Connect-MgGraph -Identity

# Benutzer- und Systeminfos
$username  = $env:USERNAME
$hostname  = $env:COMPUTERNAME
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Betreff und Body wie bisher
$subject = "SelfX: Skript '$Script' wurde ausgefuehrt"
$body = @"
Das Skript '$Script' wurde ausgefuehrt.

Benutzer: $username
Hostname: $hostname
Zeitpunkt: $timestamp

--- Logs ---
$Logs
"@

# E-Mail-Parameter für Graph
$params = @{
    Message = @{
        Subject = $subject
        Body = @{
            ContentType = "Text"
            Content = $body
        }
        ToRecipients = @(
            @{
                EmailAddress = @{
                    Address = $Recipient
                }
            }
        )
    }
    SaveToSentItems = "true"
}

try {
    Send-MgUserMail -UserId $username -BodyParameter $params
    Write-Host "E-Mail wurde erfolgreich über Microsoft Graph versendet."
} catch {
    Write-Warning "Fehler beim E-Mail-Versand über Graph: $($_.Exception.Message)"
}