#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'

if($regelsæt_id -ne $false){
    
    DoesZipExist #Does data.zip exists

    $testPath = DoesFileExist -FileName MuligStatus.csv

    if($testPath){

        Title -Title 'Set-MuligStatus'

        $muligStatus_csv = Import-Csv -Path $path/MuligStatus.csv
    
        $insert = "" #The query which inserts the new data into the table

        $status = @()
        $status_activities = @()

        ##################################
        ############ STATUS ##############
        ##################################

        foreach($ms in $muligStatus_csv){
            $s = $ms.STATUS
            $status_type = isNull($ms.STATUS_TYPE)
            $budgetbeskyt = isNull_int($ms.BUDGETBESKYT)
            $udbt_tilladt = isNull($ms.UDBT_TILBAGEHOLDT_TILLADT)
       
            $doesStatusExist = DoesStatusExist -StatusCode $s
        
            if($doesStatusExist){
                $exist = DoesRegelsætStatus -StatusCode $s

                if(!$exist){
                    $insert = $insert + "($regelsæt_id, '$s', $status_type, $budgetbeskyt, $udbt_tilladt), `r`n"

                    $status += $s
                }
            }else{
                Write-Host Skipping status "'"$s"'" -ForegroundColor Yellow
            }

            
        }
    
        #Making the query for execution.
        if(!([string]::IsNullOrEmpty($insert))){
            $insert = "INSERT INTO REGELSAET_STATUS (REGELSAET_ID,STATUS,STATUS_TYPE,BUDGETBESKYT,UDBT_TILBAGEHOLDT_TILLADT) `r`n" + 'VALUES' + $insert
            $insert = $insert.Substring(0,$insert.Length-4) #remove the last ','
            $insert = $insert.Replace('System.Xml.XmlElement', 'null')
        
            Invoke-Sqlcmd -Query $insert -ConnectionString $connectionstring -MaxCharLength $maxCharLength
            Write-Host Inserted $status.Length Status. They are the following: -ForegroundColor Green
            $status | ForEach-Object -Process {Write-Host $_ }
            Write-Host 
        }
    
        
        ##################################
        ########## Activities ############
        ##################################

        $muligStatus_activites = Import-Csv -Path $path/MuligStatusActivities.csv

        $insert_activities = "" #The query which inserts the new data into the table

        foreach($msa in $muligStatus_activites){
            $aktivitet_kode = $msa.AKTIVITET_KODE
            $status_fra = $msa.STATUS_FRA
            $status_til = $msa.STATUS_TIL
            $aktivitet_fortryd_kode =  $msa.AKTIVITET_FORTRYD_ID
        
            #Check if the activity and status' exist
            $check_aktivitet = DoesActivityExist -ActivityCode $aktivitet_kode
            $check_status_fra = DoesStatusExist -StatusCode $status_fra
            $check_status_til = DoesStatusExist -StatusCode $status_til

            if(!([string]::IsNullOrEmpty($aktivitet_fortryd_kode))){
                $aktivitet_fortryd_kode = DoesActivityExist -ActivityCode $aktivitet_fortryd_kode
            }else{
                $aktivitet_fortryd_id = isNull_int($aktivitet_fortryd_id)
            }

            if($check_aktivitet -ne $false -or $check_status_fra -ne $false -or $check_status_til -ne $false){
                $exits_mulig_status_activity = DoesMuligStatusActivityExist -ActivityCode $aktivitet_kode -StatusFra $status_fra -StatusTil $status_til
            
                if(!$exits_mulig_status_activity){
                    #Replace the AKTIVITET_ID with the new one in PROD using the AKTIVITET_KODE. If it exists
            
                    $aktivitet_id_regel = GetActivityId -ActivityCode $aktivitet_kode          

                    if(!([string]::IsNullOrEmpty($aktivitet_id_regel))){
                         #Generate new GUID
                        $layout_guid = New-Guid

                        $insert_activities = "INSERT INTO AKTIVITET_REGEL(AKTIVITET_ID,REGELSAET_ID,STATUS_FRA,STATUS_TIL,AKTIVITET_FORTRYD_ID,LAYOUT_GUID) `r`n" + "VALUES($aktivitet_id_regel, $regelsæt_id, '$status_fra', '$status_til', $aktivitet_fortryd_id , '$layout_guid')"
                       
                        Invoke-Sqlcmd -Query $insert_activities -ConnectionString $connectionstring -MaxCharLength $maxCharLength

                        $status_activities += $aktivitet_kode
                    }  
                }                
            }
        }
              
            
        $insert_activities = $insert_activities.Substring(0,$insert_activities.Length-4) #remove the last ','
            
        Write-Host Inserted $status_activities.Length Activities. -ForegroundColor Green
        $status_activities | ForEach-Object -Process {Write-Host $_}
        Write-Host 
        
    }  
}


