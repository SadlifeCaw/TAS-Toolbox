#Author : Nevethan Alagaratnam

$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1"
. "$path\Methods.ps1"

$testPath = DoesFileExist -FileName Templates.csv

if($testPath){
    
    $template_csv = Import-Csv -Path $path\Templates.csv.

    foreach($schema in $template_csv){
        $name = $schema.TEKST
       
        $DoesSchemaExist = DoesSchemaExist -SchemaName $name

        if($DoesSchemaExist){

            $templateId = GetSchemaID -SchemaName $name
            
            GetBackupTemplate -SchemaId $templateId

            $xmlTemplate = GetNewTemplateReferences($schema.FrontSystemTemplateXml)
            $xmlTemplate = ReplaceTemplateReferenceIdUVG -SchemaTemplate $xmlTemplate            
            $xmlTemplate = Format-XML($xmlTemplate)
		    $xmlTemplate = Replace-EscapeCharacters -SchemaTemplate $xmlTemplate
                
            $query = "UPDATE DynamicFrontSystemTemplate
                        SET FrontSystemTemplateXml = '$xmlTemplate'
                        WHERE FrontSystemId = $templateId"
            
            try{
                $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
                $connection.Open();

                if($connection.State -eq "Open"){
                    Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
                    Write-Host Uploaded new template - $name"($templateId)" -ForegroundColor Green
                }else{
                    Write-Error couldnt create connection to sql 
                }
            }catch{
                Write-Error $_
                Write-Error $name
            }            
        }

    }

}else{
    Write-Host Couldnt find document "'Templates.csv'" -ForegroundColor Yellow
}



