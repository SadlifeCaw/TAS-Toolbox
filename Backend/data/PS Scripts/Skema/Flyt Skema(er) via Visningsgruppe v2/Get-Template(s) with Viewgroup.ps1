#Author : Nevethan Alagaratanm

#Getting all the methods and database connection information
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1"
. "$path\Methods.ps1"


Preprocess # Making sure powershell has installed the module 'SqlServer'

#Create a connection to sql database 
try{
    
    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

    $connection.Open();

    if($connection.State -eq "Open"){
        Write-Host "SQL connection is successufull"
        
        if($ViewGroup.Count -gt 1){
            $ViewGroup | ForEach-Object{
                return $_ = "'$_'"
            }

            $ViewGroup = $ViewGroup -join ','
        } else {
            $ViewGroup = "'$ViewGroup'"
        }

        Write-Output $ViewGroup
        
        $query = "select df.FrontSystemTemplateXml, f.TEKST, v.Title
                        from DynamicFrontSystemTemplate df
                        left join FORSYSTEM f
                        on df.FrontSystemId = f.FORSYSTEM_ID
                        inner join ViewGroup v
                        on v.Id = df.ViewGroupId
                        where v.Title IN($ViewGroup)"
    
        $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength

        Write-Host Replacing Template Reference Id with their Names 
        $result | ForEach {$_.FrontSystemTemplateXml = ReplaceTemplateReferenceIdWithName($_.FrontSystemTemplateXml)}

        Write-Host Replacing the Escape Characters
        $result | ForEach {$_.FrontSystemTemplateXml = Replace-InvalidFormat($_.FrontSystemTemplateXml)}

        Write-Host Replaceing Template Reference Id with Name - UVG
        $result | Foreach {$_.FrontSystemTemplateXml = ReplaceTemplateReferenceNameUVG -SchemaTemplate $_.FrontSystemTemplateXml}
        
        $result |Export-Csv -Path $path\Templates_ViewGroup.csv -NoTypeInformation -Encoding UTF8
        Write-Host "Output exported in the given path $path" `r`n -ForegroundColor Green

        Write-Host Retrieved $result.Count Templates. They are the following: -ForegroundColor Green
        $result | ForEach-Object -Process {Write-Host $_.TEKST -ForegroundColor Green}
    
    }

    $connection.Close()
    Write-Host "SQL connection Closed"

}catch{
    $_
}