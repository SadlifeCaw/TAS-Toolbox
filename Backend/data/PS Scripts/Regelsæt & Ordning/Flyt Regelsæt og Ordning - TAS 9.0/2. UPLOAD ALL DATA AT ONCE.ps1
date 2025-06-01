#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

$title    = 'Invoke script in Database'
$question = 'Uploading data to Regelsæt name - ' + "'" + $RegelsætName + "'" + ', Ordning - ' + "'" + $ordning + "'" + '. Are you sure you want to proceed?'
$choices  = '&Yes', '&No'

$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if ($decision -eq 0) {
    
    $date = Get-Date -Format yyyy-MM-dd.HH.mm.ss

    if(!(Test-Path -Path $path\LogFiles)){
        New-Item $path\LogFiles -ItemType Directory  
    }
    
    Start-Transcript -path $path\LogFiles\logFile-SET.$date.txt -append
    

    ###################################
      ############ BACKUP #############
    ###################################
  
   # . "$path\GetBackUp.ps1"


    ##### Uploading data #####
    Title -Title 'UPLOADING DATA'    
    

    ####################################
    ############# REGELSÆT #############
    ####################################


    #Execute Set-Status
   # . "$path\Set-Scripts\Set-Status.ps1"
    
    #Execute Set-Activities
   # . "$path\Set-Scripts\Set-Activities.ps1"
    
    #Execute Set-StatusNeutralActivities
   # . "$path\Set-Scripts\Set-StatusNeuralActivities.ps1"

    #Execute Set-ActivitySecurities
   # . "$path\Set-Scripts\Set-ActivitySecurities.ps1"

    #Execute Set-MuligStatus
   # . "$path\Set-Scripts\Set-MuligStatus.ps1"



    ###################################
    ############# ORDNING #############
    ###################################
    
    #Execute Set-SchemaSettings
    . "$path\Set-Scripts\Set-SchemaSettings.ps1"

    #Execute Set-Sagsbemyndiget
 #   . "$path\Set-Scripts\Set-Sagsbemyndiget.ps1"

    #Execute Set-KontorOrdning
  #  . "$path\Set-Scripts\Set-KontorOrdning.ps1"

    #Execute Set-Omkostningsart
  #  . "$path\Set-Scripts\Set-Omkostningsart.ps1"
    
    #Execute Set-EmneOrd
   # . "$path\Set-Scripts\Set-EmneOrd.ps1" 

    #Execute Set-RapportGruppe
    #. "$path\Set-Scripts\Set-RapportGruppe.ps1" 

    #Execute Set-StatistikKode
  #  . "$path\Set-Scripts\Set-StatistikKode.ps1" 

    #Execute Set-BudgetOmraadeOrdning
    #. "$path\Set-BudgetOmraadeOrdning.ps1"  #Ikke Testet endnu


    #Deleting the unnecessary backup csv files.
    Get-ChildItem -Path $path -Filter *.csv | foreach {Remove-Item -Path $_.FullName}

    Stop-Transcript

    Write-Host DATA UPLOAD COMPLETED -ForegroundColor Green
    Write-Host ORDNING : $ordning
    Write-Host REGELSÆT : $RegelsætName
    Write-Host
    
}else{
    Write-Host "Didn't Execute script."
    break
}

