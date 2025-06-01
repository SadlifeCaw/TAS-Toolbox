#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'
    
DoesZipExist #Does data.zip exists
   
$testPath = DoesFileExist -FileName Activities.csv

if($testPath){

    Title -Title 'Set-Activities'

    #Getting data 
    $activities_csv = Import-Csv -Path $path/Activities.csv -Encoding UTF8

    $query_tas_konto = "" #Inserting Tas konto if they do not exist
    $tas_konto_names = @() #Tas konto names

    $query = "" #The query which insert and/or update the data into the table

    $query_tk = "" #Update query for Activity konto

    $new_activities = @()
    $update_activities = @()

    $query_notification = ""

    $names = ""
    $count = 0

    $activity_quota_query = "" #query for insert new or update activityQuota

    foreach($tk in $activities_csv){

        if($tk.TAS_KONTO -ne ''){
            $exist_tas_konto = DoesTasKontoExist -KONTO $tk.TAS_KONTO

            $konto = $tk.TAS_KONTO
            $tekst = $tk.TAS_KONTO_TEKST
            $udtog = $tk.KONTOUDTOG_DEB_KRE
            $konto_gruppe = $tk.KONTOUDTOG_GRUPPE
            $anvendelse = $tk.KONTO_ANVENDELSE
            $ctrl = $tk.CTRL_PI
            $integration_id = $tk.INTEGRATION_ID
            $factor = isNull_int($tk.FAKTOR)

            if((!$exist_tas_konto) -and (!$tas_konto_names.Contains($tk.TAS_KONTO))){
                
                $query_tas_konto += "INSERT INTO RG_TAS_KONTO (TAS_KONTO, TEKST, KONTOUDTOG_DEB_KRE, KONTOUDTOG_GRUPPE, KONTO_ANVENDELSE, CTRL_PI, INTEGRATION_ID, FAKTOR) `r`n" + "VALUES('$konto','$tekst', '$udtog', '$konto_gruppe', '$anvendelse', '$ctrl', $integration_id, $factor)`r`n"
                $tas_konto_names += $konto
                
            }elseif($exist_tas_konto -and (!$tas_konto_names.Contains($tk.TAS_KONTO))){
                $query_tas_konto += "UPDATE RG_TAS_KONTO `r`n SET TAS_KONTO = '$konto', TEKST = '$tekst', KONTOUDTOG_DEB_KRE = '$udtog', KONTOUDTOG_GRUPPE = '$konto_gruppe', KONTO_ANVENDELSE = '$anvendelse', CTRL_PI = '$ctrl', INTEGRATION_ID = $integration_id, FAKTOR = $factor `r`n WHERE TAS_KONTO = '$konto' `r`n"
                $tas_konto_names += $konto
            }
        }
    }
    
    if(!([string]::IsNullOrEmpty($query_tas_konto))){
                    
        try{
            $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
            $connection.Open();
				
            Invoke-Sqlcmd -Query $query_tas_konto -ConnectionString $connectionstring -MaxCharLength $maxCharLength
				
			write-host Created/Updated the following TAS_KONTO: -ForegroundColor Green
            $tas_konto_names | foreach {Write-Host $_ -ForegroundColor Green }

            #Closing db connection
            $connection.Close()
            Write-Host "DB connection closed."

        }catch{
            $_
        }
    }
        
    function InsertQuery([Object] $activity){
        $code = $activity.AKTIVITET_KODE 
        $tekst = $activity.TEKST
        $eco = $activity.KONS_ECO
        $kons_brev = $activity.KONS_BREV
        $kons_sagslog = $activity.KONS_SAGSLOG
        $auto_reminder = $activity.AUTO_REMINDER
        $auto_godkend = $activity.AUTO_GODKEND
        $egen = $activity.EGEN_GODKENDELSE
        $object = isNull($activity.OBJEKT)
        $aktiv = $activity.AKTIV
        $aktivitetType = $activity.AKTIVITET_TYPE
        $budget = $activity.BUDGET
        $nySagsbehandler = isNull($activity.NY_SAGSBEHANDLER)
        $nySagsbehandlerType = isNull($activity.NY_SAGSBEHANDLERTYPE)

                        
        $q = "INSERT INTO AKTIVITET (AKTIVITET_KODE,TEKST,KONS_ECO,KONS_BREV,KONS_SAGSLOG,AUTO_REMINDER,REMINDER_HVEM,AUTO_GODKEND,EGEN_GODKENDELSE,BREV_TYPE,OBJEKT,AKTIONSKODE,AKTIV,AKTIVITET_TYPE,BUDGET,DIMENSION,AKTIVITET_PARM,NY_SAGSBEHANDLER,Email,NY_SAGSBEHANDLERTYPE,PublicAvailableForApplicationService,PublicName,UserGuide,ApproveText,MustSupplyTitle,MustApplyNote,MustAttachFile,MustSupplyCommitmentSpecification,MustSupplyPaymentSpecification,PortalType,DisplayTaskOverviewTab,RespondWithActivityId,DigitalSignature,MustAttachFilesAmount,DisplayAsButton,ButtonText,ButtonDescription,DisplayCaseInfo,DisplayUserProfileAsTab,DisplayAttachementTabBeforeFrontsystems,AttachtmentDescription,DisplayTopBar,DisplayOnBehalfOf,IsSendApplicationActivity,ActivityQuotaId,DisplayUserProfileForAllRoles,IsSystem) `r`n VALUES('$code', '$tekst', 'N', '$kons_brev', '$kons_sagslog', '$auto_reminder', NULL, '$auto_godkend', '$egen', NULL, NULL, NULL, '$aktiv', '$aktivitetType', '$budget', NULL, NULL, $nySagsbehandler, NULL, $nySagsbehandlerType, 0, NULL, NULL, NULL, 0, 0, 0, 0, 0, NULL, 0, NULL, 0, NULL, 0, 0, NULL, 0, 0,  0, NULL, 0, 0, 0, NULL, 0, 0) `r`n"
            
        try{
            $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
            $connection.Open();

            Invoke-Sqlcmd -Query $q -ConnectionString $connectionstring -MaxCharLength $maxCharLength
                
            #Closing db connection
            $connection.Close()

        }catch{
            Write-Error $_
        }
    }

    function UpdateQuery([Object] $activity){
        $code = $activity.AKTIVITET_KODE 
        $tekst = $activity.TEKST
        $eco = $activity.KONS_ECO
        $kons_brev = $activity.KONS_BREV
        $kons_sagslog = $activity.KONS_SAGSLOG
        $auto_reminder = $activity.AUTO_REMINDER
        $auto_godkend = $activity.AUTO_GODKEND
        $egen = $activity.EGEN_GODKENDELSE
        $object = isNull($activity.OBJEKT)
        $aktiv = $activity.AKTIV
        $aktivitetType = $activity.AKTIVITET_TYPE
        $budget = $activity.BUDGET
        $nySagsbehandler = isNull($activity.NY_SAGSBEHANDLER)
        $nySagsbehandlerType = isNull($activity.NY_SAGSBEHANDLERTYPE)

        $publicAvailable = TrueOrFalse($activity.PublicAvailableForApplicationService)
                                        
        $publicName = isNull($activity.PublicName)
        $userGuide = isNull($activity.UserGuide)
        $approveText = isNull($activity.ApproveText)
        $mustSupplyTitle = $activity.MustSupplyTitle
        $mustApplyNote = $activity.MustApplyNote
        $mustAttachFile = $activity.MustAttachFile
        $mustSupplyCommitment = TrueOrFalse($activity.MustSupplyCommitmentSpecification)
        $mustSupplyPayment = TrueOrFalse($activity.MustSupplyPaymentSpecification)
        $portalType = isNull($activity.PortalType)
        $displayTaskOverview = TrueOrFalse($activity.DisplayTaskOverviewTab)
        $respondWithActivityId = isNull_int($activity.RespondWithActivityId)
        $DigitalSignature = TrueOrFalse($activity.DigitalSignature)
        $mustAttachFilesAmount = isNull($activity.MustAttachFilesAmount)
        $displayButton = TrueOrFalse($activity.DisplayAsButton)
        $buttonText = isNull($activity.ButtonText)
        $buttonDescription = isNull($activity.ButtonDescription)
        $displayCaseInfo = TrueOrFalse($activity.DisplayCaseInfo)
        $displayUserProfile = TrueOrFalse($activity.DisplayUserProfileAsTab)
        $displayAttachementTab = TrueOrFalse($activity.DisplayAttachementTabBeforeFrontsystems)
        $attachmentDescription = isNull($activity.AttachtmentDescription)
        $displayTopBar = TrueOrFalse($activity.DisplayTopBar)
        $displayOnBehalf = TrueOrFalse($activity.DisplayOnBehalfOf)
        $isSendApplication = TrueOrFalse($activity.IsSendApplicationActivity)
        $ActivityQuota = isNull($activity.ActivityQuotaId)

        if($ActivityQuota -ne 'NULL'){            
            $activity_id = GetActivityId -ActivityCode $code
            $quotaType = $activity.ActivityQuotaType
            $title = $activity.HeaderTitle
            $subText = $activity.HeaderSubText
            $htmlText = $activity.BottomHtmlText

            #$doesQuotaExist = DoesActivityQuotaExist -ID $ActivityQuota
            $activityQuotaId = GetActivityQuota -id $ActivityQuota

            if([string]::IsNullOrEmpty($activityQuotaId)){
                $newActivityQuotaId = New-Guid
                $activity_quota_query = "INSERT INTO ActivityQuota(Id, ActivityQuotaType, HeaderTitle, HeaderSubText, BottomHtmlText) `r`n VALUES('$newActivityQuotaId', $quotaType, '$title', '$subText', '$htmlText') `r`n"
				$ActivityQuota = isNull($newActivityQuotaId)
			}else{
                $activity_quota_query = "UPDATE ActivityQuota `r`n SET ActivityQuotaType = $quotaType, HeaderTitle = '$title', HeaderSubText = '$subText', BottomHtmlText = '$htmlText' `r`n WHERE Id = '$activityQuotaId' `r`n" 
				$ActivityQuota = isNull($activityQuotaId)
			}
			#Write-Host $activity_quota_query -ForegroundColor Magenta
            Invoke-Sqlcmd -Query $activity_quota_query -ConnectionString $connectionstring -MaxCharLength $maxCharLength 
        }

        $displayUserprofileForAllRoles = TrueOrFalse($activity.DisplayUserProfileForAllRoles)
        $isSystem = TrueOrFalse($activity.IsSystem)
                        
        $q = "UPDATE AKTIVITET `r`n set TEKST = '$tekst', KONS_ECO = '$eco' , KONS_BREV = '$kons_brev', KONS_SAGSLOG = '$kons_sagslog', AUTO_REMINDER='$auto_reminder', AUTO_GODKEND='$auto_godkend', EGEN_GODKENDELSE='$egen', OBJEKT=$object, AKTIV='$aktiv', AKTIVITET_TYPE='$aktivitetType', BUDGET='$budget', NY_SAGSBEHANDLER=$nySagsbehandler, NY_SAGSBEHANDLERTYPE=$nySagsbehandlerType, PublicAvailableForApplicationService = $publicAvailable, PublicName = $publicName, UserGuide = $userGuide, ApproveText = $approveText,MustSupplyTitle = $mustSupplyTitle,MustApplyNote=$mustApplyNote,MustAttachFile=$mustAttachFile,MustSupplyCommitmentSpecification=$mustSupplyCommitment,MustSupplyPaymentSpecification=$mustSupplyPayment,PortalType=$portalType,DisplayTaskOverviewTab=$displayTaskOverview,RespondWithActivityId=$respondWithActivityId,DigitalSignature=$DigitalSignature,DisplayAsButton=$displayButton,ButtonText=$buttonText,ButtonDescription=$buttonDescription,DisplayCaseInfo=$displayCaseInfo,DisplayUserProfileAsTab=$displayUserProfile,DisplayAttachementTabBeforeFrontsystems=$displayAttachementTab,AttachtmentDescription=$attachmentDescription,DisplayTopBar=$displayTopBar,DisplayOnBehalfOf=$displayOnBehalf,IsSendApplicationActivity=$isSendApplication,ActivityQuotaId=$ActivityQuota,DisplayUserProfileForAllRoles=$displayUserprofileForAllRoles,IsSystem=$isSystem `r`n where AKTIVITET_KODE = '$code' `r`n `r`n"
        
        try{
            $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
            $connection.Open();

            Invoke-Sqlcmd -Query $q -ConnectionString $connectionstring -MaxCharLength $maxCharLength
                
            #Closing db connection
            $connection.Close()

        }catch{
            Write-Error $_
        }

    }

    foreach($a in $activities_csv){           
            
        $exist = DoesActivityExist -ActivityCode $a.AKTIVITET_KODE

        if(!$exist){
            Write-Host Inserted new Activity $a.AKTIVITET_KODE -ForegroundColor Green

            InsertQuery($a)
            
            UpdateQuery($a) #Some tables need the activity to be created first before making elements (ActivityQuota)
            $new_activities += $a.AKTIVITET_KODE
            

        }else{
            Write-Host Updated Activity $a.AKTIVITET_KODE -ForegroundColor Green

            UpdateQuery($a)
            $update_activities += $a.AKTIVITET_KODE
        }
    }
      
    try{
            
        Write-Host Inserted $new_activities.Count new activities:
        $new_activities | foreach {Write-Host $_ -ForegroundColor green}

        Write-Host `r`n Updated $update_activities.Count activities:
        $update_activities | foreach {Write-Host $_ -ForegroundColor Green}
                
    }catch{
        write-Error $_
    }    
    
    #Including the AKTIVITET_KONTO into the 'update' query
    #The Activities should ahve been created already from the 'insert' query
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        $connection.Open();
        
        foreach($ac in $activities_csv){
            $konto = $ac.TAS_KONTO
            $tidspunkt = $ac.TIDSPUNKT
            $deb_kre = $ac.DEB_KRE
            $procent = $ac.PROCENT.Replace(',','.')
                
            if(!([string]::IsNullOrEmpty($konto))){
                $activityId = GetActivityId -ActivityCode $ac.AKTIVITET_KODE

                $doesActivityKontoExist = DoesActivityHaveKonto -ActivityId $activityId -Konto $konto

                if($doesActivityKontoExist){
                    $query_tk = "UPDATE AKTIVITET_KONTO `r`n set TIDSPUNKT = '$tidspunkt', DEB_KRE = '$deb_kre', PROCENT = $procent `r`n WHERE AKTIVITET_ID = $activityId `r`n `r`n"
                }else{
                    $query_tk = "INSERT INTO AKTIVITET_KONTO(AKTIVITET_ID,TAS_KONTO,TIDSPUNKT,DEB_KRE,PROCENT) `r`n VALUES($activityId,'$konto','$tidspunkt','$deb_kre',$procent) `r`n"
                } 
                            
                Invoke-Sqlcmd -Query $query_tk -ConnectionString $connectionstring -MaxCharLength $maxCharLength
                Write-Host Activity konto is Completed -ForegroundColor Green                

            }
        }
        #Closing db connection
        $connection.Close()
        Write-Host "DB connection closed."
        
    }catch{
        Write-Error $_
    }
   

    #Activity notifications
    foreach($an in $activities_csv){
        
        if(!([string]::IsNullOrEmpty($an.INTERESSENT_ROLLE_ID)) -or !([string]::IsNullOrEmpty($an.SECURITY_USERS_ID)) -or !([string]::IsNullOrEmpty($an.KATEGORITYPE))){
            $interessent = isNull($an.INTERESSENT_ROLLE_ID)
            $security = isNull($an.SECURITY_USERS_ID)
            $kategory = $an.KATEGORITYPE
            $code = $an.AKTIVITET_KODE
    
            $id = GetActivityId -ActivityCode $code
   
            $exist_notification = DoesActivityHaveNotification -ActivityId $id 
    
            if($exist_notification){
                $query_notification = "UPDATE AKTIVITET_EMAIL `r`n set INTERESSENT_ROLLE_ID = $interessent, SECURITY_USERS_ID = $security, KATEGORITYPE = '$kategory' `r`n WHERE AKTIVITET_ID = $id `r`n `r`n"
                Write-Host Updated notification Activity "'$code'" -ForegroundColor Yellow
            }else{
                $query_notification = "INSERT INTO AKTIVITET_EMAIL(AKTIVITET_ID, INTERESSENT_ROLLE_ID,SECURITY_USERS_ID, KATEGORITYPE) `r`n VALUES($id, $interessent, $security, '$kategory') `r`n `r`n"
                Write-Host Inserted notification Activity "'$code'" -ForegroundColor Green
            } 

            Invoke-Sqlcmd -Query $query_notification -ConnectionString $connectionstring -MaxCharLength $maxCharLength
        }
    }
}


