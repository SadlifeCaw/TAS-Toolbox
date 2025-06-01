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

        $query = "select d.FrontSystemId AS 'FrontSystemId',f.TEKST AS 'TEKST', d.FrontSystemTemplateXml as 'FrontSystemTemplateXml'
                    from DynamicFrontSystemTemplate d
                    inner join FORSYSTEM f
                    on d.FrontSystemId = f.FORSYSTEM_ID
                    where d.FrontSystemId IN($frontSystemIds)"

        $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
            
        Write-Host Replacing Template Reference Id with their Names 
        $result | ForEach {$_.FrontSystemTemplateXml = ReplaceTemplateReferenceIdWithName($_.FrontSystemTemplateXml)}
        
        Write-Host "Replacing the Escape Characters"
        $result | ForEach {$_.FrontSystemTemplateXml = Replace-EscapeCharacters($_.FrontSystemTemplateXml)}       

        Write-Host Replaceing Template Reference Id with Name - UVG
        $result | Foreach {$_.FrontSystemTemplateXml = ReplaceTemplateReferenceNameUVG -SchemaTemplate $_.FrontSystemTemplateXml}

        $result | Export-Csv -Path $path\Templates.csv -NoTypeInformation -Encoding UTF8
        Write-Host "Output exported in the given path $path" `r`n -ForegroundColor Green

        Write-Host Retrieved $result.Count Templates. They are the following: -ForegroundColor Green
        $result | ForEach-Object -Process {Write-Host $_.TEKST - $_.FrontSystemId -ForegroundColor Green}
            
        Write-Host "Output Template(s) in the given path $path"         
    }

    $connection.Close()
    Write-Host "SQL connection Closed"

}catch{
    $_
}



