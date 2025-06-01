#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs and Methods
. "$path\Methods.ps1"

Preprocess # Making sure powershell has installed the module 'SqlServer'

if($regelsæt_id -ne $false){
    Title -Title 'Get-Activities'
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        $query = "select distinct a1.AKTIVITET_KODE,a1.TEKST, a1.KONS_ECO,a1.KONS_BREV,a1.KONS_SAGSLOG,a1.AUTO_REMINDER,a1.AUTO_GODKEND,a1.EGEN_GODKENDELSE,a1.OBJEKT,a1.AKTIV,a1.AKTIVITET_TYPE,a1.BUDGET,a1.NY_SAGSBEHANDLER,a1.PublicAvailableForApplicationService,a1.PublicName
                    , a1.UserGuide, a1.ApproveText,a1.MustSupplyTitle,a1.MustApplyNote,a1.MustAttachFile,a1.MustSupplyCommitmentSpecification,a1.MustSupplyPaymentSpecification,a1.PortalType,a1.DisplayTaskOverviewTab,a1.RespondWithActivityId,a1.DigitalSignature,a1.MustAttachFilesAmount,
                    a1.DisplayAsButton,a1.ButtonText,a1.ButtonDescription,a1.DisplayCaseInfo,a1.DisplayUserProfileAsTab,DisplayAttachementTabBeforeFrontsystems,a1.AttachtmentDescription,a1.DisplayTopBar,a1.DisplayOnBehalfOf,a1.IsSendApplicationActivity,a1.ActivityQuotaId,a1.DisplayUserProfileForAllRoles
                    ,a1.IsSystem, ak.TAS_KONTO, ak.TIDSPUNKT, ak.DEB_KRE,ak.PROCENT,rtk.TEKST as 'TAS_KONTO_TEKST',rtk.KONTOUDTOG_DEB_KRE,rtk.KONTOUDTOG_GRUPPE, rtk.KONTO_ANVENDELSE,rtk.CTRL_PI,rtk.INTEGRATION_ID,rtk.FAKTOR,am.INTERESSENT_ROLLE_ID,am.SECURITY_USERS_ID,am.KATEGORITYPE,aq.ActivityQuotaType,aq.HeaderTitle
                    ,aq.HeaderSubText,aq.BottomHtmlText
                                        from AKTIVITET a1
                                        left join AKTIVITET_KONTO ak
                                        on ak.AKTIVITET_ID = a1.AKTIVITET_ID
                                        left join RG_TAS_KONTO rtk
                                        on ak.TAS_KONTO = rtk.TAS_KONTO
                                        left join AKTIVITET_EMAIL am
                                        on am.AKTIVITET_ID = a1.AKTIVITET_ID
                                        left join ActivityQuota aq
                                        on aq.ActivityId = a1.AKTIVITET_ID
                                        where a1.AKTIVITET_KODE IN(
	                                        select distinct a.AKTIVITET_KODE
	                                        from AKTIVITET_REGEL ar
	                                        inner join AKTIVITET a
	                                        on ar.AKTIVITET_ID = a.AKTIVITET_ID
	                                        where ar.REGELSAET_ID = $regelsæt_id
	                                        UNION
	                                        select distinct a.AKTIVITET_KODE
	                                        from AKTIVITET_REGEL_GENEREL arg
	                                        inner join AKTIVITET a
	                                        on arg.AKTIVITET_ID = a.AKTIVITET_ID
	                                        where REGELSAET_ID = $regelsæt_id)"
        
        $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
        
        $result | foreach {
            $_.AKTIVITET_KODE = $_.AKTIVITET_KODE.replace($InitialFra,$InitialTil)
            $_.TEKST = $_.TEKST.replace($InitialFra,$InitialTil)
            
            if(!([string]::IsNullOrEmpty($_.TAS_KONTO))){
                $_.TAS_KONTO = $_.TAS_KONTO.replace($InitialFra,$InitialTil)
            }
            
            
            if(!([string]::IsNullOrEmpty($_.TAS_KONTO_TEKST))){
                $_.TAS_KONTO_TEKST = $_.TAS_KONTO_TEKST.replace($InitialFra,$InitialTil)
            }
        }


        Write-Host Retrieved the Activities:
        foreach($item in $result){
            Write-Host $item.AKTIVITET_KODE - $item.TEKST -ForegroundColor Green
        }

        $result | Export-Csv -Path $path/Activities.csv -NoTypeInformation -Encoding UTF8
        Write-Host Created Activities.csv file `r`n

        Write-Host Retrieved $result.Count Activities -ForegroundColor Green 
    
        Write-Host `r`n "Outputs exported in the given path $path" `r`n

        $connection.Close()
        Write-Host "SQL connection Closed"

    }catch{
        Write-Error $_
    }

}


