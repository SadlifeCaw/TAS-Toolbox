#Author : Nevethan Alagaratnam

$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Methods.ps1" #Loading Methods

###########################################
#########      CONFIGS       ##############
###########################################


#ConnectionString information
# You can get 'source' and 'database name' variables from the CONFIGS in TAS or from the database in SQL Server Management Studio (SSMS)

##### TEST #####
$source = "bsmsossql01t\TASTEST" # Data source 
$db = "TASTestDB" # Database name'

##### PROD #####
#$source = "bsm-sos-sql01p\TASPROD" # Data source 
#$db = "TASProdDB" # Database name'

#ConnectionString - DONT CHANGE THIS
#Windows authentication
$connectionstring = "Data Source=$source;Initial Catalog=$db;Integrated Security=true;"

$maxCharLength = 2147483647 #Invoking a sqlcmd has a Default char length limit of 4000 characters(It doesnt get everything). So, put the limit to 


#############################################
#########    GET Word Setting   #############
#############################################


######################################################################################################

$ordning = 'MASTER2' #Specify which 'Ordning' to retrive the the word setting from.

######################################################################################################


#############################################
#########    SET Word Setting   #############
#############################################

######################################################################################################

#Specify which 'Ordnings' where the word settings should be replaced. DEFAULT exclude ordnings: MASTER1 and MASTER2
#If the variable '$ordnings' is empty, it will retrieve all ORDNINGS except MASTER1 and MASTER2
$ordnings = @('KOSKO','TESTKS')  #@('ORDNING1','ORDNING2', ...)

#Which Ordning/Ordnings should be skipped. 
$skipOrdnings = @()  #@('ORDNING1','ORDNING2', ...)

######################################################################################################


############################################
###   GET Word Setting IMPLEMENTATION    ###
############################################

if(($ordning -ne '')){
    try{ 

        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        $connection.Open();

        if($connection.State -eq "Open"){
            Write-Host "SQL connection is successufull"

            ####################################
            ### Getting Word settings ####
            ####################################
            
            $query = "select a.AKTIVITET_KODE, w.PROJEKTTYPE, w.DOC_TITLE, w.DOC_DESCRIBE, convert(varchar(max),convert(varbinary(max), w.DOC),2) AS 'DOC', w.TYPE, w.BUDGET_OMRAADE_ID, w.PRIVAT, w.KONTOR, w.ROLLE_1, w.ROLLE_2, w.ROLLE_3, w.STD_DOC_ID, w.KODE
                    from WORD_DOC_STD w
                    left join AKTIVITET a 
                    on w.AKTIVITET_ID = a.AKTIVITET_ID
                    where ORDNING = '$ordning' AND PROJEKTTYPE IS NULL AND a.AKTIVITET_KODE = 'MASSEBREV'"


            $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
                       
            Write-Host Query executed

            #Making sure the 'DOC' has the proper start '0x'
            foreach($doc in $result){
                $doc.DOC = '0x' + $doc.DOC
            }

            Write-Host `r`n Retrieved $result.Count word settings: -ForegroundColor Green
            foreach($item in $result){
                Write-Host $item.AKTIVITET_KODE - $item.DOC_TITLE -ForegroundColor Green
            } 

            
            $result | Export-Csv -Path $path\WordSettings.csv -NoTypeInformation -Encoding UTF8
            Write-Host "Output exported in the given path:" 
            write-host $path\WordSettings.csv
            Write-Host -------------------------------------------------------------

        }

    }catch{
        Write-Error $_
    }
    finally{
        $connection.Close()
    }
}else{
    Write-Host "'Ordning'" variable is empty. It has to be specified. -ForegroundColor Yellow
}


############################################
###   SET Word Setting IMPLEMENTATION    ###
############################################

# Getting all Ordnings
if(($ordnings.Count -eq 0)){
    
    try{

    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
    $connection.Open();

    if($connection.State -eq "Open"){
            Write-Host "SQL connection is successufull"

            ####################################
            ### Getting Word settings ####
            ####################################
            
            $query = "SELECT ORDNING
                        FROM ORDNING
                        WHERE ORDNING NOT IN('MASTER1','MASTER2')"


            $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
        }
    }catch{
        Write-Error $_
    }
    finally{
        $connection.Close()
    }

    $ordnings = $result.itemArray
}


#Getting the word setting
$wordSettings_csv = Import-Csv -Path $path\WordSettings.csv

if($wordSettings_csv.AKTIVITET_KODE.Length -gt 0){ #Check if a word setting has been retrieved
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        $connection.Open();

        foreach($word in $wordSettings_csv){
            $wordSettings_count = 0
            $update_count = 0
            $count = 0

            foreach($o in $ordnings){
                
                if($skipOrdnings -notcontains $o ){
                    $query = ""
   
                    $ordning = $o

                    $isActivityLinkedToOrdning = IsActivityLinkedToOrdning -Code $word.AKTIVITET_KODE

                    if($isActivityLinkedToOrdning){
		                $proType = 'NULL'	
                    
		                if($word.DOC_DESCRIBE -ne ''){
                            $doesWordSettingExist = DoesWordSettingExist -ActivityCode $word.AKTIVITET_KODE -ProjectType $proType -Title $word.DOC_TITLE -Describe $word.DOC_DESCRIBE 
                        }else{
                            $doesWordSettingExist = DoesWordSettingExist -ActivityCode $word.AKTIVITET_KODE -ProjectType $proType -Title $word.DOC_TITLE 
                        }

                        $activity_id = GetActivityId -Activity_code $word.AKTIVITET_KODE
                        
                            $budget = isNull_int($word.BUDGET_OMRAADE_ID)
                	        $title = isNull($word.DOC_TITLE)
                	        $describe = isNull($word.DOC_DESCRIBE)
                	        
                            $doc = $word.DOC

                            #$docValue = $doc.ItemArray[4]
                            #Write-Host HELLO -ForegroundColor Magenta
                            
                            #$test2 = "$docValue"

                            $type = isNull($word.TYPE)
                	        $private = isNull($word.PRIVAT)
                	        $kontor = isNull($word.KONTOR)
                	        $rol1 = isNull($word.ROLLE_1)
                	        $rol2 = isNull($word.ROLLE_2)
                	        $rol3 = isNull($word.ROLLE_3)
                	        $std_id = isNull_int($word.STD_DOC_ID)
                	        $kode = isNull($word.KODE) 

                        if(!$doesWordSettingExist){ 
			            #$pdf = isNull_int($word.PDF)
                                                
                            $query = "DECLARE @binary_$count varbinary(max) = $doc `r`n
                                                INSERT INTO WORD_DOC_STD(AKTIVITET_ID,ORDNING,PROJEKTTYPE,DOC_TITLE,DOC_DESCRIBE,DOC,TYPE,BUDGET_OMRAADE_ID,PRIVAT,KONTOR,ROLLE_1,ROLLE_2,ROLLE_3,STD_DOC_ID,KODE)
                                                VALUES($activity_id, '$ordning', $proType, $title, $describe, @binary_$count, $type, $budget, $private, $kontor, $rol1, $rol2, $rol3, $std_id, $kode) `r`n"
                        
                            $wordSettings_count++
                            $count++

                            Write-Host Inserted new Word settings in "'$o' `r`n" -ForegroundColor Green
                        }elseif($doesWordSettingExist){
                            $doc_id = GetDocId -ActivityCode $word.AKTIVITET_KODE -ProjectType $proType -Title $word.DOC_TITLE -Describe $word.DOC_DESCRIBE
                    
                            $query = "DECLARE @binary_$count varbinary(max) = $doc `r`n 
                                            UPDATE WORD_DOC_STD 
                                            SET DOC_TITLE = $title, DOC_DESCRIBE = $describe, DOC = @binary_$count, TYPE = $type, BUDGET_OMRAADE_ID = $budget, PRIVAT = $private, KONTOR = $kontor, ROLLE_1 = $rol1, ROLLE_2 = $rol2, ROLLE_3 = $rol3, STD_DOC_ID = $std_id, KODE = $kode 
                                            where DOC_ID = $doc_id `r`n"

                            $update_count++
                            $count++

                            Write-Host Updated Word settings in "'$o' `r`n" -ForegroundColor Yellow
                        }

                        #Write-Host $query

                        if($query -ne ''){
                            if($connection.State -eq 'Open'){
                                #Write-Host $query
                                $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength

                            }

                        }else{
                            Write-Host Nothing to insert -ForegroundColor Yellow
                        }
                    }
                }else{
                    Write-Host Skipped ordning "'$o'" -ForegroundColor Yellow
                } 
            }
            Write-Host 
            Write-Host $wordSettings_count Word settings were uploaded and $update_count were updated"'" -ForegroundColor Green
            Write-Host     
        
        }
    }catch{
        Write-Error $_
    }
    finally{
        $connection.Close()
        Write-Host SQL connection is closed.
    }
}else{
    Write-Host No Word settings where retrieved. Check $path\WordSettings.csv -ForegroundColor Red 
}
    
