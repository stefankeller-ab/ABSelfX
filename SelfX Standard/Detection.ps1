$PackageName = "SelfX"
$Version = '202511131'

$ProgramVersion_current = Get-Content -Path "$ENV:LOCALAPPDATA\_MEM\$PackageName"

if($ProgramVersion_current -eq $Version){
    Write-Host "Found it!"
}