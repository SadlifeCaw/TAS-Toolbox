#Author : Nevethan Alagaratnam

$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1"
. "$path\Methods.ps1"

$testPath = DoesFileExist -FileName Templates_Names.csv

if($testPath){
	$template_csv = Import-Csv -Path $path\Templates_Names.csv.
    
    try{
        foreach($tmp in $template_csv){

            $viewGroupId = GetViewGroupId -ViewGroup $tmp.VISNINGSGRUPPE_NAVN

            $doesSkemaExist = DoesSchemaExist -SchemaName $tmp.SKEMA_NAVN

            if(!$doesSkemaExist){

                $Id = GetLastId #Getting the lastest ids for schema and OBJEKT
                
                $Schema = $tmp.SKEMA_NAVN

                $NewSchemaId = $Id + 1

                $Objekt_id = GetLastObjectId
                $Objekt_id = $Objekt_id + 1
                $Objekt = 'DynamicFrontSystemObject' + $Objekt_id

                $SchemaGuidId = New-Guid

                $template = '<TemplateDynamicFrontSystem xmlns="http://schemas.datacontract.org/2004/07/Traen.TAS.Domain.TAS.NotMapped.Frontsystem" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
                                    <TemplateTabs />
                                    <Templates />
                                </TemplateDynamicFrontSystem>'

                $query = "INSERT INTO OBJEKT(OBJEKT_ID,OBJEKT,TEKST,OBJEKTTYPE_ID,AKTIV,COLUMNS,OKO_KONSEKVENS)
                            VALUES($Objekt_id,'$Objekt','DynamicFrontSystemObject created by frontsystem editor',5,'J',NULL,0)

                            INSERT INTO FORSYSTEM(FORSYSTEM_ID, OBJEKT,TABEL,TEKST,OVERSKRIFT,TABEL_SLET,GENAABEN,FORSYSTEM_OBJEKT,SORTERING,BESKRIVELSE)
                            VALUES($NewSchemaId,'$Objekt','dbo.SAG_FORSYSTEM','$Schema',NULL,NULL,NULL,NULL,NULL,NULL)

                            INSERT INTO DynamicFrontSystemTemplate(Id, FrontSystemId, ViewGroupId, FrontSystemTemplateXml,Title)
                            VALUES('$SchemaGuidId', $NewSchemaId, '$viewGroupId', '$template', NULL)
                                
                            INSERT INTO SECURITY_TEMPLATE(APPLICATION,WINDOW,CONTROL,OBJECT_TYPE,DESCRIPTION)
                            VALUES('TAS','SagMain',$NewSchemaId, 'DynamicFrontSystem','Skema(" + $NewSchemaId + ")')"

                #Write-Host $query   
                
                Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
                Write-Host Created Schema "'$Schema'($NewSchemaId)" -ForegroundColor Green
            
            }else{
                Write-Host skema already exists -ForegroundColor Magenta
            }
            
        }
    }catch{
        Write-Error $_
    }	
}else{
    Write-Host Couldnt find document "'Templates_Viewgroups.csv'" -ForegroundColor Yellow
}



