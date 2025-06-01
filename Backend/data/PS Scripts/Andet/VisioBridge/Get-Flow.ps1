# Import methods from methods.ps1
. "$PSScriptRoot\Methods.ps1"
. "$PSScriptRoot\Config.ps1"

$results = Get-Status -visioFilePath $FilePath
$results | ForEach-Object { Write-Host $_ }
