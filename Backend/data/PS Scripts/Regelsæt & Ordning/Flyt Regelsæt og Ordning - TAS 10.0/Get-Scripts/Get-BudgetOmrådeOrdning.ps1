#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'

if($ordning_id -ne $false){
    Title -Title 'Get-BudgetOmrådeOrdning'
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){cls
            Write-Host "SQL connection is successufull"

            ####################################
            ### Getting the Schema settings ####
            ####################################
        
            $query = "select BUDGET_OMRAADE_ID, ORDNING, TEKST, BUDGET_OMRAADE, BUDGET_OMRAADE_LBN
                        from BUDGET_OMRAADE
                        where ORDNING = '$ordning'
                        order by BUDGET_OMRAADE_LBN"
        
            
            $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
            Write-Host Query executed
        
            Write-Host `r`n Retrieved $result.Count Budget Områder: 
            ForEach($item in $result){
                Write-Host $item.TEKST -ForegroundColor Green
            } 

            $result | Export-Csv -Path $path\BudgetOmraadeOrdning.csv -NoTypeInformation -Encoding UTF8
            Write-Host "Output exported in the given path $path" `r`n

        }
    }catch{
        $_
    }
}