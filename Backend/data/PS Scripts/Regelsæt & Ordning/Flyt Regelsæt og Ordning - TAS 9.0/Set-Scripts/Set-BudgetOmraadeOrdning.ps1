#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'


if($ordning_id -ne $false){

    DoesZipExist #Does data.zip exists

    $testPath = DoesFileExist -FileName BudgetOmraadeOrdning.csv

    if($testPath){
        
        Title -Title 'Set-BudgetOmraadeOrdning'

        $Budget_csv = Import-Csv -Path $path\BudgetOmraadeOrdning.csv

        foreach($b in $Budget_csv){
            
            $budget_omraade = $b.BUDGET_OMRAADE
            
            $doesBudgetOmraadeExist = DoesBudgetOmraadeExist -Budget $budget_omraade

            if(!$doesBudgetOmraadeExist){
                
                $getLastestLbnr = GetLastestLbnrBudgetOmraade
                $getLastestLbnr++ #Increment from lastest lbnr

                $tekst = $b.TEKST
                
                $bo_id = $ordning + $budget_omraade + $getLastestLbnr

                $query = "INSERT INTO BUDGET_OMRAADE(BUDGET_OMRAADE_ID, ORDNING, TEKST, BUDGET_OMRAADE, BUDGET_OMRAADE_LBN)
                            VALUES('$bo_id','$ordning','$tekst','$budget_omraade','$bo_id')"

                try{
                    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
                    $connection.Open();
        
                    if($connection.State -eq "Open"){
                        
                        Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
                        Write-Host Query Executed
                        
                        Write-Host Created BudgetOmråde: 
                        Write-Host Budget Omrade : $budget_omraade -ForegroundColor Green
                        Write-Host Tekst : $tekst -ForegroundColor Green
                        Write-Host Ordning : $ordning -ForegroundColor Green
                    }
                    
                }catch{
                    Write-Error $_
                }

            }
        }
    }
}