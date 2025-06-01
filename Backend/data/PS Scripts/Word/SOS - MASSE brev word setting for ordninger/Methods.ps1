#Author : Nevethan Alagaratnam

###############################################
#########      METHODS         ################
###############################################

#region Methods

$RegelsætName = '' 

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

$ordning_id = GetOrdningId

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
           
            return $SQLresult.PROJEKTTYPE
        }

    }catch{
        Write-Error $_
    }
}

function IsProjectTypeBoundToOrdning{
    $projectTypes = GetProjectTypes

    if($projectTypes.Contains($projektType)){
        return $true
    }else{
        Write-Host Project Type "'$projektType'" is not bound to Ordning "'$ordning'" -ForegroundColor Yellow
        return $false
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
        [Alias('ActivityCode')]
        [string] $Code,

        [parameter(Mandatory=$true, Position=1)]
        [string] $ProjectType,

        [parameter(Mandatory=$true, Position=2)]
        [string] $Title,

        [parameter(Mandatory=$false, Position=3)]
        [string] $Describe

    )

    $activity_id = GetActivityId -ActivityCode $Code

    try{
        
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){
            
            if($PSBoundParameters.ContainsKey('Describe')){
                if($ProjectType -eq 'NULL'){
                    $query = "select DOC_ID
                        from WORD_DOC_STD
                        where AKTIVITET_ID = $activity_id AND ORDNING = '$ordning' AND PROJEKTTYPE IS NULL and DOC_TITLE = '$Title' and DOC_DESCRIBE = '$Describe'"
                }else{
                    $query = "select DOC_ID
                        from WORD_DOC_STD
                        where AKTIVITET_ID = $activity_id AND ORDNING = '$ordning' AND PROJEKTTYPE = $ProjectType and DOC_TITLE = '$Title' and DOC_DESCRIBE = '$Describe'"
                }
            }else{
                if($ProjectType -eq 'NULL'){
                    $query = "select DOC_ID
                    from WORD_DOC_STD
                    where AKTIVITET_ID = $activity_id AND ORDNING = '$ordning' AND PROJEKTTYPE IS NULL and DOC_TITLE = '$Title' and DOC_DESCRIBE IS NULL"
                }else{
                    $query = "select DOC_ID
                        from WORD_DOC_STD
                        where AKTIVITET_ID = $activity_id AND ORDNING = '$ordning' AND PROJEKTTYPE = $ProjectType and DOC_TITLE = '$Title' and DOC_DESCRIBE IS NULL"
                }
            }
             
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                Write-Host Inserting Word setting. -ForegroundColor Green
                Write-Host Activity Code : $Code -ForegroundColor Green
                Write-Host ProjectType : $ProjectType -ForegroundColor Green
                Write-Host Title : $Title -ForegroundColor Green
                Write-Host Ordning : $ordning -ForegroundColor Green
                Write-Host Describe : $Describe -ForegroundColor Green `r`n
                return $false
            }else{
                Write-Host Updating Word setting. -ForegroundColor Yellow
                Write-Host Activity Code : $Code -ForegroundColor Yellow
                Write-Host ProjectType : $ProjectType -ForegroundColor Yellow
                Write-Host Title : $Title -ForegroundColor Yellow
                Write-Host Ordning : $ordning -ForegroundColor Yellow
                Write-Host Describe : $Describe -ForegroundColor Yellow `r`n
                return $true
            } 
        }

    }catch{
        $_
    }
}

function GetDocId{
    Param(
        [parameter(Mandatory=$true, Position=0)]
        [Alias('ActivityCode')]
        [string] $Code,

        [parameter(Mandatory=$true, Position=1)]
        [string] $ProjectType,

        [parameter(Mandatory=$true, Position=2)]
        [string] $Title,

        [parameter(Mandatory=$false, Position=3)]
        [string] $Describe
    )

    $activity_id = GetActivityId -ActivityCode $Code

    try{

        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){
            if($PSBoundParameters.ContainsKey('Describe')){
                if($ProjectType -eq 'NULL'){
                    $query = "select DOC_ID
                        from WORD_DOC_STD
                        where AKTIVITET_ID = $activity_id AND ORDNING = '$ordning' AND PROJEKTTYPE IS NULL and DOC_TITLE = '$Title' and DOC_DESCRIBE = '$Describe'"
                }else{
                    $query = "select DOC_ID
                        from WORD_DOC_STD
                        where AKTIVITET_ID = $activity_id AND ORDNING = '$ordning' AND PROJEKTTYPE = $ProjectType and DOC_TITLE = '$Title' and DOC_DESCRIBE = '$Describe'"
                }                
            }else{
                if($ProjectType -eq 'NULL'){
                    $query = "select DOC_ID
                        from WORD_DOC_STD
                        where AKTIVITET_ID = $activity_id AND ORDNING = '$ordning' AND PROJEKTTYPE IS NULL and DOC_TITLE = '$Title' and DOC_DESCRIBE IS NULL"
                }else{
                    $query = "select DOC_ID
                        from WORD_DOC_STD
                        where AKTIVITET_ID = $activity_id AND ORDNING = '$ordning' AND PROJEKTTYPE = $ProjectType and DOC_TITLE = '$Title' and DOC_DESCRIBE IS NULL"
                }
            }
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            return $SQLresult.DOC_ID
        }
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

function sqlList([Array] $list){
    $l = @()
    
    foreach($el in $list){
        $l += "'$el'"
    }

    return $l -join ','
}

#endregion