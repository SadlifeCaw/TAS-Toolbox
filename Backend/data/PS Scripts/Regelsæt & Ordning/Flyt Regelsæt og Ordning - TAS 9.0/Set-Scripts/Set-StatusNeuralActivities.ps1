#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'

if($regelsæt_id -ne $false){

    DoesZipExist #Does data.zip exists
    
    $testPath = DoesFileExist -FileName StatusNeuralActivities.csv

    if($testPath){
        Title -Title 'Set-StatusNeutralActivities'

        $status_neutral_activities = Import-Csv -Path $path/StatusNeuralActivities.csv

        $insert = "" #Insert query

        $codes = @() 
        

        foreach($neu in $status_neutral_activities){
            $ac_code = $neu.AKTIVITET_KODE

            $newId = GetActivityId -ActivityCode $ac_code #New activity ID from PROD

            $exist = IsActivityStatusNeutral -ActivityId $newId
    
            if($exist -eq $false){
                $insert = $insert + "($newId,'$regelsæt_id'), `r`n"    
                $codes += $ac_code 
            }
    
        }
        
        if(!([string]::IsNullOrEmpty($insert))){
            write-host "The INSERT query has been created.`r`n"
            $insert = "INSERT INTO AKTIVITET_REGEL_GENEREL(AKTIVITET_ID,REGELSAET_ID) `r`n" + 'VALUES' + $insert
            $insert = $insert.Substring(0,$insert.Length-4) #remove the last ','

            Invoke-Sqlcmd -Query $insert -ConnectionString $connectionstring -MaxCharLength $maxCharLength

            Write-Host Inserted the following status neutral activities: -ForegroundColor Green
            $codes | ForEach-Object -Process { Write-Host $_ -ForegroundColor Green}

        }else{
            Write-Host No Status Neutral Activities were inserted -ForegroundColor Yellow
        }
    }
}

