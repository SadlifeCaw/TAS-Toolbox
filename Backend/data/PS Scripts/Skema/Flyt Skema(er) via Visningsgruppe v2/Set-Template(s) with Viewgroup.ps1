#Author : Nevethan Alagaratnam

$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1"
. "$path\Methods.ps1"

$testPath = DoesFileExist -FileName Templates_ViewGroup.csv

######################################################################
            ##### Create the Templates #####
######################################################################
if($testPath){

    $template_csv = Import-Csv -Path $path\Templates_ViewGroup.csv.
    
    #$SchemaNames = @()
    #$template_csv | ForEach {$SchemaNames += $_.TEKST}

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        $connection.Open();

        if($connection.State -eq "Open"){        
            foreach($Schema in $template_csv){
                #If the viewgroup already exists, it will be retrieve or a viewgroup will be created
                $ViewGroupId = GetViewGroupId -ViewGroup $Schema.Title

                $DoesSchemaExist = DoesSchemaExist -SchemaName $Schema.TEKST
        
                if(!$DoesSchemaExist){
                    $Id = GetLastId #Getting the lastest ids for schema and OBJEKT
    
                    $NewSchemaId = $Id + 1

                    $Objekt_id = GetLastObjectId
                    $Objekt_id = $Objekt_id + 1
                    $Objekt = 'DynamicFrontSystemObject' + $Objekt_id

                    $SchemaGuidId = New-Guid
                    $SchemaName = $Schema.TEKST

                    $template = '<TemplateDynamicFrontSystem xmlns="http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
                                      <TemplateTabs />
                                      <Templates />
                                    </TemplateDynamicFrontSystem>'

                    $query = "INSERT INTO OBJEKT(OBJEKT_ID,OBJEKT,TEKST,OBJEKTTYPE_ID,AKTIV,COLUMNS,OKO_KONSEKVENS)
                                VALUES($Objekt_id,'$Objekt','DynamicFrontSystemObject created by frontsystem editor',5,'J',NULL,0)

                                INSERT INTO FORSYSTEM(FORSYSTEM_ID, OBJEKT,TABEL,TEKST,OVERSKRIFT,TABEL_SLET,GENAABEN,FORSYSTEM_OBJEKT,SORTERING,BESKRIVELSE)
                                VALUES($NewSchemaId,'$Objekt','dbo.SAG_FORSYSTEM','$SchemaName',NULL,NULL,NULL,NULL,NULL,NULL)

                                INSERT INTO DynamicFrontSystemTemplate(Id, FrontSystemId, ViewGroupId, FrontSystemTemplateXml,Title)
                                VALUES('$SchemaGuidId', $NewSchemaId, '$ViewGroupId', '$template', NULL)
                                
                                INSERT INTO SECURITY_TEMPLATE(APPLICATION,WINDOW,CONTROL,OBJECT_TYPE,DESCRIPTION)
                                VALUES('TAS','SagMain',$NewSchemaId, 'DynamicFrontSystem','Skema(" + $NewSchemaId + ")')"

                    
                    Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
                    Write-Host Created Schema "'$SchemaName'($NewSchemaId)" -ForegroundColor Green
                    
                }
            }
        }
    }catch{
        Write-Error $_
    }
}


######################################################################
            ##### Transfer all the templates #####
######################################################################

if($testPath){
    $template_csv = Import-Csv -Path $path\Templates_ViewGroup.csv.

    #If the viewgroup already exists, it will be retrieve or the new Guid will be created
    try{               

        foreach($el in $template_csv){
            $name = $el.TEKST
                        
            $id = GetSchemaID -SchemaName $name
            
            GetBackupTemplate -SchemaId $id
                                
            $template = GetNewTemplateReferences($el.FrontSystemTemplateXml)
            $template = ReplaceTemplateReferenceIdUVG -SchemaTemplate $template
            $xmlTemplate = ReplaceXmlTagContent -xmlContent $xmlTemplate -searchPattern '<ParentTemplateId>\s*</ParentTemplateId>' -replacementValue '<ParentTemplateId i:nil="true" />'  
            $xmlTemplate = Format-XML($xmlTemplate)
		    $xmlTemplate = Replace-InvalidFormat -SchemaTemplate $xmlTemplate

            $query = "UPDATE DynamicFrontSystemTemplate
                            SET FrontSystemTemplateXml = '$template'
                            WHERE FrontSystemId = $id"
                
            #Write-Host $query
            
            Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
            Write-Host Uploaded new XML template for "'$name'($id)" `r`n -ForegroundColor Green

        }
    }catch{
        Write-Error $_
        Write-Error $name
    }
}else{
    Write-Host "'Viewgroup'" variable is empty or the "'Templates_ViewGroup.csv'" doesnt exist in the directory -ForegroundColor Red
}
