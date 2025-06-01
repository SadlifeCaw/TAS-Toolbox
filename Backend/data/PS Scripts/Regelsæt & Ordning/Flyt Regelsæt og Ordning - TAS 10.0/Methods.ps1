#Author : Nevethan Alagaratnam

###############################################
#########      METHODS         ################
###############################################
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs and Methods


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

function ReplaceParenthesis{
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [string] $Text
    )
    
    $Text = $Text.Replace('(','').Replace(')','')
   
    return $Text

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
        Write-Error "Could not find $file" 
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return $false
            }else{
                return $true
            }
        }

    }catch{
        Write-Error $_
    }
}


function DoesFinansKontoExist{
    Param(
        [Parameter(Mandatory=$true,position=0)]
        [Alias('TasKonto')]
        [string] $konto,
        
        [Parameter(Mandatory=$true,position=1)]
        [Alias('ScrKonto')]
        [string] $scr,

        [Parameter(Mandatory=$true,position=2)]
        [Alias('DEB_KRE_FINANS')]
        [string] $dkf,

        [Parameter(Mandatory=$true,position=3)]
        [string] $Procent,

        [Parameter(Mandatory=$true,position=4)]
        [string] $DEB_KRE,

        [Parameter(Mandatory=$true,position=5)]
        [string] $Modkonto,

        [Parameter(Mandatory=$true,position=6)]
        [string] $Year,

        [Parameter(Mandatory=$true,position=7)]
        [string] $KonteringGruppe,

        [Parameter(Mandatory=$true,position=8)]
        [string] $Ramme,
        
        [Parameter(Mandatory=$true,position=9)]
        [string] $Udligning,

        [Parameter(Mandatory=$true,position=10)]
        [Alias('TransaktionsType')]
        [string] $transaktion,
        
        [Parameter(Mandatory=$true,position=11)]
        [string] $Fond

    )
    <#
    if($transaktion -ne 'NULL'){
        $transaktion = "TRANSAKTIONSTYPE = $transaktion"
    }else{
        $transaktion = NullQuery -Column TRANSAKTIONSTYPE -Value $transaktion
        $transaktion = "( $transaktion "+ "OR TRANSAKTIONSTYPE = '')"
    }#>

    if($Fond -ne 'NULL'){
        $Fond = "FOND = $Fond"
    }else{
        $Fond = NullOrEmptyQuery -Column FOND -Value $Fond
    }
    

    $Year = NullQuery -Column 'YEAR' -Value $Year
    
    $Procent = $Procent.Replace(',','.')
    
    if($KonteringGruppe -ne 'NULL'){
        $doesKontoGroupExist = GetKontoGruppe -Value $KonteringGruppe

        if(!$doesKontoGroupExist){
            $KonteringGruppe = ''
        }
    }

    $KonteringGruppe = NullQuery -Column 'RG_KONTERING_GRUPPE' -Value $KonteringGruppe
    
    $transaktion = NullOrEmptyQuery -Column 'TRANSAKTIONSTYPE' -Value $transaktion
    
    $query = "select RG_SCR_KONTOPLAN_ID
                from RG_SCR_KONTOPLAN
                where SCR_KONTO = $scr AND TAS_KONTO = $konto AND DEB_KRE_FINANS = $dkf AND PROCENT = $Procent AND DEB_KRE = $DEB_KRE AND MODKONTO = $Modkonto AND $Year AND $KonteringGruppe AND RAMME = $Ramme AND UDLIGNING = $Udligning AND $transaktion AND $Fond"
    
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return $false
            }else{
                return $true
            } 
    }
}catch{
        Write-Error $_
    }

}

function GetKontoGruppe {

    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [string] $Value
    )

    $query = "select RG_KONTERING_GRUPPE_ID
                from RG_KONTERING_GRUPPE
                where RG_KONTERING_GRUPPE_ID = $Value"

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return $false
            }else{
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return $false
            }else{
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return $false
            }else{
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return $false
            }else{
                return $true
            }
        }

    }catch{
        Write-Error $_
    }
}


function DoesSecurityNameExist{
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Name
    )

    $query = "select NAME
                from SECURITY_USERS
                where NAME = '$Name'"
    
    try{
        
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                Write-Host Security user "$Name" doesnt exist -ForegroundColor Yellow
                return $false
            }else{
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return $false
            }else{
                Write-Host Activity security permission already exists: -ForegroundColor Yellow
                Write-Host ActivityID : $SQLresult.AKTIVITET_ID
                write-host Security : $NAME
                Write-Host 
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
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
        [string] $TjeklisteId
    )
   
    $FORSYSTEM_ID = GetSchemaID -SchemaName $FORSYSTEM_NAME
    
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
                                            WHERE ORDNING = '$ordning' AND FORSYSTEM_ID = $list_forsystem_id AND AKTIVITET_ID = $OPEN_ACTIVITY AND PARM IS NULL AND OBJEKT = $OBJEKT"
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
                                            WHERE ORDNING = '$ordning' AND FORSYSTEM_ID = $list_forsystem_id AND AKTIVITET_ID = $OPEN_ACTIVITY AND PARM = $PARM AND OBJEKT = $OBJEKT "
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
                                                where SchemeFrontSystemID IN ($list_ordning_forsystem_id) AND NextActivityId IS NULL AND ApproveActivity = $ApproveActivity AND NumberOfRespiteDays = $NumberOfRespiteDays AND CaselogState = $CaseLogState AND ActionOnCompletion = $ActionOnCompletion"
                        }else{
                            $sql_dataSync = "select SchemeFrontSystemId
                                                from DATASYNC_JOB_SETUP
                                                where SchemeFrontSystemID IN ($list_ordning_forsystem_id) AND NextActivityId IS NOT NULL AND ApproveActivity = $ApproveActivity AND NumberOfRespiteDays = $NumberOfRespiteDays AND CaselogState = $CaseLogState AND ActionOnCompletion = $ActionOnCompletion"
                        }
                        

                        $sql_datasync = Invoke-Sqlcmd -Query $sql_dataSync -ConnectionString $connectionstring -MaxCharLength 9999999
                    
                        if([string]::IsNullOrEmpty($sql_datasync.itemarray)){
                            return $false
                        }else{
                            Write-Host Schema Setting already exists : `r`n Schema name: $FORSYSTEM_NAME `r`n Open Activity: $OPEN_ACTIVITY `r`n Close Activity: $CLOSE_ACTIVITY `r`n NextActivityId: $NextActivityId `r`n ApproveActivity: $ApproveActivity `r`n NumberOfRespiteDays: $NumberOfRespiteDays `r`n CaseLogState: $CaseLogState `r`n ActionOnCompletion: $ActionOnCompletion `r`n -ForegroundColor Yellow
                            return $true
                        }
                    }else{
                        Write-Host Schema Setting already exists : `r`n Schema name: $FORSYSTEM_NAME `r`n Open Activity: $OPEN_ACTIVITY `r`n Close Activity: $CLOSE_ACTIVITY `r`n Parameter: $PARM `r`n Objekt: $OBJEKT `r`n -ForegroundColor Yellow
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return $false
            }else{
                Write-Host "'$ORDNING_FORSYSTEM_ID'" Already exists -ForegroundColor Yellow
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return $false
            }else{
                return $true
            }
        }

    }catch{
        Write-Error $_
    }
}

function GetActivityQuota{
    Param(
        [parameter(Mandatory=$true, Position = 0)]
        [string] $id
    )

    $query = "select Id
                from ActivityQuota
                where Id = $id"

                #Write-Host $query
    
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();

        if($connection.State -eq "Open"){
                        
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return ''
            }else{
                return $SQLresult.itemArray
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

    <#
    $exist = DoesStatusExist -StatusCode $status

    if($exist -eq $false){
        return $false
    }
    #>
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){
            
            $query = "SELECT *
                        FROM REGELSAET_STATUS
                        WHERE STATUS = '$status' AND REGELSAET_ID = $regelsæt_id"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return $false
            }else{
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
            
            $query = "SELECT AKTIVITET_REGEL_ID
                        FROM AKTIVITET_REGEL
                        where AKTIVITET_ID = $activity_id AND REGELSAET_ID = $regelsæt_id AND STATUS_FRA = '$status_fra' AND STATUS_TIL = '$status_til'"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return $false
            }else{
                $code = GetActivityCode -activity_id $activity_id

                Write-Host Mulig Status already exists -ForegroundColor Yellow
                Write-Host Activity Code : $code
                Write-Host Status Fra : $status_fra
                Write-Host Status Til : $status_til
                Write-Host 
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                Write-Host Schema "'$Schema_Name'" does not exist. -ForegroundColor Red
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
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
           
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
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
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return $false
            }else{
                Write-Host Word setting Already exists. -ForegroundColor Green
                Write-Host Activity Code : $Code -ForegroundColor 
                Write-Host ProjectType : $ProjectType -ForegroundColor 
                Write-Host Title : $Title -ForegroundColor 
                Write-Host Ordning : $ordning -ForegroundColor 
                Write-Host Describe : $Describe -ForegroundColor  `r`n
                return $true
            } 
        }

    }catch{
        Write-Error $_
    }
}

function DoesTjeklistIdExist{
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [string] $TjeklisteId
    )

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){
            $query = "select TJEKLISTEDATA_ID
                        from TJEKLISTEDATA
                        where TJEKLISTEDATA_TJEKLISTEID = $TjeklisteId"

            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return $false
            }else{
                return $true
            }
        }
    }catch{
        Write-Error $_
    }
}

function GetTjeklisteDataId{
    Param(
        [Parameter(Mandatory=$true,Position = 0)]
        [string] $TjeklisteId
    )

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){
            $query = "select TJEKLISTEDATA_ID
                        from TJEKLISTEDATA
                        where TJEKLISTEDATA_TJEKLISTEID = $TjeklisteId"

            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            return $SQLresult.itemarray
        }
    }catch{
        Write-Error $_
    }


}

function DoesBudgetExist{

    Param(
        [parameter(Mandatory=$true, Position=0)]
        [string] $ID
    )

    $query = "select BUDGET_OMRAADE_ID
                from BUDGET_OMRAADE
                where BUDGET_OMRAADE_ID = '$ID'"

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){

            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return $false
                Write-Host BUDGET_OMRAADE_ID : $BUDGET_OMRAADE_ID does not exist -ForegroundColor Yellow
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

function DoesInitialExist{

    Param(
        [parameter(Mandatory=$true,Position=0)]
        [string] $Initial
    )

    $query = "select NAME
                from SECURITY_USERS
                where NAME = '$Initial'"

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){

            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return $false
                Write-Host Initial : $initial does not exist -ForegroundColor Yellow
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

function DoesSagsbemyndigetSettingExist{

    Param(
        [Parameter(Mandatory=$true, Position = 0)]
        [string] $Initial,

        [Parameter(Mandatory=$true, Position = 1)]
        [string] $BudgetOmraade,

        [Parameter(Mandatory=$true, Position = 2)]
        [string] $Max,

        [Parameter(Mandatory=$true, Position = 3)]
        [string] $ramme1,

        [Parameter(Mandatory=$true, Position = 4)]
        [string] $ramme2
    )

    $Max = NullQuery -Column MAX_BELOEB -Value $Max
    $ramme1 = NullQuery -Column RAMME1_MAX_BELOEB -Value $ramme1
    $ramme2 = NullQuery -Column RAMME2_MAX_BELOEB -Value $ramme2


    $query = "Select INITIALER
                from ORDNING_BEMYNDIGET
                where ORDNING = '$ordning' AND INITIALER = '$Initial' AND BUDGET_OMRAADE_ID = '$BudgetOmraade' AND $Max AND $ramme1 AND $ramme2"
                
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){

            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
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


function DoesKontorExist{

    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Kontor,
        
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Ejer 
    )

    $query = "Select KONTOR
                from ORDNING_KONTOR
                where ORDNING = '$ordning' AND KONTOR = $Kontor AND EJER = '$Ejer'"
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){

            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return $false
            }else{
                Write-Host Kontor setting already exist -ForegroundColor Yellow
                Write-Host KONTOR : $Kontor 
                Write-Host EJER : $Ejer
                Write-Host ORDNING : $ordning
                return $true
           }
        }
    }catch{
        Write-Error $_
    }finally{
        $connection.Close()
    }
}

function DoesOmkostningArtExist{

    Param(
        [parameter(Mandatory=$true, Position=0)]
        [string] $OmkostningsArt,

        [parameter(Mandatory=$true, Position=1)]
        [string] $Tekst,

        [parameter(Mandatory=$true, Position=2)]
        [string] $SystemArt,

        [parameter(Mandatory=$true, Position=3)]
        [string] $Niveu,

        [parameter(Mandatory=$true, Position=4)]
        [string] $Aktiv
    
    )

    $SysArt = NullOrEmptyQuery -Column SYSTEM_ART -Value $SystemArt

    $Niv = NullQuery -Column NIVEAU -Value $Niveu

    $query = "select OMKOSTNING_ART
                from OMKOSTNINGSART
                where OMKOSTNING_ART = '$OmkostningsArt' AND TEKST = '$Tekst' AND $SysArt AND $Niv AND AKTIV = '$Aktiv'"


    try{

        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){

            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
                        
            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                #creating the element
                
                if($Niveu -eq 'NULL'){
                    $queryOmk = "INSERT INTO OMKOSTNINGSART(OMKOSTNING_ART, TEKST, SYSTEM_ART, NIVEAU, AKTIV) `r`n VALUES('$OmkostningsArt','$Tekst',$SystemArt, NULL, '$Aktiv')"
                
                }else{
                    $queryOmk = "INSERT INTO OMKOSTNINGSART(OMKOSTNING_ART, TEKST, SYSTEM_ART, NIVEAU, AKTIV) `r`n VALUES('$OmkostningsArt','$Tekst',$SystemArt, $Niv, '$Aktiv')"
                }
                #Write-Host $queryOmk
                Invoke-Sqlcmd -Query $queryOmk -ConnectionString $connectionstring -MaxCharLength 9999999
                
                Write-Host Created new Omkostning art:
                Write-Host OMKOSTNING_ART : $OmkostningsArt -ForegroundColor Green
                Write-Host TEKST : $Tekst -ForegroundColor Green

            }
            
            $doesOmkOrdningExist = "select OMKOSTNING_ART
                                        from ORDNING_OMK
                                        where ORDNING = '$ordning' AND OMKOSTNING_ART = '$OmkostningsArt'" 

            $result = Invoke-Sqlcmd -Query $doesOmkOrdningExist -ConnectionString $connectionstring -MaxCharLength 9999999
            Write-Host $result
            if([string]::IsNullOrEmpty($result.itemarray)){
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


function DoesEmneOrdExist{

    Param(
        [parameter(Mandatory=$true, Position=0)]
        [string] $Value
    )

    $query = "select EMNE_ORD
        from ORDNING_EMNEORD
        where ORDNING = '$ordning' AND EMNE_ORD = '$Value'"

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){

            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999

            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
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

function CreateRapportGruppe{

    Param(
        [parameter(Mandatory=$true, Position=0)]
        [string] $Tekst,

        [parameter(Mandatory=$true, Position=1)]
        [string] $Aktiv
    )

    $query = "select RAPPORTGRUPPE_ID
                from RAPPORTGRUPPE
                where TEKST = '$Tekst' AND AKTIV = '$Aktiv'"
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999

            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                $queryRapport = "INSERT INTO RAPPORTGRUPPE(RAPPORTGRUPPE_ID, TEKST, AKTIV) `r`n VALUES('$Tekst','$Aktiv')"

                Invoke-Sqlcmd -Query $queryRapport -ConnectionString $connectionstring -MaxCharLength 9999999
                
                Write-Host Created new Rapport gruppe:
                Write-Host TEKST : $Tekst -ForegroundColor Green
                Write-Host ORDNING : $ordning -ForegroundColor Green
                Write-Host
            }
        }
    }catch{
        Write-Error $_
    }finally{
        $connection.Close()
    }


}

function GetRapportGruppeId{

    Param(
        [parameter(Mandatory=$true, Position=0)]
        [string] $Value
    )

    $query = "select RAPPORTGRUPPE_ID
                from RAPPORTGRUPPE
                where TEKST = '$Value'"

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999

            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                Write-Error Something went wrong with the rapport gruppe - $Value
            }else{
                return $SQLresult.itemarray
            }
        }
    }catch{
        Write-Error $_
    }finally{
        $connection.Close()
    }
}


function DoesRapportGruppeSettingExist{

    Param(
        [parameter(Mandatory=$true, Position=0)]
        [string] $Id,

        [parameter(Mandatory=$true, Position=1)]
        [string] $Tekst,

        [parameter(Mandatory=$true, Position=2)]
        [string] $Obl,

        [parameter(Mandatory=$true, Position=3)]
        [string] $Sort,

        [parameter(Mandatory=$true, Position=4)]
        [string] $Aktiv,

        [parameter(Mandatory=$true, Position=5)]
        [string] $Kategori
    )

    $Sort = NullOrEmptyQuery -Column SORT -Value $Sort

    $Kategori = NullOrEmptyQuery -Column KATEGORI -Value $Kategori
    

    $query = "select RAPPORTGRUPPE_ID
                from ORDNING_RAPPORTGRUPPE
                where ORDNING = '$ordning' AND RAPPORTGRUPPE_ID = $Id AND OBLIGATORISK = '$Obl' AND $Sort AND AKTIV = '$Aktiv' AND $Kategori"

    
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){

            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999

            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
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


function DoesStatistikKodeExist{

    Param(
        [parameter(Mandatory=$true, Position=0)]
        [string] $Kode,

        [parameter(Mandatory=$false, Position=1)]
        [string] $Sort

    )

    $Sort = isNull_int($Sort)

    $Sort = NullQueryInt -Column SORT -Value $Sort

    $query = "select STATISTIK_KODE
                from ORDNING_STATISTIK
                where ORDNING = '$ordning' AND STATISTIK_KODE = '$Kode' AND $Sort"
    
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){

            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999

            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
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

function DoesBudgetOmraadeExist{

    Param(
        [Paramter(mandatory=$true,position=0)]
        [string] $Budget
    )

    $query = "select BUDGET_OMRAADE
                from BUDGET_OMRAADE
                where ORDNING = '$ordning' ANd BUDGET_OMRAADE = '$Budget'" 


    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){

            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999

            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
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

function GetLastestLbnrBudgetOmraade{

    $query = "select top 1 BUDGET_OMRAADE_LBN
                from BUDGET_OMRAADE
                where ORDNING = '$ordning'
                order by BUDGET_OMRAADE_LBN desc" 

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){

            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999

            if([string]::IsNullOrEmpty($SQLresult.itemarray)){
                return 0
            }else{
                return $SQLresult.itemarray
            }
        }
    }catch{
        Write-Error $_
    }finally{
        $connection.Close()
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

function NullQuery{
    Param(
        [parameter(Mandatory=$true,position=0)]
        [string] $Column,

        [parameter(Mandatory=$true,position=1)]
        [string] $Value
    )    

    if([string]::IsNullOrEmpty($Value) -or ($Value -eq 'NULL')){
        $str = "$Column IS NULL"
    }else{
        $str = "$Column = " + "'$Value'"
    }
    
    return $str

}

function NullQueryInt{
    Param(
        [parameter(Mandatory=$true,position=0)]
        [string] $Column,

        [parameter(Mandatory=$true,position=1)]
        [string] $Value
    )    

    if([string]::IsNullOrEmpty($Value) -or ($Value -eq 'NULL')){
        $str = "$Column IS NULL"
    }else{
        $str = "$Column = " + "$Value"
    }
    
    return $str

}

function NullOrEmptyQuery{
    Param(
            [parameter(Mandatory=$true,position=0)]
            [string] $Column,

            [parameter(Mandatory=$true,position=1)]
            [string] $Value
        )    

        if([string]::IsNullOrEmpty($Value) -or ($Value -eq 'NULL')){
            $str = "($Column IS NULL OR $Column = '')"
        }else{
            $str = "$Column = " + "'$Value'"
        }
    
        return $str

}

#endregion