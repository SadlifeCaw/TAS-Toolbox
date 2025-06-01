#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading Configs 
. "$path\Methods.ps1" #Loading Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'


if(($ordning -ne '')){
    if([string]::IsNullOrEmpty($projektType) -or (IsProjectTypeBoundToOrdning)){
        $wordSettings_csv = Import-Csv -Path $path\WordSettings.csv
        
        $insert_word = ""
        $update = ""

        $wordSettings_count = 0
        $update_count = 0
        $count = 0
            
        foreach($word in $wordSettings_csv){
            $isActivityLinkedToOrdning = IsActivityLinkedToOrdning -Code $word.AKTIVITET_KODE -ordning $ordning

            if($isActivityLinkedToOrdning){
		        $proType = isNull($projektType)		
                
		        if($word.DOC_DESCRIBE -ne ''){
                    $doesWordSettingExist = DoesWordSettingExist -ActivityCode $word.AKTIVITET_KODE -ProjectType $proType -Title $word.DOC_TITLE -Describe $word.DOC_DESCRIBE
                }else{
                    $doesWordSettingExist = DoesWordSettingExist -ActivityCode $word.AKTIVITET_KODE -ProjectType $proType -Title $word.DOC_TITLE
                }

                

                $activity_id = GetActivityId -Activity_code $word.AKTIVITET_KODE

                if(!$doesWordSettingExist){ 
			#$pdf = isNull_int($word.PDF)
                                                
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
                                                  
                    $insert_word += "DECLARE @binary_$count varbinary(max) = $doc `r`n
                                        INSERT INTO WORD_DOC_STD(AKTIVITET_ID,ORDNING,PROJEKTTYPE,DOC_TITLE,DOC_DESCRIBE,DOC,TYPE,BUDGET_OMRAADE_ID,PRIVAT,KONTOR,ROLLE_1,ROLLE_2,ROLLE_3,STD_DOC_ID,KODE)
                                        VALUES($activity_id, '$ordning', $proType, $title, $describe, @binary_$count, $type, $budget, $private, $kontor, $rol1, $rol2, $rol3, $std_id, $kode) `r`n"
                        
                    $wordSettings_count++
                    $count++
                }elseif($doesWordSettingExist){

                    $doc_id = GetDocId -ActivityCode $word.AKTIVITET_KODE -ProjectType $proType -Title $word.DOC_TITLE -Describe $word.DOC_DESCRIBE
                    
                    $update += "DECLARE @binary_$count varbinary(max) = $doc `r`n 
                                    UPDATE WORD_DOC_STD 
                                    SET DOC_TITLE = $title, DOC_DESCRIBE = $describe, DOC = @binary_$count, TYPE = $type, BUDGET_OMRAADE_ID = $budget, PRIVAT = $private, KONTOR = $kontor, ROLLE_1 = $rol1, ROLLE_2 = $rol2, ROLLE_3 = $rol3, STD_DOC_ID = $std_id, KODE = $kode 
                                    where DOC_ID = $doc_id `r`n"

                    $update_count++
                    $count++
                }
            }
        }

        $query = $insert_word + $update
        
        if($query -ne ''){
            
            try{
                $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
                $connection.Open();

                if($connection.State -eq 'Open'){
                    #Write-Host $query
                    $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength

                    Write-Host Query executed `r`n -ForegroundColor Green  
                    Write-Host $wordSettings_count Word settings were uploaded and $update_count were updated"'" -ForegroundColor Green
               }

               $connection.Close()
               Write-Host SQL connection is closed.
            }catch{
                Write-Error $_
            }
    
        }else{
            Write-Host Nothing to insert -ForegroundColor Yellow
        }

    }        
}else{
    Write-Host 'Ordning' and/or 'ProjektType' variables are empty. They have to be specified. -ForegroundColor Yellow
}

   
 


