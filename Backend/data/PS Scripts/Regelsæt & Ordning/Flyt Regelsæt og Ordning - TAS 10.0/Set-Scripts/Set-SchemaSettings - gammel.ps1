#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'


if($ordning_id -ne $false){

    DoesZipExist #Does data.zip exists

    $testPath = DoesFileExist -FileName SchemaSettings.csv

    if($testPath){
        
        Title -Title 'Set-SchemaSettings'

        $schemaSettings_csv = Import-Csv -Path $path\SchemaSettings.csv

        $insert_schema_setting = ''
        $insert_schema_param = ''
        $insert_data_sync = ''

        $schemaSettings_count = 0
        $schemaSettingParameters_count = 0
        $DataSyncs_count = 0

        ##################################
        ######### SCHEMA SETTINGS ########
        ##################################

        foreach($s in $schemaSettings_csv){
            $s_forsystem_name = $s.TEKST
            $s_åben = $s.AKTIVITET_KODE 
            $s_luk = isNull($s.LUK_AKTIVITET_KODE) 
            $s_statistik_id = $s.STATISTIK_MODUL_ID
            $s_tjekliste_data_id = $s.TJEKLISTEDATA_ID
            $s_statistik_bruger = $s.STATISTIK_MODUL_BRUGER
            $s_tjekliste_id = $s.TJEKLISTEDATA_TJEKLISTEID
            $s_genåben = isNull_int($s.GENAABEN_AKTIVITET_ID)
            $s_ordning_forsystem_id = $s.ORDNING_FORSYSTEM_ID
            $s_public = $s.IsPublic


            $schema_param = isNull($s.PARM)
            $schema_object = isNull($s.OBJEKT)

            $data_sync_NextActivity = $s.NextActivityId #Return the Activity code
            $data_sync_ApproveActivity = TrueOrFalse($s.ApproveActivity)
            $data_sync_NumberOfRespiteDays = $s.NumberOfRespiteDays
            $data_sync_CaseLogState = $s.CaseLogState
            $data_sync_ActionOnCompletion = $s.ActionOnCompletion
            
            $isActivityLinkedToOrdning = IsActivityLinkedToOrdning -Code $s_åben

            if($isActivityLinkedToOrdning){
                $doesSchemaExist = DoesSchemaExist -SchemaName $s_forsystem_name

                if($doesSchemaExist){
                    
                    if($schema_object -eq 'nv_DataSync'){
                        $exist = DoesSchemaSettingExist -FORSYSTEM_NAME $s_forsystem_name -OPEN_ACTIVITY $s_åben -CLOSE_ACTIVITY $s_luk -PARM $schema_param -NextActivityId $data_sync_NextActivity -ApproveActivity $data_sync_ApproveActivity -NumberOfRespiteDays $data_sync_NumberOfRespiteDays -CaseLogState $data_sync_CaseLogState -ActionOnCompletion $data_sync_ActionOnCompletion -TjeklisteId $s_tjekliste_id
                    }else{
                        $exist = DoesSchemaSettingExist -FORSYSTEM_NAME $s_forsystem_name -OPEN_ACTIVITY $s_åben -CLOSE_ACTIVITY $s_luk -PARM $schema_param -TjeklisteId $s_tjekliste_id
                    }
                    if($exist){
                        Write-Host $true
                    }else{
                        Write-Host $false
                    }

     <#
                    if($exist -eq $false){
                        $newOpenActivityId = GetActivityId -ActivityCode $s_åben
    
                        if($s_luk -ne 'NULL'){
                            $newCloseActivityId = GetActivityId -ActivityCode $s_luk
                        }else{
                            $newCloseActivityId = ''
                        }
        
                        if($s_genåben -ne 'NULL'){
                            $s_genåben = GetActivityId -ActivityCode $s_genåben
                        }
    
                        $s_public_int = 0

                        if($s_public -eq 'true'){
                            $s_public_int = 1
                        }
                        
                        if(!([string]::IsNullOrEmpty($newOpenActivityId))){
                            
                            if(([string]::IsNullOrEmpty($newCloseActivityId))){
                                $newCloseActivityId = isNull_int($newCloseActivityId)
                            }
                    
                            $timeStamp = Get-Date -Format "yyyy/MM/dd HH:mm:ss.fff"
                            $newSchemaId = GetSchemaID -SchemaName $s_forsystem_name
                            
                            if(([string]::IsNullOrEmpty($newCloseActivityId))){
                                $insert_schema_setting = "INSERT INTO ORDNING_FORSYSTEM(FORSYSTEM_ID, ORDNING,AKTIVITET_ID,TIMESTAMP,LUK_AKTIVITET_ID,STATISTIK_MODUL_ID,TJEKLISTEDATA_ID, STATISTIK_MODUL_ID_BRUGER, TJEKLISTEDATA_TJEKLISTEID, GENAABEN_AKTIVITET_ID, OBJEKT, PROJEKTTYPE, BUDGET_OMRAADE_ID, INDSATSOMRAADE_ID, IsPublic) `r`n VALUES($newSchemaId, '$ordning',$newOpenActivityId, '$timeStamp',NULL,NULL,NULL,NULL,NULL ,$s_genåben,NULL,NULL,NULL,NULL, $s_public_int) `r`n"
                            }else{
                                $insert_schema_setting = "INSERT INTO ORDNING_FORSYSTEM(FORSYSTEM_ID, ORDNING,AKTIVITET_ID,TIMESTAMP,LUK_AKTIVITET_ID,STATISTIK_MODUL_ID,TJEKLISTEDATA_ID, STATISTIK_MODUL_ID_BRUGER, TJEKLISTEDATA_TJEKLISTEID, GENAABEN_AKTIVITET_ID, OBJEKT, PROJEKTTYPE, BUDGET_OMRAADE_ID, INDSATSOMRAADE_ID, IsPublic) `r`n VALUES($newSchemaId, '$ordning',$newOpenActivityId, '$timeStamp',$newCloseActivityId,NULL,NULL,NULL,NULL ,$s_genåben,NULL,NULL,NULL,NULL, $s_public_int) `r`n"
                            }
           

                            Write-Host $insert_schema_setting
                            
                            if(!([string]::IsNullOrEmpty($insert_schema_setting))){
                                Invoke-Sqlcmd -Query $insert_schema_setting -ConnectionString $connectionstring -MaxCharLength $maxCharLength
                                $schemaSettings_count += 1
                            }
            
                            ####################################
                            ########### SCHEMA PARAM ###########
                            ####################################
                            
                            #getting the new ordning_forsystem_id 
                            $new_ordning_forsystem_id = GetOrdningForsystemId -FORSYSTEM_ID $newSchemaId -OPEN_ACTIVITY $newOpenActivityId -CLOSE_ACTIVITY $newCloseActivityId # GET NEW ORDNING_FORSYSTEM_ID
                            
                            if(([string]::IsNullOrEmpty($new_ordning_forsystem_id))){
                                Write-Error "ORDNING_FORSYSTEM_ID is 0. The Schema Setting wasnt created right"
                                break
                            }

                            $Param_exist = DoesSchemaParameterExist -ORDNING_FORSYSTEM_ID $new_ordning_forsystem_id

                            if($Param_exist -eq $false){
                                if($schema_param -eq ''){
                                    $insert_schema_param = "INSERT INTO ORDNING_FORSYSTEM_PARM(FORSYSTEM_ID,ORDNING,AKTIVITET_ID,PARM,OBJEKT,ORDNING_FORSYSTEM_ID) `r`n VALUES($newSchemaId,'$ordning',$newOpenActivityId,NULL,'$schema_object',$new_ordning_forsystem_id) `r`n"
                                }elseif($schema_param.Contains('#CREATEVALIDATION')){
                                    $newCreateValidation =  "#CREATEVALIDATION(CASEHASNOOPENFRONTSYSTEMS,$newSchemaId,Sagen har et eller flere åbne skemaer ({0}). Indsend først dit åbne skema.)"
                        
                                    $insert_schema_param = "INSERT INTO ORDNING_FORSYSTEM_PARM(FORSYSTEM_ID,ORDNING,AKTIVITET_ID,PARM,OBJEKT,ORDNING_FORSYSTEM_ID) `r`n VALUES($newSchemaId,'$ordning',$newOpenActivityId,'$newCreateValidation','$schema_object',$new_ordning_forsystem_id) `r`n"
                                }elseif($schema_object -eq 'nv_DataSync'){
                                    $insert_schema_param = "INSERT INTO ORDNING_FORSYSTEM_PARM(FORSYSTEM_ID,ORDNING,AKTIVITET_ID,PARM,OBJEKT,ORDNING_FORSYSTEM_ID) `r`n VALUES($newSchemaId,'$ordning',$newOpenActivityId,'$schema_param','$schema_object',$new_ordning_forsystem_id) `r`n"
                                }
                    
                                if($insert_schema_param -ne ''){
                                    Write-Host $insert_schema_param
                                    Invoke-Sqlcmd -Query $insert_schema_param -ConnectionString $connectionstring -MaxCharLength $maxCharLength
                                    $schemaSettingParameters_count += 1
                                }  


                                ####################################
                                ######### DATA SYNC SETUP ##########
                                ####################################
                        
                                if($data_sync_ApproveActivity -ne ''){
                                    $data_sync_ApproveActivity = TrueOrFalse($data_sync_ApproveActivity)

                                    if($data_sync_NextActivity -ne ''){
                                        $data_sync_NextActivity = GetActivityId -ActivityCode $data_sync_NextActivity
                                    }                       

                                    if($data_sync_NextActivity -eq ''){
                                        $insert_data_sync = "INSERT INTO DATASYNC_JOB_SETUP(SchemeFrontSystemId,NextActivityId,ApproveActivity,NumberOfRespiteDays,CaseLogState,ActionOnCompletion) `r`n VALUES($new_ordning_forsystem_id,NULL,$data_sync_ApproveActivity,$data_sync_NumberOfRespiteDays,'$data_sync_CaseLogState',$data_sync_ActionOnCompletion) `r`n"
                                    }else{
                                        $insert_data_sync = "INSERT INTO DATASYNC_JOB_SETUP(SchemeFrontSystemId,NextActivityId,ApproveActivity,NumberOfRespiteDays,CaseLogState,ActionOnCompletion) `r`n VALUES($new_ordning_forsystem_id,$data_sync_NextActivity,$data_sync_ApproveActivity,$data_sync_NumberOfRespiteDays,'$data_sync_CaseLogState',$data_sync_ActionOnCompletion) `r`n"
                                    }


                                    if($insert_data_sync -ne ''){
                                        Write-Host $insert_data_sync
                                    
                                        Invoke-Sqlcmd -Query $insert_data_sync -ConnectionString $connectionstring -MaxCharLength $maxCharLength
                                        $DataSyncs_count += 1
                                    }
                                }
                            }
                        }
                    } #>
                }
            }   
        }

        Write-Host RESULTS: -ForegroundColor Green
        Write-Host Schema Settings upload Count : $schemaSettings_count row'(s)' -ForegroundColor Green
        Write-Host Schema Setting Parameters upload Count : $schemaSettingParameters_count row'(s)' -ForegroundColor Green
        Write-Host Data Sync upload Count : $DataSyncs_count row'(s)' -ForegroundColor Green
    }
}


