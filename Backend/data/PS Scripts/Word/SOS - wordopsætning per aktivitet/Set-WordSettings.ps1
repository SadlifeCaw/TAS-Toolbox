#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs
. "$path\1. Methods - v2.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'

$wordSettings_csv = Import-Csv -Path $path\WordSettings.csv

$insert_word = ""
$wordSettings_count = 0

## Get list of ordnings ##

try{
    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

    $connection.Open();

    if($connection.State -eq "Open"){
        $query = "select distinct ORDNING
                        from ORDNING_PROJEKTTYPE
                        where REGELSAET_ID IN (select REGELSAET_ID
                        from AKTIVITET_REGEL
                        where AKTIVITET_ID IN(select AKTIVITET_ID from AKTIVITET where AKTIVITET_KODE IN ('xNEAL008','xALBO008'))
                        union select REGELSAET_ID
                        from AKTIVITET_REGEL_GENEREL
                        where AKTIVITET_ID IN(select AKTIVITET_ID from AKTIVITET where AKTIVITET_KODE IN ('xNEAL008','xALBO008')))"
            
        $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
        if($SQLresult -eq $null){
            Write-Error -Message "Couldnt find the RegelSæt ID. It is either because the variable is empty or the ordning name does not exist " -Category InvalidArgument 
            break
        }else{
            $list_ordning = $SQLresult.itemArray
        } 
    }

}catch{
    $_    
}

foreach($ordning in $list_ordning){
    foreach($word in $wordSettings_csv){
        $isActivityLinkedToOrdning = IsActivityLinkedToOrdning -Code $word.AKTIVITET_KODE 

        if($isActivityLinkedToOrdning){
            
            $projectTypes = GetProjectTypes 
            
            foreach($ptype in $projectTypes){
                $projectType = $ptype.PROJEKTTYPE
                
                $isActivityLinkedToProjectType = IsActivityLinkedToProjectType -ActivityCode $word.AKTIVITET_KODE

                if($isActivityLinkedToProjectType){
                    $doesWordSettingExist = DoesWordSettingExist -Code $word.AKTIVITET_KODE -ProjectType $projectType -Title $word.DOC_TITLE -Describe $word.DOC_DESCRIBE

                    if($doesWordSettingExist -eq $false){
                
                        try{
                            $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

                            $connection.Open();

                            if($connection.State -eq 'Open'){
                                $pdf = isNull_int($word.PDF)
                                                
                                $budget = isNull_int($word.BUDGET_OMRAADE_ID)
                                $title = isNull($word.DOC_TITLE)
                                $describe = isNull($word.DOC_DESCRIBE)
                                $doc = $word.DOC
                                $type = isNull($word.TYPE)
                                $private = isNull($word.PRIVAT)
                                $kontor = isNull($word.KONTOR)
                                $rol1 = isNull($word.ROLLE_1)
                                $rol2 = isNull($word.ROLLE_2)
                                $rol3 = isNull($word.ROLLE_3)
                                $std_id = isNull_int($word.STD_DOC_ID)
                                $kode = isNull($word.KODE)
                        
                                $activity_id = GetActivityId -Activity_code $word.AKTIVITET_KODE
                            
                                $insert_word = $insert_word + "DECLARE @binary_$wordSettings_count varbinary(max) = $doc `r`n
                                                    INSERT INTO WORD_DOC_STD(AKTIVITET_ID,ORDNING,PDF,PROJEKTTYPE,DOC_TITLE,DOC_DESCRIBE,DOC,TYPE,BUDGET_OMRAADE_ID,PRIVAT,KONTOR,ROLLE_1,ROLLE_2,ROLLE_3,STD_DOC_ID,KODE)
                                                    VALUES($activity_id, '$ordning', $pdf, '$projectType', $title, $describe, @binary_$wordSettings_count, $type, $budget, $private, $kontor, $rol1, $rol2, $rol3, $std_id, $kode) `r`n"

                                                   <# $insert_word = $insert_word + "INSERT INTO WORD_DOC_STD(AKTIVITET_ID,ORDNING,PDF,PROJEKTTYPE,DOC_TITLE,DOC_DESCRIBE,DOC,TYPE,BUDGET_OMRAADE_ID,PRIVAT,KONTOR,ROLLE_1,ROLLE_2,ROLLE_3,STD_DOC_ID,KODE)
                                                    VALUES($activity_id, '$ordning', $pdf, '$projectType', $title, $describe, @binary_$wordSettings_count, $type, $budget, $private, $kontor, $rol1, $rol2, $rol3, $std_id, $kode) `r`n"#>
                        
                                $wordSettings_count++
                                                
                            }
                        }catch{
                            $_
                        }
                    }
                }             
            }
        }
    }
}
#Write-Host $insert_word


if($insert_word -ne ''){
    
    $result = Invoke-Sqlcmd -Query $insert_word -ConnectionString $connectionstring -MaxCharLength $maxCharLength
    Write-Host Query executed `r`n
            
    Write-Host $wordSettings_count Word settings were uploaded"'" -ForegroundColor Green
}
    
    
    


