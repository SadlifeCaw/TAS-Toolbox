#Author : Nevethan Alagaratnam

###############################################
#########      METHODS         ################
###############################################
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs and Methods

#region Methods 
$maxCharLength = 2147483647 #Invoking a sqlcmd has a Default char length limit of 4000 characters(It doesnt get everything). So, put the limit to 

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

#replace the character "'" and Zero-Width Space to HTML encoding such that it does not cause problems in the SQL server management studio.
function Replace-InvalidFormat{
    Param(
        [parameter(Mandatory=$true,Position=0)]
        [Alias('SchemaTemplate')]
        [string] $sTemplate
    )
    
    #$sTemplate = $sTemplate.Replace("'","'+char(39)+'")
    $sTemplate = $sTemplate.Replace("'","&#39;")
    $sTemplate = $sTemplate.Replace("​", "&#8203;")
    return $sTemplate
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
                Write-Host Schema "'$Schema_Name'" does not exist. -ForegroundColor Yellow
                return $false
            }else{
                return $true
            } 
        }

    }catch{
        $_
    }
}

function GetBackupTemplate{
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [int] $SchemaId
    )

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
        $connection.Open();
        
        if($connection.State -eq "Open"){
            $query = "select FrontSystemTemplateXml
                        from DynamicFrontSystemTemplate
                        where FrontSystemId = $SchemaId"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if(!(Test-Path -Path $path\templateBackups)){
                New-Item $path\templateBackups -ItemType Directory
            }

            Set-Content -Path $path\templateBackups\templateXml_$SchemaId.xml -Value $SQLresult.FrontSystemTemplateXml 
            Write-Host Retrieved xml template for backup : $SchemaId -ForegroundColor Yellow

        }
    }catch{
        Write-Error $_
    }
}

function GetViewGroupId{
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [string] $ViewGroup
    )

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        $connection.Open();

        if($connection.State -eq "Open"){
            $query = "select Id
                        from ViewGroup
                        where Title = '$ViewGroup'"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
            if($SQLresult -eq $null){
                $id = New-Guid
                
                $insert = "INSERT INTO ViewGroup(Id, Title, Sorting, Hide) `r`n VALUES('$id','$ViewGroup',1,0)"
                
                Invoke-Sqlcmd -Query $insert -ConnectionString $connectionstring -MaxCharLength 9999999
                
                Write-Host Created a new viewGroup "'$ViewGroup'" with ViewGroupId $id -ForegroundColor Green
                
                return $id
            }else{
                Write-Host ViewGroup "'$ViewGroup'" aldready exists -ForegroundColor Yellow
                return $SQLresult.Id 
            }            
        }
    }catch{
        Write-Error $_
    }
}

function GetLastId{
    try{
        
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        $connection.Open();

        if($connection.State -eq "Open"){
            $query = "select top 1 FORSYSTEM_ID
                        from FORSYSTEM
                        order by FORSYSTEM_ID desc"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999

            $id = $SQLresult.FORSYSTEM_ID

            return $id

        }


    }catch{
        Write-Error $_
    }
}

function GetLastObjectId{

    try{

        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        $connection.Open();

        if($connection.State -eq "Open"){
            $query = "select top 1 OBJEKT_ID
                        from OBJEKT
                        order by OBJEKT_ID desc"
            
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999

            $id = $SQLresult.OBJEKT_ID

            return $id

        }

    }catch{
        Write-Error $_
    }

}


function ReplaceTemplateReferenceIdWithName([string] $xml){
    #Write-Host $xml

    $xml2 = New-Object -TypeName System.Xml.XmlDocument
    $xml2.LoadXml($xml)

    [xml]$data = $xml2.InnerXml
    
    foreach($x in $data.TemplateDynamicFrontSystem.Templates.Template.TemplateRules.TemplateRule){
        $id = $x.Rule
           
        $query = "select TEKST
                    from FORSYSTEM
                    where FORSYSTEM_ID = $id"
              
        try{
        
            $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
            $connection.Open();
        
            if($connection.State -eq "Open"){
                        
                $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
                                   
                if($SQLresult -eq $null){
                    Write-Host Schema id "'$id'" doesnt exists. Remember to make the reference yourself in TAS. -ForegroundColor Yellow
                    $x.Rule = ''
                }else{
                    $x.Rule = $SQLresult.TEKST  
                }
            }
        
        }catch{
            $_
        }        
    }

    return $data.OuterXml
}


function GetNewTemplateReferences([string] $xml) {
   
    $xml2 = New-Object -TypeName System.Xml.XmlDocument
    $xml2.LoadXml($xml)

    [xml]$data = $xml2.InnerXml
   
    foreach($x in $data.TemplateDynamicFrontSystem.Templates.Template.TemplateRules.TemplateRule){
        $templatename = $x.Rule

        $query = "select FORSYSTEM_ID
                    from FORSYSTEM
                    where TEKST = '$templatename'"
        
        try{
        
            $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
            $connection.Open();
        
            if($connection.State -eq "Open"){
                                        
                $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
                
                if($templatename -ne ''){
                    if($SQLresult -eq $null){
                        Write-Host Schema name "'$templatename'" doesnt exists. Remember to make the reference yourself in TAS. -ForegroundColor Yellow
                        $x.Rule = ''
                    }else{
                        $x.Rule = [string]$SQLresult.FORSYSTEM_ID
                    }
                }else{
                    Write-Host Reference is empty. Make sure the referenced template exists. -ForegroundColor Yellow
                }                                   
                
            }
        
        }catch{
            $_
        }        
    }   
    #Write-Host $data.OuterXml
    return $data.OuterXml
}

function Format-XML ([xml]$xml, $indent=2)
{
    $StringWriter = New-Object System.IO.StringWriter
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter
    $xmlWriter.Formatting = “indented”
    $xmlWriter.Indentation = $Indent
    $xml.WriteContentTo($XmlWriter)
    $XmlWriter.Flush()
    $StringWriter.Flush()
    Write-Output $StringWriter.ToString()
}

function GetTemplateUVG{
    
    $query = "select FrontSystemTemplateXml
                from DynamicFrontSystemTemplate
                where FrontSystemId IS NULL"

    try{

        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        $connection.Open();
        
        if($connection.State -eq "Open"){
            $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
            
            return $SQLresult.itemArray 
        }


    }catch{
        $_
    }

}

$xmluvg = GetTemplateUVG

function GetTemplateReferenceNameUVG{

    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('TemplateId')]
        [string] $Id,

        [Parameter(Mandatory=$true, Position = 1)]
        [Alias('TemplateXmlUVG')]
        [string] $xmlUVG
    )

    $xml = [xml]$xmlUVG

    foreach($node in $xml.TemplateDynamicFrontSystem.Templates.Template){
        $s = [string]$node.Id
       
        if($s.Contains('-')){
            if($s -eq $Id){
                #Write-Host Found Template Reference Title -ForegroundColor Yellow
                return $node.Title
            }
        }
    }
    Write-Host Could not find Template Reference Id - $Id -ForegroundColor Yellow
    return ''
}

function GetTemplateReferenceIdUVG{

    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('ReferenceName')]
        [string] $name,

        [Parameter(Mandatory=$true, Position = 1)]
        [Alias('TemplateXmlUVG')]
        [string] $xmlUVG
    )

    $xml = [xml]$xmlUVG

    foreach($node in $xml.TemplateDynamicFrontSystem.Templates.Template){
        #Write-Host $node.Title -ForegroundColor Magenta
        #Write-Host $name -ForegroundColor Magenta

        if($node.Title -eq $name){
            #Write-Host Found Template Reference Id -ForegroundColor Yellow
            return $node.Id
        }       
    }
    
    Write-Host Could not find Template Reference Name - $name -ForegroundColor Yellow
    return ''
}

function ReplaceTemplateReferenceNameUVG{
    Param(
        [parameter(Mandatory=$true,Position=0)]
        [Alias('SchemaTemplate')]
        [string] $uvgT
    )
    
    $uvgTemplate = [xml]$uvgT
    
    foreach($node in $uvgTemplate.TemplateDynamicFrontSystem.Templates.Template){           
        $templateId = [string]$node.ParentTemplateId
        
        if($templateId.Contains('-')){
            $result = GetTemplateReferenceNameUVG -TemplateId $templateId -TemplateXmlUVG $xmluvg

            $node.ParentTemplateId = $result
            #Write-Host Changed Reference to "'$result'" -ForegroundColor Green
        }    
    }
    
    return $uvgTemplate.OuterXml
    
}

function ReplaceTemplateReferenceIdUVG{
    Param(
        [parameter(Mandatory=$true,Position=0)]
        [Alias('SchemaTemplate')]
        [string] $uvgT
    )

    $uvgTemplate = [xml]$uvgT

    foreach($node in $uvgTemplate.TemplateDynamicFrontSystem.Templates.Template){    
        if(!($node.ParentTemplateId.nil)){
            $name = [string]$node.ParentTemplateId    

            if(!([string]::IsNullOrEmpty($name))){
                $result = GetTemplateReferenceIdUVG -ReferenceName $name -TemplateXmlUVG $xmluvg

                #Write-Host Changed Reference to "'$result'" -ForegroundColor Green
                $node.ParentTemplateId = $result
            }
        }
    }

    return $uvgTemplate.OuterXml
}

function ReplaceXmlTagContent {
    Param(
        [parameter(Mandatory = $true, Position = 0)]
        [String] $xmlContent,

        [parameter(Mandatory = $true, Position = 1)]
        [String] $searchPattern,

        [parameter(Mandatory = $true, Position = 2)]
        [String] $replacementValue
    )

    # Perform the search and replace
    $updatedXmlContent = $xmlContent -replace $searchPattern, $replacementValue

    return $updatedXmlContent
}

#endregion