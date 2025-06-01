#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods


$date = Get-Date -Format yyyy-MM-dd.HH.mm.ss

if(!(Test-Path -Path $path\backups)){
    New-Item $path\backups -ItemType Directory
}

Title -Title 'CREATING A BACKUP'  
    
#region Backup
#Execute Get-Status
. "$path\Get-Scripts\Get-Status.ps1"

#Execute Get-Activities
. "$path\Get-Scripts\Get-Activities.ps1"

#Execute Get-StatusNeutralActivities
. "$path\Get-Scripts\Get-StatusNeutralActivities.ps1"

#Execute Get-ActivitySecurities
. "$path\Get-Scripts\Get-ActivitySecurities.ps1"

#Execute Get-MuligStatus
. "$path\Get-Scripts\Get-MuligStatus.ps1"

#Execute Get-SchemaSettings
. "$path\Get-Scripts\Get-SchemaSettings.ps1"

#Execute Get-Sagsbemyndiget
. "$path\Get-Scripts\Get-Sagsbemyndiget.ps1"

#Execute Get-Sagsbemyndiget
. "$path\Get-Scripts\Get-KontorOrdning.ps1"

#Execute Get-Sagsbemyndiget
. "$path\Get-Scripts\Get-Omkostningsart.ps1"

#Execute Get-Sagsbemyndiget
. "$path\Get-Scripts\Get-EmneOrd.ps1" 

#Execute Get-Sagsbemyndiget
. "$path\Get-Scripts\Get-RapportGruppe.ps1"

#Execute Get-Sagsbemyndiget
. "$path\Get-Scripts\Get-StatistikKode.ps1"

#Execute Get-BudgetOmraadeOrdning
. "$path\Get-BudgetOmraadeOrdning.ps1"

$backup = @{
    Path = "$path\*.csv"
    CompressionLevel = "Fastest"
    DestinationPath = "$path\backups\backup_$ordning" + "_$RegelsætName"+ ".$date.zip"
}
Compress-Archive @backup -Force    
    
#Deleting the unnecessary backup csv files.
Get-ChildItem -Path $path -Filter *.csv | foreach {Remove-Item -Path $_.FullName} 