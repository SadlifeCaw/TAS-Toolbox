#Author : Nevethan Alagaratnam

$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1"
. "$path\Methods.ps1"

$testPath = DoesFileExist -FileName TemplateSecurity.csv

if($testPath){
    
    $template_csv = Import-Csv -Path $path\TemplateSecurity.csv.

    foreach($schema in $template_csv){
        $name = $schema.SKEMA_NAVN
        

        $DoesSchemaExist = DoesSchemaExist -SchemaName $name

        if($DoesSchemaExist){

            $templateId = GetSchemaID -SchemaName $name
            $user = $schema.USER_NAME
            $status = $schema.STATUS

            $DoesSecurityUsernameExist = DoesSecurityUsernameExist -Name $user

            if($DoesSecurityUsernameExist){
                
                $DoesSchemaSecurityExist = DoesSchemaSecurityExist -Control $templateId -Username $user
            
                if(!$DoesSchemaSecurityExist){
                    
                    $query = "INSERT INTO SECURITY_INFO(APPLICATION, WINDOW, CONTROL, USER_NAME, STATUS) `r`n VALUES('TAS', 'SagMain', '$templateId','$user','$status') `r`n"

                    try{
                        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
                        $connection.Open();

                        
                        Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
                        
			            Write-Host Created schema security -ForegroundColor Green
                        Write-Host Template : $name "($templateId)"
                        Write-Host Username : $user
                        Write-Host Status :  $status
                        Write-Host
                        
                    }catch{
                        Write-Error $_
                    }      

                }else{
                    Write-Host Schema Security setting already exists -ForegroundColor Yellow
                    Write-Host Template : $name "($templateId)"
                    Write-Host Username : $user
                    Write-Host Status :  $status
                    Write-Host
                } 
            }else{
                Write-Host Username "'$user'" doesnt exist -ForegroundColor Yellow
            }                  
        }else{
            Write-Host Schema "'$name'" doesnt exist -ForegroundColor Yellow
            Write-Host 
        }
    }

}else{
    Write-Host Couldnt find document "'Templates.csv'" -ForegroundColor Yellow
}



