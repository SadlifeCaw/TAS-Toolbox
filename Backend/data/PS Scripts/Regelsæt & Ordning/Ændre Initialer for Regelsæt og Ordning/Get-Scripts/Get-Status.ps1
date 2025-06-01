#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs and Methods
. "$path\Methods.ps1"

Preprocess # Making sure powershell has installed the module 'SqlServer'

if($regelsæt_id -ne $false){
    Title -Title 'Get-Status'
    #Create a connection to sql database and retrieve the Status'
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){
            Write-Host "SQL connection is successufull"

            $query = "select *
                        from STATUS
                        where STATUS IN (select distinct STATUS
                                                from REGELSAET_STATUS
                                                where REGELSAET_ID = $regelsæt_id OR 
	                                                STATUS IN (select STATUS_TIL 
				                                                from AKTIVITET_REGEL 
				                                                where REGELSAET_ID = $regelsæt_id))"
        
            $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
            Write-Host Query executed `r`n
            
            $result | foreach{
                $_.STATUS = $_.STATUS.replace($InitialFra,$InitialTil)
                $_.TEKST = $_.TEKST.replace($InitialFra,$InitialTil)
            }

            Write-Host Retrieved Status
            foreach($item in $result){
                Write-Host $item.STATUS - $item.TEKST -ForegroundColor Green
            } 

            $result |Export-Csv -Path $path\Status.csv -NoTypeInformation -Encoding UTF8
            Write-Host "Output exported in the given path $path" `r`n

            Write-Host Retrieved $result.Count Status"'"
                
        }

        $connection.Close()
        Write-Host "SQL connection Closed"

    }catch{
        $_
    }
}





