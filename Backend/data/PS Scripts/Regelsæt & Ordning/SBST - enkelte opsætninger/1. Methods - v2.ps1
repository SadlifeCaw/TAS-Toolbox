#Author : Nevethan Alagaratnam

#Install the SqlServer module 
function Preprocess {    
    if((Get-InstalledModule -Name SqlServer) -eq $null){

        Set-ExecutionPolicy -ExecutionPolicy Unrestricted
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    
        Write-Host "Installing Module 'SqlServer'."
        Install-Module -Name SqlServer
    }
}

#Get the current location of the script
function Get-ScriptDirectory {
    if ($psise) {
        Split-Path $psise.CurrentFile.FullPath
    }
    else {
        $global:PSScriptRoot
    }
}

#Get the path of the current script
$path = Get-ScriptDirectory # Path to where the script is located.

#replace the character "'" to escape it in the SQL management studio.
function Replace-EscapeCharacters([String] $text){
    $text.Replace("'","' + char(39) + '")
}

#Get RegelSæt_ID per Regelsæt name
function DoesRegelsætExist{
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){
            $query = "select REGELSAET_ID
                        from REGELSAET
                        where TEKST = '$RegelsætName'"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                Write-Error -Message "Couldnt find the RegelSæt ID. It is either because the variable is empty or the ordning name does not exist " -Category InvalidArgument 
                break
            }else{
                return $SQLresult.itemArray
         
            } 
        }

   }catch{
        $_    
   }
    
}

function GetRegelsætId{
    if($RegelsætName -ne ''){
        $regelsæt_id = DoesRegelsætExist
        return $regelsæt_id
    }else{
        Write-Host Regelsæt name is empty -ForegroundColor Red
        return ''
    }
}

$regelsæt_id = GetRegelsætID

function DoesOrdningExist{
    
    $query = "select ORDNING
                from ORDNING
                where ORDNING = '$ordning'"    

     try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                Write-Error -Message "Couldnt find the 'Ordning'. Check Ordning name" -Category InvalidArgument
                break
            }else{
                return $SQLresult.itemArray
         
            } 
        }

   }catch{
        $_    
   }

}

function GetOrdningId{
    if($ordning -ne ''){
        $ordning_id = DoesOrdningExist
        return $ordning_id
    }else{
        Write-Host Ordning name is empty -ForegroundColor Red
        return ''
    }
}

$ordning_id = GetOrdningId

#Checking if the Status already exists
function DoesStatusExist{
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $status
    )

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){
            $query = "SELECT *
                        FROM STATUS
                        WHERE STATUS = '$status'"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                return $false
            }else{
                return $true
            } 
        }

   }catch{
       $_   
   }
}

function DoesTasKontoExist{
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [String] $KONTO
    )

    $query = "select *
                    from RG_TAS_KONTO
                    where TAS_KONTO = '$KONTO'"

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                return $false
            }else{
                Write-Host TAS KONTO "'$KONTO'" Already exists. -ForegroundColor Green
                return $true
            }
        }

    }catch{
        $_
    }
}

#Checking if the activity exist
function DoesActivityExist{
    Param(
            [Parameter(Mandatory=$true, Position=0)]
            [string] $code   
        )

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){
            $query = "SELECT *
                        FROM AKTIVITET
                        WHERE AKTIVITET_KODE = '$code'"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                return $false
            }else{
                Write-Host Activity '$code' already exists -ForegroundColor Green
                return $true
            } 
        }
    }catch{
        $_
    }
}

#Checking if the activities already exist in PROD and retrieving the Acitivity id.
function GetActivityId{
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Activity_code
    )
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
            
            $query = "SELECT AKTIVITET_ID
                        FROM AKTIVITET
                        WHERE AKTIVITET_KODE = '$Activity_code'"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                Write-Host Activity "'$Activity_code'" doesnt exist -ForegroundColor Red
                return ''
            }else{
                return $SQLresult.itemArray
            } 
        }

    }catch{
        $_
    }
}

function DoesActivityHaveKonto{
    Param(
        [parameter(Mandatory=$true,Position=0)]
        [String] $Activity_code,

        [parameter(Mandatory=$true,Position=1)]
        [String] $KONTO
    )

    $query = "select AKTIVITET_ID
                from AKTIVITET_KONTO
                where AKTIVITET_ID = $Activity_code AND TAS_KONTO = '$KONTO'"

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                return $false
            }else{
                Write-Host Activity code "'$Activity_code'" Already has an Activity konto "'$KONTO'" bound to it. -ForegroundColor Green
                return $true
            }
        }

    }catch{
        $_
    }
}

function DoesActivityHaveNotification{
    Param(
        [parameter(Mandatory=$true,Position=0)]
        [String] $AKTIVITET_ID
    )

    $query = "select AKTIVITET_ID
                from AKTIVITET_EMAIL
                where AKTIVITET_ID = $AKTIVITET_ID "

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                return $false
            }else{
                Write-Host Notification for Activity id "'$AKTIVITET_ID'" Already exists. -ForegroundColor Green
                return $true
            }
        }

    }catch{
        $_
    }
}

function DoesActivitySecurityPermissionExist{
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [string] $ACTIVITY_ID,

        [Parameter(Mandatory=$true,Position=1)]
        [string] $NAME
    )

    $query = "select AKTIVITET_ID
                from AKTIVITET_SECURITY
                where AKTIVITET_ID = $ACTIVITY_ID AND NAME = '$NAME'"
    
    try{
        
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){
            
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                return $false
            }else{
                Write-Host Activity security permission for activity_id "'$SQLresult.AKTIVITET_ID'" and name "'$SQLresult.NAME'" already exists -ForegroundColor Green
                return $true 
            } 
        }

    }catch{
        $_
    }
}

function IsActivityStatusNeutral{
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [String] $Activity_id
    )

    $query = "select AKTIVITET_ID
                from AKTIVITET_REGEL_GENEREL 
                where REGELSAET_ID = $regelsæt_id AND AKTIVITET_ID = $Activity_id"

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                return $false

            }else{
                return $true
            } 
        }

    }catch{
        $_
    }
}

function GetSchemaID{
    
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [Alias('SchemaName')]
        [string] $schema_name
    )
  
    $query = "select FORSYSTEM_ID
                from FORSYSTEM
                where TEKST = '$schema_name'"

    try{
        
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        $connection.Open();
        
        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if(!([string]::IsNullOrEmpty($SQLresult.itemarray))){
                return $SQLresult.itemArray
            }else{
                Write-Host Couldn"'"t find new FORSYSTEM_ID from name "'$schema_name'" -ForegroundColor Red
                return ''
            }
        }

    }catch{
        Write-Error $_
    }
}

function DoesSchemaSettingExist{
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $FORSYSTEM_NAME,
        
        [Parameter(Mandatory=$true, Position=1)]
        [string] $OPEN_ACTIVITY,

        [Parameter(Mandatory=$true, Position=2)]
        [string] $CLOSE_ACTIVITY,

        [Parameter(Mandatory=$true, Position=3)]
        [string] $PARM,

        [Parameter(Mandatory=$false, Position=4)]
        [string] $OBJEKT,

        [Parameter(Mandatory=$false, Position=5)]
        [string] $NextActivityId,

        [Parameter(Mandatory=$false, Position=6)]
        [string] $ApproveActivity,

        [Parameter(Mandatory=$false, Position=7)]
        [string] $NumberOfRespiteDays,

        [Parameter(Mandatory=$false, Position=8)]
        [string] $CaseLogState,

        [Parameter(Mandatory=$false, Position=9)]
        [string] $ActionOnCompletion,

        [Parameter(Mandatory=$false, Position=10)]
        [string] $TjeklisteId,

        [Parameter(Mandatory=$false, Position=11)]
        [string] $ordning

    )

    $OPEN_ACTIVITY = GetActivityId -Activity_code $OPEN_ACTIVITY
       
    $FORSYSTEM_ID = GetSchemaID -SchemaName $FORSYSTEM_NAME
    $ApproveActivity = TrueOrFalse($ApproveActivity)
    
    if($CLOSE_ACTIVITY -eq 'NULL'){
        if(![string]::IsNullOrEmpty($TjeklisteId)){
            $query = "select top 1 FORSYSTEM_ID
                from ORDNING_FORSYSTEM
                where FORSYSTEM_ID = $FORSYSTEM_ID AND ORDNING = '$ordning' AND AKTIVITET_ID = $OPEN_ACTIVITY AND LUK_AKTIVITET_ID IS NULL AND TJEKLISTEDATA_TJEKLISTEID = $TjeklisteId"
        }else{
            $query = "select top 1 FORSYSTEM_ID
                from ORDNING_FORSYSTEM
                where FORSYSTEM_ID = $FORSYSTEM_ID AND ORDNING = '$ordning' AND AKTIVITET_ID = $OPEN_ACTIVITY AND LUK_AKTIVITET_ID IS NULL"
        }
        
    }else{

        $CLOSE_ACTIVITY = GetActivityId -Activity_code $CLOSE_ACTIVITY

        if(![string]::IsNullOrEmpty($TjeklisteId)){
            $query = "select top 1 FORSYSTEM_ID
                    from ORDNING_FORSYSTEM
                    where FORSYSTEM_ID = $FORSYSTEM_ID AND ORDNING = '$ordning' AND AKTIVITET_ID = $OPEN_ACTIVITY AND LUK_AKTIVITET_ID = $CLOSE_ACTIVITY AND TJEKLISTEDATA_TJEKLISTEID = $TjeklisteId"
        }else{
            $query = "select top 1 FORSYSTEM_ID
                    from ORDNING_FORSYSTEM
                    where FORSYSTEM_ID = $FORSYSTEM_ID AND ORDNING = '$ordning' AND AKTIVITET_ID = $OPEN_ACTIVITY AND LUK_AKTIVITET_ID = $CLOSE_ACTIVITY"
        }
    }
    
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                                    
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
           
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return $false
            }else{
                $list_forsystem_id = $SQLresult.itemArray
               
                if($PARM -eq 'NULL'){
                    if($OBJEKT -eq 'NULL'){
                        #Objekt is null
                        $ordning_param = "select ORDNING_FORSYSTEM_ID
                                            from ORDNING_FORSYSTEM_PARM
                                            WHERE ORDNING = '$ordning' AND FORSYSTEM_ID = $list_forsystem_id AND AKTIVITET_ID = $OPEN_ACTIVITY AND PARM IS NULL AND OBJEKT IS NULL"

                    }else{
                        #objekt is not null
                        $ordning_param = "select ORDNING_FORSYSTEM_ID
                                            from ORDNING_FORSYSTEM_PARM
                                            WHERE ORDNING = '$ordning' AND FORSYSTEM_ID = $list_forsystem_id AND AKTIVITET_ID = $OPEN_ACTIVITY AND PARM IS NULL AND OBJEKT IS NOT NULL"
                    }
                }else{
                    if($OBJEKT -eq 'NULL'){
                        #Objekt is null
                        $ordning_param = "select ORDNING_FORSYSTEM_ID
                                            from ORDNING_FORSYSTEM_PARM
                                            WHERE ORDNING = '$ordning' AND FORSYSTEM_ID = $list_forsystem_id AND AKTIVITET_ID = $OPEN_ACTIVITY AND PARM = $PARM AND OBJEKT IS NULL"
                    }else{
                        #objekt is not null
                        $ordning_param = "select ORDNING_FORSYSTEM_ID
                                            from ORDNING_FORSYSTEM_PARM
                                            WHERE ORDNING = '$ordning' AND FORSYSTEM_ID = $list_forsystem_id AND AKTIVITET_ID = $OPEN_ACTIVITY AND PARM = $PARM AND OBJEKT IS NOT NULL "
                    }
                }
               
                $sql_parm = Invoke-Sqlcmd -Query $ordning_param -ConnectionString $connectionstring -MaxCharLength 9999999
                
                if([string]::IsNullOrEmpty($sql_parm.itemarray)){
                    return $false
                }else{                   
                    if($OBJEKT -eq "'nv_DataSync'"){
                        if($sql_parm.itemArray.Count -gt 1){ 
                            $list_ordning_forsystem_id = $sql_parm.itemArray -join ','
                        }else{
                            $list_ordning_forsystem_id = $sql_parm.itemArray
                        } 

 
                        if($NextActivityId -eq 'NULL'){
                            $sql_dataSync = "select SchemeFrontSystemId
                                                from DATASYNC_JOB_SETUP
                                                where SchemeFrontSystemID IN ($list_ordning_forsystem_id) AND NextActivityId IS NULL AND ApproveActivity = $ApproveActivity AND NumberOfRespiteDays = $NumberOfRespiteDays AND CaselogState = '$CaseLogState' AND ActionOnCompletion = $ActionOnCompletion"
                        }else{
                            $sql_dataSync = "select SchemeFrontSystemId
                                                from DATASYNC_JOB_SETUP
                                                where SchemeFrontSystemID IN ($list_ordning_forsystem_id) AND NextActivityId IS NOT NULL AND ApproveActivity = $ApproveActivity AND NumberOfRespiteDays = $NumberOfRespiteDays AND CaselogState = '$CaseLogState' AND ActionOnCompletion = $ActionOnCompletion"
                        }
                        
                        $sql_datasync = Invoke-Sqlcmd -Query $sql_dataSync -ConnectionString $connectionstring -MaxCharLength 9999999
                    
                        if([string]::IsNullOrEmpty($sql_datasync.itemarray)){
                            return $false
                        }else{
                            Write-Host Schema Setting already exists : `r`n Schema name: $FORSYSTEM_NAME `r`n Open Activity: $OPEN_ACTIVITY `r`n Close Activity: $CLOSE_ACTIVITY `r`n NextActivityId: $NextActivityId `r`n ApproveActivity: $ApproveActivity `r`n NumberOfRespiteDays: $NumberOfRespiteDays `r`n CaseLogState: $CaseLogState `r`n ActionOnCompletion: $ActionOnCompletion `r`n -ForegroundColor Green
                            return $true
                        }
                    }else{
                        Write-Host Schema Setting already exists : `r`n Schema name: $FORSYSTEM_NAME `r`n Open Activity: $OPEN_ACTIVITY `r`n Close Activity: $CLOSE_ACTIVITY `r`n Parameter: $PARM `r`n Objekt: $OBJEKT `r`n -ForegroundColor Green
                        return $true
                    }
                }
            }
             
        }

    }catch{
        Write-Error $_
    }
}


function GetOrdningForsystemId{
    Param(
        [parameter(Mandatory=$true,Position=0)]
        [int] $FORSYSTEM_ID,

        [Parameter(Mandatory=$true, Position=1)]
        [string] $OPEN_ACTIVITY,

        [Parameter(Mandatory=$true, Position=2)]
        [string] $CLOSE_ACTIVITY,

        [Parameter(Mandatory=$true, Position=3)]
        [string] $ORDNING
    )

    $query = ""

    if($CLOSE_ACTIVITY -eq 'NULL'){
        $query="select ORDNING_FORSYSTEM_ID
                from ORDNING_FORSYSTEM
                where FORSYSTEM_ID = $FORSYSTEM_ID AND ORDNING = '$ORDNING' AND AKTIVITET_ID = $OPEN_ACTIVITY AND LUK_AKTIVITET_ID IS NULL AND ORDNING = '$ORDNING'"
    }else{
        $query="select ORDNING_FORSYSTEM_ID
                from ORDNING_FORSYSTEM
                where FORSYSTEM_ID = $FORSYSTEM_ID AND ORDNING = '$ORDNING' AND AKTIVITET_ID = $OPEN_ACTIVITY AND LUK_AKTIVITET_ID = $CLOSE_ACTIVITY AND ORDNING = '$ORDNING'"
    }
       write-host $query
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                return ''
            }else{
                return $SQLresult.itemArray[0]
            } 
        }

    }catch{
        $_
    }
}

function DoesSchemaParameterExist{
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [int] $ORDNING_FORSYSTEM_ID
    )

    $query = "select FORSYSTEM_ID
                from ORDNING_FORSYSTEM_PARM
                where ORDNING_FORSYSTEM_ID = $ORDNING_FORSYSTEM_ID"
    
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                return $false
            }else{
                Write-Host "'$ORDNING_FORSYSTEM_ID'" Already exists -ForegroundColor Green
                return $true
            } 
        }

    }catch{
        $_
    }

}

function IsActivityBoundToRegelSæt{
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [String] $CODE
    )
    
    $id =  GetActivityId -Activity_code $CODE

    if($id -eq ''){
        return $false
    }

    $query = "select AKTIVITET_ID
                from AKTIVITET_REGEL 
                where AKTIVITET_ID = $id AND REGELSAET_ID = $regelsæt_id"
    
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                $isStatusNeutral = IsActivityStatusNeutral -Activity_id $id

                if($isStatusNeutral -eq $false){
                    Write-Host Activity "'$CODE'" is not bound to the regelsæt "'$RegelsætName'" -ForegroundColor Red
                    return $false
                }else{
                    return $true
                }
            }else{
                return $true
            } 
        }

    }catch{
        $_
    }
}

function isActivityBoundToOrdning{

    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [string] $Ordning,

        [Parameter(Mandatory=$false, Position=1)]
        [string] $Code
    )

    $query = "select distinct a1.AKTIVITET_KODE
                from AKTIVITET_REGEL ar
                left join AKTIVITET a1
                on ar.AKTIVITET_ID = a1.AKTIVITET_ID
                where REGELSAET_ID IN (select REGELSAET_ID
                from ORDNING_PROJEKTTYPE
                where ORDNING = '$Ordning') AND a1.AKTIVITET_KODE = '$Code'
                union
                select distinct a2.AKTIVITET_KODE
                from AKTIVITET_REGEL_GENEREL arg
                left join AKTIVITET a2
                on arg.AKTIVITET_ID = a2.AKTIVITET_ID
                where REGELSAET_ID IN(select REGELSAET_ID
                from ORDNING_PROJEKTTYPE
                where ORDNING = '$Ordning') AND a2.AKTIVITET_KODE = '$Code'"
    
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring        
        
        $connection.Open();

        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult)){
                return $false  
            }else{
                return $true
            } 
        }
        
    }catch{
        Write-Error $_
    }finally{
        $connection.Close()
    }


}

function DoesActivityQuotaExist{
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [String] $ID
    )

    $query = "select Id
                from ActivityQuota
                where Id = '$ID'"

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                return $false
            }else{
                return $true
            }
        }

    }catch{
        $_
    }
}

#Checking if the status in 'Mulig Status' exists
function DoesRegelsætStatus{
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $status
    )

    $exist = DoesStatusExist -status $status

    if($exist -eq $false){
        return $false
    }
    
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){
            
            $query = "SELECT *
                        FROM REGELSAET_STATUS
                        WHERE STATUS = '$status' AND REGELSAET_ID = $regelsæt_id"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                return $false
            }else{
                Write-Host Status "'$status'" already exists -ForegroundColor Green
                return $true
            } 
        }

    }catch{
        $_
    }
}

#Checking if the activities in 'mulig status' already exist
function DoesMuligStatusActivityExist{
   Param(
        [Parameter(Mandatory=$true,position=0)]
        [string] $activity_kode,
        
        [Parameter(Mandatory=$true,position=2)]
        [string] $status_fra,
        
        [Parameter(Mandatory=$true,position=3)]
        [string] $status_til   
   )

   $activity_id = GetActivityId -Activity_code $activity_kode
    
   try{
        
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){
            
            $query = "SELECT *
                        FROM AKTIVITET_REGEL
                        where AKTIVITET_ID = $activity_id AND REGELSAET_ID = $regelsæt_id AND STATUS_FRA = '$status_fra' AND STATUS_TIL = '$status_til'"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            $ar_id = $SQLresult.AKTIVITET_REGEL_ID

            if($SQLresult -eq $null){
                return $false
            }else{
                Write-Host Mulig Status "'$ar_id'" already exists -ForegroundColor Green
                return $true
            } 
        }

    }catch{
        $_
    }
}

#Does Schema Exist
function DoesSchemaExist{
    Param(
        [parameter(Mandatory=$true, Position=0)]
        [string] $Schema_Name
    )

    try{
        
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){
            
            $query = "select *
                        from FORSYSTEM
                        where TEKST = '$Schema_Name'"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                Write-Host Schema '$Schema_Name' does not exist. -ForegroundColor Red
                return $false
            }else{
                return $true
            } 
        }

    }catch{
        $_
    }



}



function TrueOrFalse([String] $n){
    if($n -eq "True"){
        return 1
    }elseif($n -eq "False"){
        return 0
    }
}

function isNull([String] $input_string){

    if($input_string -eq ''){
        return 'NULL'
    }else{
        return "'$input_string'"
    }

}

function isNull_int([String] $input_int){

    if($input_int -eq ''){
        return 'NULL'
    }else{
        return $input_int
    }

}