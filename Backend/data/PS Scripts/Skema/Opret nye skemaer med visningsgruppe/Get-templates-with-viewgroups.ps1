#Author : Nevethan Alagaratanm

#Getting all the methods and database connection information
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1"
. "$path\Methods.ps1"

Preprocess # Making sure powershell has installed the module 'SqlServer'

#Create a connection to sql database and retrieve the FrontSystem (Schema)
try{
    
    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

    $connection.Open();

    if($connection.State -eq "Open"){
        Write-Host "SQL connection is successufull"

        $query = "select f.tekst AS SKEMA_NAVN, v.Title AS VISNINGSGRUPPE_NAVN
                    from DynamicFrontSystemTemplate d
                    left join ViewGroup v
                    on d.ViewGroupId = v.Id 
                    left join FORSYSTEM f
                    on d.FrontSystemId = f.FORSYSTEM_ID 
                    where f.FORSYSTEM_ID IS NOT NULL AND f.FORSYSTEM_ID IN ($frontSystemIds)"

        $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
            
        $result |Export-Csv -Path $path\Templates_Names.csv -NoTypeInformation -Encoding UTF8
        Write-Host "Output exported in the given path $path" `r`n -ForegroundColor Green

        Write-Host Retrieved $result.Count Templates. They are the following: -ForegroundColor Green
        $result | ForEach-Object -Process {Write-Host $_.SKEMA_NAVN - $_.VISNINGSGRUPPE_NAVN -ForegroundColor Green}
            
        Write-Host "Output Template(s) in the given path $path"         
    }

    $connection.Close()
    Write-Host "SQL connection Closed"

}catch{
    $_
}

$compress = @{
  Path = "$path\*.xml"
  CompressionLevel = "Fastest"
  DestinationPath = "$path\templates.Zip"
}
Compress-Archive @compress -Force 

