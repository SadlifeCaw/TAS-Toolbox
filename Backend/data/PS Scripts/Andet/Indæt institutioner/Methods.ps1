#Author : Nevethan Alagaratnam

$path = $PWD.Path #Split-Path $psise.CurrentFile.FullPath
. "C:\Users\P-X153157\Desktop\Indæt institutioner\Configs.ps1"
###############################################
#########      METHODS         ################
###############################################

#region Methods

$RegelsætName = '' # The name of the regelsæt you want to transfer

$ordning = '' #Ordningen du vil arbejde med.

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
        Write-Error -Message "Couldnt find file '$file'" -Category ObjectNotFound
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
            
            if($SQLresult -eq $null){
                Write-Error -Message "Couldnt find the RegelSæt ID. It is either because the variable is empty or the regelsæt name does not exist" -Category InvalidArgument 
                return $false
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
        return $false
    }
}

#$regelsæt_id = GetRegelsætID

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
                return $false
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
        return $false
    }
}

#$ordning_id = GetOrdningId

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
            
            if($SQLresult -eq $null){
                return $false
            }else{
                Write-Host Activity "'$code'" already exists -ForegroundColor Green
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
        [Alias('ActivityCode')]
        [String] $Activity_code,

        [parameter(Mandatory=$true,Position=1)]
        [String] $Konto
    )

    $query = "select AKTIVITET_ID
                from AKTIVITET_KONTO
                where AKTIVITET_ID = $Activity_code AND TAS_KONTO = '$Konto'"

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                return $false
            }else{
                Write-Host Activity code "'$Activity_code'" Already has an Activity konto "'$Konto'" bound to it. -ForegroundColor Green
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
        [Alias('ActivityId')]
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
                Write-Host ´Activity id "'$AKTIVITET_ID'" does not have Notification. -ForegroundColor Yellow
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
            
            if($SQLresult.itemArray -ne ''){
                return $SQLresult.itemArray
            }else{
                Write-Host Couldn"'"t find new FORSYSTEM_ID from name "'$schema_name'" -ForegroundColor Red
                return ''
            }
        }

    }catch{
        $_
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
    
    $FORSYSTEM_ID = GetSchemaID -SchemaName $FORSYSTEM_NAME
    $OPEN_ACTIVITY = GetActivityId -ActivityCode $OPEN_ACTIVITY_CODE
    
    if($CLOSE_ACTIVITY_CODE -eq 'NULL'){
        $query = "select *
                from ORDNING_FORSYSTEM
                where FORSYSTEM_ID = $FORSYSTEM_ID AND ORDNING = '$ordning' AND AKTIVITET_ID = $OPEN_ACTIVITY AND LUK_AKTIVITET_ID IS NULL"
    }else{
        $CLOSE_ACTIVITY = GetActivityId -ActivityCode $CLOSE_ACTIVITY_CODE

        $query = "select *
                from ORDNING_FORSYSTEM
                where FORSYSTEM_ID = $FORSYSTEM_ID AND ORDNING = '$ordning' AND AKTIVITET_ID = $OPEN_ACTIVITY AND LUK_AKTIVITET_ID = $CLOSE_ACTIVITY"
    }
    
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
           
            if($SQLresult.itemArray -eq $null){
                return $false
            }else{
                Write-Host Schema Setting already exists : `r`n Schema name: $FORSYSTEM_NAME `r`n Open Activity: $OPEN_ACTIVITY_CODE `r`n Close Activity: $CLOSE_ACTIVITY_CODE `r`n -ForegroundColor Green
                return $true
            } 
        }

    }catch{
        $_
    }
    break
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

    $query = ""

    $CLOSE_ACTIVITY = isNull_int($CLOSE_ACTIVITY)

    if($CLOSE_ACTIVITY -eq 'NULL'){
        $query="select ORDNING_FORSYSTEM_ID
                from ORDNING_FORSYSTEM
                where FORSYSTEM_ID = $FORSYSTEM_ID AND ORDNING = '$ORDNING' AND AKTIVITET_ID = $OPEN_ACTIVITY AND LUK_AKTIVITET_ID IS NULL"
    }else{
        $query="select ORDNING_FORSYSTEM_ID
                from ORDNING_FORSYSTEM
                where FORSYSTEM_ID = $FORSYSTEM_ID AND ORDNING = '$ORDNING' AND AKTIVITET_ID = $OPEN_ACTIVITY AND LUK_AKTIVITET_ID = $CLOSE_ACTIVITY"
    }
       
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
            
            if($SQLresult -eq $null){
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
        $_
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

#Does institution exist
function DoesInstitutionExist{
    
    Param(
        [parameter(Mandatory=$true, Position=0)]
        [Alias('InstitutionId')]
        [string] $Institution_Id
    )

    try{
        
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){
            
            $query = "select *
                        from FORSYSTEM
                        where TEKST = '$Institution_Id'"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                return $false
            }else{
                Write-Host Schema '$Institution_Id' already exist. -ForegroundColor Red
                return $true
            } 
        }

    }catch{
        $_
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
            
            if($SQLresult -eq $null){
                Write-Host Activity $Code is not linked to ordning $ordning. -ForegroundColor Yellow
                return $false
            }else{
                return $true
            } 
        }

    }catch{
        $_
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
           
            if($SQLresult -eq $null){
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
            
            if($SQLresult -eq $null){
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
        $_
    }
}

function DoesDynamicAutoFieldExist{
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [string] $AutoTextName,

        [Parameter(Mandatory=$true,Position=1)]
        [string] $SchemaName,

        [Parameter(Mandatory=$true,Position=2)]
        [string] $DataFieldSetLabel,

        [Parameter(Mandatory=$true,Position=3)]
        [string] $DataFieldLabel
    
    )

    try{

        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        $schemaId = GetSchemaID -SchemaName $SchemaName

        $query = "select Id
						    from DynamicFrontsystemAutoTextField 
						    where AutoTextName = $AutoTextName AND FrontSystemId = $schemaId AND DataFieldSetLabel = $DataFieldSetLabel AND DataFieldLabel = $DataFieldLabel"
        
        
        $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
        if($SQLresult -eq $null){
            return $false
        }else{
            Write-Host DynamicAutoTextField already exists: -ForegroundColor Yellow
            Write-Host AutoTextName: $AutoTextName -ForegroundColor Yellow
            Write-Host FrontSystemId: $schemaId -ForegroundColor Yellow
            Write-Host DataFieldSetLabel: $DataFieldSetLabel -ForegroundColor Yellow
            Write-Host DataFieldLabel: $DataFieldLabel -ForegroundColor Yellow `r`n
            return $true
        }
        
        $connection.Close()
    }catch{
        Write-Error $_
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

#endregion