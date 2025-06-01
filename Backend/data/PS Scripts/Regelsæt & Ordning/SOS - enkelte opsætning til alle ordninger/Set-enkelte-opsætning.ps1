#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\0. Configs.ps1" #Loading all Configs
. "$path\1. Methods - v2.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'

$SpecificSchemaSettings_csv = Import-Csv -Path $path\SpecificSchemaSettings.csv

$list_ordning = @()

## Get list of ordnings ##

try{
    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

    $connection.Open();

    if($connection.State -eq "Open"){
        <#
        $query = "select distinct ORDNING
					from ordning 
					where ORDNING IN (select ORDNING
					from ORDNING_PROJEKTTYPE
					where REGELSAET_ID IN (select REGELSAET_ID
		            from REGELSAET
		            where TEKST IN ($list_regelsaet))) AND ORDNING NOT IN('MASTER1','MASTER2')"

        #>

        $query="select ORDNING from ORDNING"

        $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
        if($SQLresult -eq $null){
            Write-Error -Message "Couldnt find the RegelSæt ID. It is either because the variable is empty or the ordning name does not exist " -Category InvalidArgument 
            break
        }else{
            $list_ordning = $SQLresult.itemArray
        } 
    }

}catch{
    Write-Error $_    
}finally{
    $connection.Close()
}


$list_ordning_length = $list_ordning.Length
$i = 0

foreach($single in $SpecificSchemaSettings_csv){
    $open = $single.AKTIVITET_ID
    $close = $single.LUK_AKTIVITET_ID
    Write-Progress -Id 0 "Schema Setting for activity - $open and close activity - $close"

    $PARM = isNull($single.PARM)
    $OBJEKT = isNull($single.OBJEKT)
   
    foreach($o in $list_ordning){
        
        if($i -eq $list_ordning_length){
            $i = 0
        }else{
            $i++
        }
        Write-Progress -Id 1 "Ordning number $i out of $list_ordning_length" 
        
        $isActivityBoundToOrdningOpen = isActivityBoundToOrdning -Ordning $o -Code $single.AKTIVITET_ID

        if([string]::IsNullOrEmpty($single.LUK_AKTIVITET_ID)){
            $isActivityBoundToOrdningClose = $true
        }else{
            $isActivityBoundToOrdningClose = isActivityBoundToOrdning -Ordning $o -Code $single.LUK_AKTIVITET_ID
        }

        if($isActivityBoundToOrdningOpen -and $isActivityBoundToOrdningClose){
            Write-Host Activities are bound

            if([string]::IsNullOrEmpty($single.LUK_AKTIVITET_ID)){
                $LUK_AKTIVITET_ID = isNull($single.LUK_AKTIVITET_ID)
            }else{
                $LUK_AKTIVITET_ID = $single.LUK_AKTIVITET_ID
            }
            
              
            $doesSchemaSettingExist = DoesSchemaSettingExist -FORSYSTEM_NAME $single.TEKST -OPEN_ACTIVITY $single.AKTIVITET_ID -CLOSE_ACTIVITY $LUK_AKTIVITET_ID -PARM $PARM -OBJEKT $OBJEKT -NextActivityId $single.NextActivityId -ApproveActivity $single.ApproveActivity -NumberOfRespiteDays $single.NumberOfRespiteDays -CaseLogState $single.CaseLogState -ActionOnCompletion $single.ActionOnCompletion -ordning $o

            if(!$doesSchemaSettingExist){
            
                $schemaId = GetSchemaID -SchemaName $single.TEKST     
                $timeStamp = Get-Date -Format "yyyy/MM/dd HH:mm:ss.fff"
                $AKTIVITET_ID = GetActivityId -Activity_code $single.AKTIVITET_ID 
                

                if($LUK_AKTIVITET_ID -ne 'NULL'){
                    $LUK_AKTIVITET_ID = GetActivityId -Activity_code $single.LUK_AKTIVITET_ID
                }                
                
                $IsPublic = TrueOrFalse($single.IsPublic)
                
                try{
                    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

                    $connection.Open();

                    if($connection.State -eq "Open"){
                        
                        if($LUK_AKTIVITET_ID -ne 'NULL'){
                            $query_insert = "INSERT INTO ORDNING_FORSYSTEM(FORSYSTEM_ID, ORDNING,AKTIVITET_ID,TIMESTAMP,LUK_AKTIVITET_ID,STATISTIK_MODUL_ID,TJEKLISTEDATA_ID, STATISTIK_MODUL_ID_BRUGER, TJEKLISTEDATA_TJEKLISTEID, GENAABEN_AKTIVITET_ID, OBJEKT, PROJEKTTYPE, BUDGET_OMRAADE_ID, INDSATSOMRAADE_ID, IsPublic) `r`n VALUES($schemaId, '$o',$AKTIVITET_ID, '$timeStamp',$LUK_AKTIVITET_ID,NULL,NULL,NULL,NULL ,NULL,NULL,NULL,NULL,NULL, $IsPublic)"

                        }else{
                            $query_insert = "INSERT INTO ORDNING_FORSYSTEM(FORSYSTEM_ID, ORDNING,AKTIVITET_ID,TIMESTAMP,LUK_AKTIVITET_ID,STATISTIK_MODUL_ID,TJEKLISTEDATA_ID, STATISTIK_MODUL_ID_BRUGER, TJEKLISTEDATA_TJEKLISTEID, GENAABEN_AKTIVITET_ID, OBJEKT, PROJEKTTYPE, BUDGET_OMRAADE_ID, INDSATSOMRAADE_ID, IsPublic) `r`n VALUES($schemaId, '$o',$AKTIVITET_ID, '$timeStamp',NULL,NULL,NULL,NULL,NULL ,NULL,NULL,NULL,NULL,NULL, $IsPublic)"

                        }
                                                
                        Write-Host $query_insert
                        Invoke-Sqlcmd -Query $query_insert -ConnectionString $connectionstring -MaxCharLength $maxCharLength

                        $new_ordning_forsystem_id = GetOrdningForsystemId -FORSYSTEM_ID $schemaId -OPEN_ACTIVITY $AKTIVITET_ID -CLOSE_ACTIVITY $LUK_AKTIVITET_ID -ORDNING $o # GET NEW ORDNING_FORSYSTEM_ID
                                                
                        if($PARM -eq 'NULL'){
                            if($OBJEKT -eq 'NULL'){
                                $insert_param = "INSERT INTO ORDNING_FORSYSTEM_PARM(FORSYSTEM_ID,ORDNING,AKTIVITET_ID,PARM,OBJEKT,ORDNING_FORSYSTEM_ID) `r`n VALUES($schemaId,'$o',$AKTIVITET_ID,NULL,NULL,$new_ordning_forsystem_id) `r`n"
                            }else{
                                $insert_param = "INSERT INTO ORDNING_FORSYSTEM_PARM(FORSYSTEM_ID,ORDNING,AKTIVITET_ID,PARM,OBJEKT,ORDNING_FORSYSTEM_ID) `r`n VALUES($schemaId,'$o',$AKTIVITET_ID,NULL,$OBJEKT,$new_ordning_forsystem_id) `r`n"
                            }
                        }elseif($PARM.Contains('#CREATEVALIDATION')){
                            $newCreateValidation =  "#CREATEVALIDATION(CASEHASNOOPENFRONTSYSTEMS,$schemaId,Sagen har et eller flere åbne skemaer ({0}). Indsend først dit åbne skema.)"
                            
                            $insert_param = "INSERT INTO ORDNING_FORSYSTEM_PARM(FORSYSTEM_ID,ORDNING,AKTIVITET_ID,PARM,OBJEKT,ORDNING_FORSYSTEM_ID) `r`n VALUES($schemaId,'$o',$AKTIVITET_ID,'$newCreateValidation',$OBJEKT,$new_ordning_forsystem_id) `r`n"
                        }elseif($OBJEKT -eq "'nv_DataSync'"){
                            $insert_param = "INSERT INTO ORDNING_FORSYSTEM_PARM(FORSYSTEM_ID,ORDNING,AKTIVITET_ID,PARM,OBJEKT,ORDNING_FORSYSTEM_ID) `r`n VALUES($schemaId,'$o',$AKTIVITET_ID,$PARM,$OBJEKT,$new_ordning_forsystem_id) `r`n"
                        }
                     
                        Write-Host $insert_param
                        Invoke-Sqlcmd -Query $insert_param -ConnectionString $connectionstring -MaxCharLength $maxCharLength             


                        if($OBJEKT -eq "'nv_DataSync'"){
                            $ApproveActivity = TrueOrFalse($single.ApproveActivity)
                            $NumberOfRespiteDays = $single.NumberOfRespiteDays
                            $CaseLogState = $single.CaseLogState
                            $ActionOnCompletion = $single.ActionOnCompletion

                            if($single.NextActivityId -ne ''){
                                $NextActivityId = GetActivityId -Activity_code $single.NextActivityId
                            }                       
                            
                            if($single.NextActivityId -eq ''){
                                $insert_data_sync = "INSERT INTO DATASYNC_JOB_SETUP(SchemeFrontSystemId,NextActivityId,ApproveActivity,NumberOfRespiteDays,CaseLogState,ActionOnCompletion) `r`n VALUES($new_ordning_forsystem_id,NULL,$ApproveActivity,$NumberOfRespiteDays,'$CaseLogState',$ActionOnCompletion) `r`n"
                            }else{
                                $insert_data_sync = "INSERT INTO DATASYNC_JOB_SETUP(SchemeFrontSystemId,NextActivityId,ApproveActivity,NumberOfRespiteDays,CaseLogState,ActionOnCompletion) `r`n VALUES($new_ordning_forsystem_id,$NextActivityId,$ApproveActivity,$NumberOfRespiteDays,'$CaseLogState',$ActionOnCompletion) `r`n"
                            }

                            if($insert_data_sync -ne ''){
                                Write-Host $insert_data_sync
                                Invoke-Sqlcmd -Query $insert_data_sync -ConnectionString $connectionstring -MaxCharLength $maxCharLength
                            }
                        }
                    }
                }catch{
                    Write-Error $_
                }finally{
                    $connection.Close()
                }
            }       
        }else{
            Write-Host Activities - $open and $close are not bound -ForegroundColor Yellow
        }
    }
}
