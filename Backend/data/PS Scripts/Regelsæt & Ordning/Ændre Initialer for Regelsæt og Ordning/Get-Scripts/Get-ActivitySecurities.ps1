#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs and Methods
. "$path\Methods.ps1"

Preprocess # Making sure powershell has installed the module 'SqlServer'

if($regelsæt_id -ne $false){
    Title -Title 'Get-ActivitySecurities'
    #Create a connection to sql database and retrieve the data
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){
            Write-Host "SQL connection is successufull"

            $query = "select AKTIVITET.AKTIVITET_KODE, AKTIVITET_SECURITY.NAME,AKTIVITET_SECURITY.STATUS,AKTIVITET_SECURITY.synlig
                            from AKTIVITET_SECURITY AKTIVITET_SECURITY 
                            inner join AKTIVITET AKTIVITET
	                            on AKTIVITET_SECURITY.AKTIVITET_ID = AKTIVITET.AKTIVITET_ID
                                where AKTIVITET.AKTIVITET_ID IN 
			                                    (select AKTIVITET_ID 
			                                    from AKTIVITET 
			                                    where AKTIVITET_KODE IN(select distinct a.AKTIVITET_KODE
	                                                from AKTIVITET_REGEL ar
	                                                inner join AKTIVITET a
	                                                on ar.AKTIVITET_ID = a.AKTIVITET_ID
	                                                where ar.REGELSAET_ID = $regelsæt_id
	                                                UNION
	                                                select distinct a.AKTIVITET_KODE
	                                                from AKTIVITET_REGEL_GENEREL arg
	                                                inner join AKTIVITET a
	                                                on arg.AKTIVITET_ID = a.AKTIVITET_ID
	                                                where REGELSAET_ID = $regelsæt_id))"

            $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength  
            Write-Host Query executed
            
            $result | foreach {
                $_.AKTIVITET_KODE = $_.AKTIVITET_KODE.replace($InitialFra,$InitialTil)
            }
            
            $result | Export-Csv -Path $path/ActivitiesSecurityPermissions.csv -NoTypeInformation
            Write-Host "Output Template in the given path $path" `r`n
            
            Write-Host Retrieved Security permission
            foreach($item in $result){
                Write-Host $item.AKTIVITET_KODE - $item.NAME -ForegroundColor Green
            }

            Write-Host $result.Count Security Permissions -ForegroundColor Green
        }
        

        $connection.Close()
        Write-Host "SQL connection Closed"

    }catch{
        $_ 
    }

}