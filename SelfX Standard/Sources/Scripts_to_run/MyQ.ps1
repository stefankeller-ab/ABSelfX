#DIG-317 MyQ Neustarten wenn man nicht drucken kann
#Start-Sleep -Seconds 5
# MyQ Agent beenden
taskkill /IM DesktopClient.Agent.Win.exe /F

Start-Sleep -Seconds 2

# MyQ Agent wieder starten (Standardpfad)
Start-Process `
  -FilePath "C:\Program Files\MyQ\Desktop Client\Agent\DesktopClient.Agent.Win.exe" `
  -WorkingDirectory "C:\Program Files\MyQ\Desktop Client\Agent"
