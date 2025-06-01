#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'

if($regelsæt_id -ne $false){
    Title -Title 'Get-MuligStatus'
    #Create a connection to sql database and retrieve data
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){
            Write-Host "SQL connection is successufull"

            ##################################
            ######### STATUS' Alone ##########
            ##################################

            $query = "Select STATUS, STATUS_TYPE, BUDGETBESKYT, UDBT_TILBAGEHOLDT_TILLADT
                            from REGELSAET_STATUS
                            where REGELSAET_ID = (select REGELSAET_ID 
							                            from REGELSAET
							                            where TEKST = '$RegelsætName')"
                            
            $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
            Write-Host Query executed
        
            Write-Host Retrieved Status
            foreach($i in $result){
                Write-Host $i.STATUS -ForegroundColor Green
            } 

            $result | Export-Csv $path/MuligStatus.csv -NoTypeInformation -Encoding UTF8
            Write-Host "Output exported in the given path $path" `r`n  
        
            Write-Host $result.Count Status"'" -ForegroundColor Green                 
        
            ##################################
            ### Activities for each status ###
            ##################################
        
            $query_activity_regel = "Select a.AKTIVITET_KODE, ar.STATUS_FRA, ar.STATUS_TIL, a2.AKTIVITET_KODE AS 'AKTIVITET_FORTRYD_ID'
                                        from AKTIVITET_REGEL ar
                                        inner join AKTIVITET a
                                        on a.AKTIVITET_ID = ar.AKTIVITET_ID
                                        left join AKTIVITET a2
                                        on ar.AKTIVITET_FORTRYD_ID = a2.AKTIVITET_ID OR (ar.AKTIVITET_FORTRYD_ID IS NULL AND a2.AKTIVITET_ID = ar.AKTIVITET_FORTRYD_ID)
                                        where ar.REGELSAET_ID = (Select REGELSAET_ID 
	                                        from REGELSAET 
	                                        where TEKST = '$RegelsætName')"
        
            $activities_regel = Invoke-Sqlcmd -Query $query_activity_regel -ConnectionString $connectionstring -MaxCharLength $maxCharLength
            Write-Host Query executed
                
 	    foreach($i in $activities_regel){
                Write-Host $i.AKTIVITET_KODE - $i.STATUS_FRA - $i.STATUS_TIL -ForegroundColor Green
            } 

            $activities_regel | Export-Csv $path/MuligStatusActivities.csv -NoTypeInformation -Encoding UTF8

            Write-Host "Output exported in the given path $path" `r`n     
            Write-Host $activities_regel.Count Mulig Statis Activities -ForegroundColor Green
        }

        $connection.Close()
        Write-Host "SQL connection Closed"

    }catch{
        $_
    }
}