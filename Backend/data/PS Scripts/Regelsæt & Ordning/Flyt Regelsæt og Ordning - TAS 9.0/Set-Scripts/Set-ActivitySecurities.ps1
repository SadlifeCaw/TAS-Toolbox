#Author : Nevethan Alagaratnam

########################### IMPORTANT #################################
#PREREQUISITE FOR USING THE SCRIPT !!!!!!!
#The security rolls/groups MUST be on the TAS where you want to move to. 
#######################################################################

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods
    
DoesZipExist #Does data.zip exists

$testPath = DoesFileExist -FileName ActivitiesSecurityPermissions.csv

if($testPath){
        
    Title -Title 'Set-ActivitiesSecurities'

    $security_permissions = Import-Csv -Path $path/ActivitiesSecurityPermissions.csv -Encoding UTF8

    $insert = ''

    $i = 0

    foreach($sp in $security_permissions){
        
        $name_sp = $sp.NAME
        
        $status_sp = $sp.STATUS
    
        if($sp.synlig -eq 'True'){
            $synlig_sp = 1
        }else{
            $synlig_sp = 0
        }  

       
        #Getting the activity code from PROD
        $id_sp = GetActivityId -ActivityCode $sp.AKTIVITET_KODE

        $doesNameExist = DoesSecurityNameExist -Name $name_sp
        
        if($doesNameExist){
            $exist = DoesActivitySecurityPermissionExist -ActivityId $id_sp -NAME $name_sp
        
            if($exist -eq $false){
                $i++

                $insert = $insert + "($id_sp,'$name_sp','$status_sp',$synlig_sp), `r`n"   

                if($security_permissions.Count -gt 100){
                    if($i -eq 100){
                        if(!([string]::IsNullOrEmpty($insert))){
                            write-host "The INSERT query has been created.`r`n"
                            $insert = "INSERT INTO AKTIVITET_SECURITY(AKTIVITET_ID,NAME,STATUS,synlig) `r`n" + 'VALUES' + $insert
                            $insert = $insert.Substring(0,$insert.Length-4) #remove the last ','

                            #$insert #Display INSERT INTO query

                            Invoke-Sqlcmd -Query $insert -ConnectionString $connectionstring -MaxCharLength $maxCharLength
               
                        }else{
                            Write-Host No Security Permissions to Insert
                        }
                        $insert = ''
                        $i = 0 
                    }
                }
            }
        }
    }

    if(!([string]::IsNullOrEmpty($insert))){
        
        $insert = "INSERT INTO AKTIVITET_SECURITY(AKTIVITET_ID,NAME,STATUS,synlig) `r`n" + 'VALUES' + $insert
        $insert = $insert.Substring(0,$insert.Length-4) #remove the last ','

        #$insert #Display INSERT INTO query

        Invoke-Sqlcmd -Query $insert -ConnectionString $connectionstring -MaxCharLength $maxCharLength
        write-host Query Executed -ForegroundColor Green   
    }else{
        Write-Host No Security Permissions to Insert
    }

    <#
    if(!([string]::IsNullOrEmpty($insert))){
        write-host "The INSERT query has been created.`r`n"
        $insert = "INSERT INTO AKTIVITET_SECURITY(AKTIVITET_ID,NAME,STATUS,synlig) `r`n" + 'VALUES' + $insert
        $insert = $insert.Substring(0,$insert.Length-4) #remove the last ','

        $insert #Display INSERT INTO query

        Invoke-Sqlcmd -Query $insert -ConnectionString $connectionstring -MaxCharLength $maxCharLength
    }else{
        Write-Host No Security Permissions to Insert
    }
    #>
}    


