#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs and Methods
. "$path\Methods.ps1"

$title    = 'Invoke script in Database'
$question = 'Getting data from Regelsæt name - ' + "'" + $RegelsætName + "'" + ', Ordning - ' + "'" + $ordning + "'" + '. Are you sure you want to proceed with replacing initial ' + "'" + $InitialFra + "'" + ' with ' + "'" + $InitialTil +"'?"
$choices  = '&Yes', '&No'


$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if ($decision -eq 0) {
    
    $date = Get-Date -Format yyyy-MM-dd.HH.mm.ss

    if(!(Test-Path -Path $path\LogFiles)){
        New-Item $path\LogFiles -ItemType Directory  
    }

    Start-Transcript -path $path\LogFiles\logFile-GET.$date.txt -append

    #Execute Get-Status
    . "$path\Get-Scripts\Get-Status"

    #Execute Get-Activities
    . "$path\Get-Scripts\Get-Activities"

    #Execute Get-StatusNeutralActivities
    . "$path\Get-Scripts\Get-StatusNeutralActivities.ps1"

    #Execute Get-ActivitySecurities
    . "$path\Get-Scripts\Get-ActivitySecurities.ps1"

    #Execute Get-MuligStatus
    . "$path\Get-Scripts\Get-MuligStatus.ps1"

    #Execute Get-SchemaSettings
  #  . "$path\Get-Scripts\Get-SchemaSettings.ps1"

    $compress = @{
      Path = "$path\*.csv"
      CompressionLevel = "Fastest"
      DestinationPath = "$path\data.Zip"
    }

    Compress-Archive @compress -Force 

    Get-ChildItem -Path $path -Filter *.csv | foreach {Remove-Item -Path $_.FullName} 

    Stop-Transcript
}else{
    Write-Host "Didn't Execute script."
    break
}





