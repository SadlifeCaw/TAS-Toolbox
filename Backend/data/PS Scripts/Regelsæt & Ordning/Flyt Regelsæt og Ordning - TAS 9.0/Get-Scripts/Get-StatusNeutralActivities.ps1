#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'

if($regelsæt_id -ne $false){
    Title -Title 'Get-StatusNeuralActivities'

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){
            Write-Host "SQL connection is successufull"

            $query = " select a.AKTIVITET_KODE
                            from AKTIVITET_REGEL_GENEREL arg
                            inner join AKTIVITET a
                            on arg.AKTIVITET_ID = a.AKTIVITET_ID
                                where arg.REGELSAET_ID = (select REGELSAET_ID from REGELSAET where TEKST = '$RegelsætName')"
        
            $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
            Write-Host Query executed
        
            Write-Host Retrieved $result.Count Status neutral activities
            foreach($item in $result){
                Write-Host $item.AKTIVITET_KODE -ForegroundColor Green
            } 

            $result |Export-Csv -Path $path\StatusNeuralActivities.csv -NoTypeInformation -Encoding UTF8
            Write-Host "Output exported in the given path $path" `r`n                
        }

        $connection.Close()
        Write-Host "SQL connection Closed"

    }catch{
        $_
    }
}

