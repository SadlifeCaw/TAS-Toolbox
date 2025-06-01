#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'


if($ordning_id -ne $false){

    DoesZipExist #Does data.zip exists

    $testPath = DoesFileExist -FileName Sagsbemyndiget.csv

    if($testPath){
        
        Title -Title 'Set-Sagsbemyndiget'

        $Sagsbemyndiget_csv = Import-Csv -Path $path\Sagsbemyndiget.csv

        foreach($sb in $Sagsbemyndiget_csv){
            
            $initial = $sb.INITIALER
            $budget_id = $sb.BUDGET_OMRAADE_ID
            $max = isNull_int($sb.MAX_BELOEB)
            $ramme1 = isNull_int($sb.RAMME1_MAX_BELOEB)
            $ramme2 = isNull_int($sb.RAMME2_MAX_BELOEB)

            $doesBudgetExist = DoesBudgetExist -ID $budget_id
           
            if($doesBudgetExist){
                
                $doesInitialExist = DoesInitialExist -Initial $initial

                if($doesInitialExist){
                    
                    $doesSagsbemyndigetSettingExist = DoesSagsbemyndigetSettingExist -Initial $initial -BudgetOmraade $budget_id -Max $max -ramme1 $ramme1 -ramme2 $ramme2

                    if(!$doesSagsbemyndigetSettingExist){
                        $query = "INSERT INTO ORDNING_BEMYNDIGET(ORDNING, INITIALER, BUDGET_OMRAADE_ID, MAX_BELOEB, RAMME1_MAX_BELOEB, RAMME2_MAX_BELOEB) `r`n VALUES('$ordning', '$initial', '$budget_id', $max, $ramme1, $ramme2)"

                        try{
                            $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
                            $connection.Open();
        
                            if($connection.State -eq "Open"){
                                #Write-Host $query
                                Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
                                Write-Host Query Executed
                        
                                Write-Host Created Sagsbemyndiget: 
                                Write-Host Ordning : $ordning -ForegroundColor Green
                                Write-Host Initial : $initial -ForegroundColor Green
                                Write-Host Budget Område : $budget_id -ForegroundColor Green
                            }
                        }catch{
                            Write-Error $_
                        }
                    }else{
                        Write-Host Sagsbemyndiget with initial : $initial already exists -ForegroundColor Yellow
                    }
                }                    
            }
        }
    }
}