#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'

if($ordning_id -ne $false){
    Title -Title 'Get-StatistikKode'
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){cls
            Write-Host "SQL connection is successufull"

            ####################################
            ### Getting the Schema settings ####
            ####################################
        
            $query = "select STATISTIK_KODE, SORT
                        from ORDNING_STATISTIK
                        where ORDNING = '$ordning'"
        
            
            $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
            Write-Host Query executed
        
            Write-Host `r`n Retrieved $result.Count Statistik codes: 
            ForEach($item in $result){
                Write-Host $item.STATISTIK_KODE -ForegroundColor Green
            } 

            $result | Export-Csv -Path $path\StatistikKode.csv -NoTypeInformation -Encoding UTF8
            Write-Host "Output exported in the given path $path" `r`n

        }
    }catch{
        $_
    }
}