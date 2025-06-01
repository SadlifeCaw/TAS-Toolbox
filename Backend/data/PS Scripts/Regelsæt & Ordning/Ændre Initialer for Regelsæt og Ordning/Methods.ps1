#Author : Nevethan Alagaratnam

$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1"
###############################################
#########      METHODS         ################
###############################################

#region Methods

#Install the SqlServer module 
function Preprocess {    
    if(!(Get-module -ListAvailable -name sqlserver)){

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
    $text.Replace("'","&#39;")
}

function DoesZipExist{
    $DoesZipExist = Test-Path -Path $path\data.zip -PathType leaf

    if($DoesZipExist){
        Expand-Archive -Path $path\data.zip -Force -DestinationPath $path
    }
}

function DoesFileExist{
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [Alias('FileName')]
        [string] $file
    )

    $path = Test-Path -Path $path\$file -PathType Leaf

    if($path){
        return $true
    }else{
        Write-Error Could not find $file 
        return $false
    }
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
            
            if([string]::IsNullOrEmpty($SQLresult)){
                Write-Error -Message "Couldnt find the RegelSæt ID. It is either because the variable is empty or the regelsæt name does not exist" -Category InvalidArgument 
                return $false
            }else{
                return $SQLresult.itemArray
         
            } 
        }

   }catch{
        Write-Error $_    
   }
    
}

function GetRegelsætId{
    if($RegelsætName -ne ''){
        $regelsæt_id = DoesRegelsætExist
        return $regelsæt_id
    }else{
        Write-Host Regelsæt name is empty -ForegroundColor Red
        return $false
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
            
            if([string]::IsNullOrEmpty($SQLresult)){
                Write-Error -Message "Couldnt find the 'Ordning'. Check Ordning name" -Category InvalidArgument
                return $false
            }else{
                return $SQLresult.itemArray
         
            } 
        }

   }catch{
        Write-Error $_    
   }

}

function GetOrdningId{
    if($ordning -ne ''){
        $ordning_id = DoesOrdningExist
        return $ordning_id
    }else{
        Write-Host Ordning name is empty -ForegroundColor Red
        return $false
    }
}

$ordning_id = GetOrdningId

#Checking if the Status already exists
function DoesStatusExist{
    
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [Alias('StatusCode')]
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
            
            if([string]::IsNullOrEmpty($SQLresult)){
                return $false
            }else{
                return $true
            } 
        }

   }catch{
       Write-Error $_   
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
            
            if([string]::IsNullOrEmpty($SQLresult)){
                return $false
            }else{
                Write-Host TAS KONTO "'$KONTO'" Already exists. -ForegroundColor Green
                return $true
            }
        }

    }catch{
        Write-Error $_
    }
}

#Checking if the activity exist
function DoesActivityExist{
    
    Param(
            [Parameter(Mandatory=$true, Position=0)]
            [Alias('ActivityCode')]
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
            
            if([string]::IsNullOrEmpty($SQLresult)){
                return $false
            }else{
                Write-Host Activity "'$code'" already exists -ForegroundColor Green
                return $true
            } 
        }
    }catch{
        Write-Error $_
    }
}

#Checking if the activities already exist in PROD and retrieving the Acitivity id.
function GetActivityId{
    
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [Alias('ActivityCode')]
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
            
            if([string]::IsNullOrEmpty($SQLresult)){
                Write-Host Activity "'$Activity_code'" doesnt exist -ForegroundColor Red
                return ''
            }else{
                return $SQLresult.itemArray
            } 
        }

    }catch{
        Write-Error $_
    }
}

function GetActivityCode{
    param(
        [parameter(Mandatory=$true,Position=0)]
        [Alias('ActivityId')]
        [string] $activity_id
    )

    $query = "SELECT AKTIVITET_KODE
                FROM AKTIVITET
                WHERE AKTIVITET_ID = $activity_id"

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult)){
                Write-Host Activity "'$activity_id'" doesnt exist -ForegroundColor Red
                return ''
            }else{
                return $SQLresult.itemArray
            } 
        }

    }catch{
        Write-Error $_
    }


}

function DoesActivityHaveKonto{
    Param(
        [parameter(Mandatory=$true,Position=0)]
        [Alias('ActivityId')]
        [String] $Activity_id,

        [parameter(Mandatory=$true,Position=1)]
        [String] $Konto
    )

    $query = "select AKTIVITET_ID
                from AKTIVITET_KONTO
                where AKTIVITET_ID = $Activity_id AND TAS_KONTO = '$Konto'"
    
    $Activity_code = GetActivityCode -ActivityId $Activity_id

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult)){
                return $false
            }else{
                Write-Host Activity code "'$Activity_code'" already has an activity konto "'$Konto'" bound to it. -ForegroundColor Green
                return $true
            }
        }

    }catch{
        Write-Error $_
    }
}

function DoesActivityHaveNotification{
    Param(
        [parameter(Mandatory=$true,Position=0)]
        [Alias('ActivityId')]
        [String] $AKTIVITET_ID
    )

    $query = "select AKTIVITET_ID
                from AKTIVITET_EMAIL
                where AKTIVITET_ID = $AKTIVITET_ID"
    
    $code = GetActivityCode -ActivityId $AKTIVITET_ID

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult)){
                Write-Host Activity "'$code'" does not have Notification. -ForegroundColor Yellow
                return $false
            }else{
                Write-Host Notification for Activity "'$code'" Already exists. -ForegroundColor Green
                return $true
            }
        }

    }catch{
        Write-Error $_
    }
}

function DoesActivitySecurityPermissionExist{
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [Alias('ActivityId')]
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
            
            if([string]::IsNullOrEmpty($SQLresult)){
                return $false
            }else{
                Write-Host Activity security permission for ActivityID $SQLresult.AKTIVITET_ID and name $NAME already exists -ForegroundColor Green
                return $true 
            } 
        }

    }catch{
        Write-Error $_
    }
}

function IsActivityStatusNeutral{
    
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [Alias('ActivityId')]
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
            
            if([string]::IsNullOrEmpty($SQLresult)){
                return $false

            }else{
                return $true
            } 
        }

    }catch{
        Write-Error $_
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
            
            if(!([string]::IsNullOrEmpty($SQLresult))){
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
        [string] $OPEN_ACTIVITY_CODE,

        [Parameter(Mandatory=$true, Position=2)]
        [string] $CLOSE_ACTIVITY_CODE
    )
        
    if($CLOSE_ACTIVITY_CODE -eq ''){
        $query = "select FORSYSTEM_ID
                from ORDNING_FORSYSTEM
                where FORSYSTEM_ID = $FORSYSTEM_ID AND ORDNING = '$ordning' AND AKTIVITET_ID = $OPEN_ACTIVITY AND LUK_AKTIVITET_ID IS NULL"
    }else{
        $query = "select FORSYSTEM_ID
                from ORDNING_FORSYSTEM
                where FORSYSTEM_ID = $FORSYSTEM_ID AND ORDNING = '$ordning' AND AKTIVITET_ID = $OPEN_ACTIVITY AND LUK_AKTIVITET_ID = $CLOSE_ACTIVITY"
    }
    
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
           
            if([string]::IsNullOrEmpty($SQLresult)){
                return $false
            }else{
                Write-Host Schema Setting already exists : `r`n Schema name: $FORSYSTEM_NAME `r`n Open Activity: $OPEN_ACTIVITY_CODE `r`n Close Activity: $CLOSE_ACTIVITY_CODE `r`n -ForegroundColor Green
                return $true
            } 
        }

    }catch{
        Write-Error $_
    }
    
}


function DoesSchemaSettingExist2{
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $FORSYSTEM_NAME,
        
        [Parameter(Mandatory=$true, Position=1)]
        [string] $OPEN_ACTIVITY,

        [Parameter(Mandatory=$true, Position=2)]
        [string] $CLOSE_ACTIVITY,

        [Parameter(Mandatory=$true, Position=3)]
        [string] $PARM,

        [Parameter(Mandatory=$true, Position=4)]
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
        [string] $ActionOnCompletion
    )
    
    $FORSYSTEM_ID = GetSchemaID -SchemaName $FORSYSTEM_NAME
    
    if($CLOSE_ACTIVITY -eq 'NULL'){
        $query = "select top 1 FORSYSTEM_ID
                from ORDNING_FORSYSTEM
                where FORSYSTEM_ID = $FORSYSTEM_ID AND ORDNING = '$ordning' AND AKTIVITET_ID = $OPEN_ACTIVITY AND LUK_AKTIVITET_ID IS NULL"
    }else{
        $query = "select top 1 FORSYSTEM_ID
                from ORDNING_FORSYSTEM
                where FORSYSTEM_ID = $FORSYSTEM_ID AND ORDNING = '$ordning' AND AKTIVITET_ID = $OPEN_ACTIVITY AND LUK_AKTIVITET_ID = $CLOSE_ACTIVITY"
    }
     
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                                    
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
             
            if([string]::IsNullOrEmpty($SQLresult)){
                return $false
            }else{
                $list_forsystem_id = $SQLresult.itemArray
                
                if($PARM -eq 'NULL'){
                    if($OBJEKT -eq ''){
                        #Objekt is null
                        $ordning_param = "select ORDNING_FORSYSTEM_ID
                                            from ORDNING_FORSYSTEM_PARM
                                            WHERE ORDNING = '$ordning' AND FORSYSTEM_ID = $list_forsystem_id AND AKTIVITET_ID = $OPEN_ACTIVITY PARM IS NULL AND OBJEKT IS NULL"

                    }else{
                        #objekt is not null
                        $ordning_param = "select ORDNING_FORSYSTEM_ID
                                            from ORDNING_FORSYSTEM_PARM
                                            WHERE ORDNING = '$ordning' AND FORSYSTEM_ID = $list_forsystem_id AND AKTIVITET_ID = $OPEN_ACTIVITY AND PARM IS NULL AND OBJEKT IS NOT NULL"
                    }
                }else{
                    if($OBJEKT -eq ''){
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
                
                if([string]::IsNullOrEmpty($sql_parm)){
                    return $false
                }else{
                                         
                    if($OBJEKT -eq 'nv_DataSync'){
                        if($sql_parm.itemArray.Count -gt 1){ 
                            $list_ordning_forsystem_id = $sql_parm.itemArray -join ','
                        }else{
                            $list_ordning_forsystem_id = $sql_parm.itemArray
                        } 

 
                        if($NextActivityId -eq 'NULL'){
                            $sql_dataSync = "select SchemeFrontSystemId
                                                from DATASYNC_JOB_SETUP
                                                where SchemeFrontSystemID IN ($list_ordning_forsystem_id) AND NextActivityId IS NULL AND ApproveActivity = $ApproveActivity AND NumberOfRespiteDays = $NumberOfRespiteDays AND CaselogState = $CaseLogState AND ActionOnCompletion = $ActionOnCompletion"
                        }else{
                            $sql_dataSync = "select SchemeFrontSystemId
                                                from DATASYNC_JOB_SETUP
                                                where SchemeFrontSystemID IN ($list_ordning_forsystem_id) AND NextActivityId IS NOT NULL AND ApproveActivity = $ApproveActivity AND NumberOfRespiteDays = $NumberOfRespiteDays AND CaselogState = $CaseLogState AND ActionOnCompletion = $ActionOnCompletion"
                        }
                        
                        $sql_datasync = Invoke-Sqlcmd -Query $sql_dataSync -ConnectionString $connectionstring -MaxCharLength 9999999
                    
                        if([string]::IsNullOrEmpty($sql_datasync)){
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
        [string] $CLOSE_ACTIVITY
    )

    if($CLOSE_ACTIVITY -eq 'NULL'){
        $query="select top 1 ORDNING_FORSYSTEM_ID
                from ORDNING_FORSYSTEM
                where FORSYSTEM_ID = $FORSYSTEM_ID AND ORDNING = '$ORDNING' AND AKTIVITET_ID = $OPEN_ACTIVITY AND LUK_AKTIVITET_ID IS NULL
                order by TIMESTAMP desc"
    }else{
        $query="select top 1 ORDNING_FORSYSTEM_ID
                from ORDNING_FORSYSTEM
                where FORSYSTEM_ID = $FORSYSTEM_ID AND ORDNING = '$ORDNING' AND AKTIVITET_ID = $OPEN_ACTIVITY AND LUK_AKTIVITET_ID = $CLOSE_ACTIVITY
                order by TIMESTAMP desc"
    }
         
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult)){
                Write-Host couldnt find an id -ForegroundColor Red
                return 0 
            }else{
                return $SQLresult.itemArray
            }
        }

    }catch{
        Write-Error $_
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
            
            if([string]::IsNullOrEmpty($SQLresult)){
                return $false
            }else{
                Write-Host "'$ORDNING_FORSYSTEM_ID'" Already exists -ForegroundColor Green
                return $true
            } 
        }

    }catch{
        Write-Error $_
    }

}

function IsActivityBoundToRegelSæt{
    
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [Alias('ActivityCode')]
        [String] $CODE
    )
    
    $id =  GetActivityId -ActivityCode $CODE

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
            
            if([string]::IsNullOrEmpty($SQLresult)){
                $isStatusNeutral = IsActivityStatusNeutral -ActivityId $id

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
        Write-Error $_
    }
}

function DoesActivityQuotaExist{
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [String] $ID
    )

    $query = "select Id
                from ActivityQuota
                where Id = $ID"
    
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
    }
}

#Checking if the status in 'Mulig Status' exists
function DoesRegelsætStatus{ 
    
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [Alias('StatusCode')]
        [string] $status
    )

    $exist = DoesStatusExist -StatusCode $status

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
            
            if([string]::IsNullOrEmpty($SQLresult)){
                return $false
            }else{
                Write-Host Status "'$status'" already exists -ForegroundColor Green
                return $true
            } 
        }

    }catch{
        Write-Error $_
    }
}

#Checking if the activities in 'mulig status' already exist
function DoesMuligStatusActivityExist{
   Param(
        [Parameter(Mandatory=$true,position=0)]
        [Alias('ActivityCode')]
        [string] $activity_kode,
        
        [Parameter(Mandatory=$true,position=1)]
        [Alias('StatusFra')]
        [string] $status_fra,
        
        [Parameter(Mandatory=$true,position=2)]
        [Alias('StatusTil')]
        [string] $status_til   
   )

   $activity_id = GetActivityId -ActivityCode $activity_kode
    
   try{
        
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){
            
            $query = "SELECT *
                        FROM AKTIVITET_REGEL
                        where AKTIVITET_ID = $activity_id AND REGELSAET_ID = $regelsæt_id AND STATUS_FRA = '$status_fra' AND STATUS_TIL = '$status_til'"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            $ar_id = $SQLresult.AKTIVITET_REGEL_ID

            if([string]::IsNullOrEmpty($SQLresult)){
                return $false
            }else{
                Write-Host Mulig Status "'$ar_id'" already exists -ForegroundColor Green
                return $true
            } 
        }

    }catch{
        Write-Error $_
    }
}

#Does Schema Exist
function DoesSchemaExist{
    
    Param(
        [parameter(Mandatory=$true, Position=0)]
        [Alias('SchemaName')]
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
            
            if([string]::IsNullOrEmpty($SQLresult)){
                Write-Host Schema '$Schema_Name' does not exist. -ForegroundColor Red
                return $false
            }else{
                return $true
            } 
        }

    }catch{
        Write-Error $_
    }
}

#IsActivityLinkedToOrdning
function IsActivityLinkedToOrdning{
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Code
    )

    try{
        
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){
            
            $query = "select AKTIVITET_KODE
                        from AKTIVITET 
                        where AKTIVITET_ID IN(
	                        select AKTIVITET_ID
	                        from AKTIVITET_REGEL where REGELSAET_ID IN (select REGELSAET_ID
	                        from ORDNING_PROJEKTTYPE
	                        where ORDNING = '$ordning') and AKTIVITET_KODE IN('$Code')
	                        union 
	                        select AKTIVITET_ID
	                        from AKTIVITET_REGEL_GENEREL
	                        where REGELSAET_ID IN (select REGELSAET_ID
	                        from ORDNING_PROJEKTTYPE
	                        where ORDNING = '$ordning') and AKTIVITET_KODE IN('$Code'))"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult)){
                Write-Host Activity $Code is not linked to ordning $ordning. -ForegroundColor Yellow
                return $false
            }else{
                return $true
            } 
        }

    }catch{
        Write-Error $_
    }
}

function GetProjectTypes{
    try{
        
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){
            
            $query = "select PROJEKTTYPE
                        from ORDNING_PROJEKTTYPE
                        where ORDNING = '$ordning'"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
           
            return $SQLresult
        }

    }catch{
        Write-Error $_
    }
}

function IsActivityLinkedToProjectType{
    
    Param(
        [parameter(Mandatory=$true,Position=0)]
        [Alias('ActivityCode')]
        [string] $activityCode
    )


    try{
        
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){
            
            $query = "select AKTIVITET_ID
                        from AKTIVITET 
                        where AKTIVITET_KODE = '$activityCode' AND AKTIVITET_ID IN (select AKTIVITET_ID
                        from AKTIVITET_REGEL
                        where REGELSAET_ID = (select REGELSAET_ID
                        from ORDNING_PROJEKTTYPE
                        where ORDNING = '$ordning' AND PROJEKTTYPE = '$projectType')
                        UNION
                        select AKTIVITET_ID
                        from AKTIVITET_REGEL_GENEREL
                        where REGELSAET_ID = (select REGELSAET_ID
                        from ORDNING_PROJEKTTYPE
                        where ORDNING = '$ordning' AND PROJEKTTYPE = '$projectType'))"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
           
            if([string]::IsNullOrEmpty($SQLresult)){
                return $false
            }else{
                return $true
            } 
        }

    }catch{
        Write-Error $_
    }
}

function DoesWordSettingExist{
    Param(
        [parameter(Mandatory=$true, Position=0)]
        [string] $Code,

        [parameter(Mandatory=$true, Position=1)]
        [string] $ProjectType,

        [parameter(Mandatory=$true, Position=2)]
        [string] $Title,

        [parameter(Mandatory=$true, Position=3)]
        [string] $Describe
    )

    $activity_id = GetActivityId -ActivityCode $Code

    try{
        
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){
            
            $query = "select DOC_ID
                    from WORD_DOC_STD
                    where AKTIVITET_ID = $activity_id AND ORDNING = '$ordning' AND PROJEKTTYPE = '$ProjectType' and DOC_TITLE = '$Title' and DOC_DESCRIBE = '$Describe'"
                    
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult)){
                return $false
            }else{
                Write-Host Word setting Already exists. -ForegroundColor Green
                Write-Host Activity Code : $Code -ForegroundColor Green
                Write-Host ProjectType : $ProjectType -ForegroundColor Green
                Write-Host Title : $Title -ForegroundColor Green
                Write-Host Ordning : $ordning -ForegroundColor Green
                Write-Host Describe : $Describe -ForegroundColor Green `r`n
                return $true
            } 
        }

    }catch{
        Write-Error $_
    }
}


function Title{
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Title
    )

    Write-Host '###############'
    Write-Host  $Title 
    Write-Host '###############'
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

#endregion