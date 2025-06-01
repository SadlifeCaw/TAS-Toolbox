#Author : Nevethan Alagaratanm

#Getting all the methods and database connection information
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1"
. "$path\Methods.ps1"


#Create a connection to sql database and retrieve the FrontSystem (Schema)
try{
    
    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

    $connection.Open();

    if($connection.State -eq "Open"){
        Write-Host "SQL connection is successufull"

        $query = "select f.TEKST AS SKEMA_NAVN, s.USER_NAME, s.STATUS
                    from SECURITY_INFO s
                    left join FORSYSTEM f
                    on s.CONTROL = CONVERT(varchar(4),f.FORSYSTEM_ID)
                    where WINDOW = 'SagMain' AND TEKST IS NOT NULL AND f.FORSYSTEM_ID IN($frontSystemIds)"

        $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
        
        $result |Export-Csv -Path $path\TemplateSecurity.csv -NoTypeInformation -Encoding UTF8
        Write-Host "Output exported in the given path $path" `r`n -ForegroundColor Green

        Write-Host Retrieved $result.Count Templates securities. They are the following: -ForegroundColor Green
        $result | ForEach-Object -Process {Write-Host $_.SKEMA_NAVN - $_.USER_NAME -ForegroundColor Green}
            
        Write-Host "Output Template(s) in the given path $path"         
    }

    $connection.Close()
    Write-Host "SQL connection Closed"

}catch{
    $_
}

