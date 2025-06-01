#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs
. "$path\1. Methods - v2.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'

$list_ordning = @()
$list_regel = @()

## Get list of ordnings ##

try{
    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

    $connection.Open();

    if($connection.State -eq "Open"){
        $query = "select o.ORDNING, r.TEKST
                    from ORDNING o
                    inner join ORDNING_PROJEKTTYPE op
                    on o.ORDNING = op.ORDNING
                    left join REGELSAET r
                    on op.REGELSAET_ID = r.REGELSAET_ID
                    where op.REGELSAET_ID IN (select REGELSAET_ID
		                                from REGELSAET
		                                where TEKST IN ($list_regelsaet)) AND o.ORDNING != 'MASTER1' AND o.ORDNING != 'MASTER2' AND o.TEKST NOT LIKE 'L%' AND o.TEKST NOT LIKE 'R%'"
      
        $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
            
        if($SQLresult -eq $null){
            Write-Error -Message "Couldnt find the RegelSæt ID. It is either because the variable is empty or the ordning name does not exist " -Category InvalidArgument 
            break
        }else{
            $list_ordning = $SQLresult.ORDNING
            $list_regel = $SQLresult.TEKST
        } 
    }

}catch{
    Write-Error $_    
}finally{
    $connection.Close()
}


#$list_ordning = @('XTEST6','XTEST6')
#$list_regel = @('Ansøgningsrunder - ANS9','Ansøgningsrunder og Løse ansøgninger T5')

$list_ordning_length = $list_ordning.Length
$i = 0

$data_syncs_ordning_ids = @()

if($list_ordning.Length -eq $list_regel.Length){
    foreach($o in $list_ordning){
        Write-Progress -Id 0 "Ordning number $i ($o) out of $list_ordning_length" 
               
        $regel = $list_regel[$i]
        
        $data_syncs_ordning_ids = GetAllDataSyncIds -Ordning $o -Regel $regel
        
        if($data_syncs_ordning_ids.Count -gt 0){
       
            write-host $o -ForegroundColor Green
            foreach($ds in $data_syncs_ordning_ids){
    
                $query = "Delete from DATASYNC_JOB_SETUP
                            where SchemeFrontSystemId = $ds

                            delete from ORDNING_FORSYSTEM_PARM
                            where ORDNING_FORSYSTEM_ID = $ds

                            delete from ORDNING_FORSYSTEM
                            where ORDNING_FORSYSTEM_ID = $ds"
                            
                Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999    
                Write-Host "Deleted data Sync for regelsæt '$regel'"  -ForegroundColor Green
                Write-Host "In Ordning '$o'" -ForegroundColor Green
                Write-Host 
            }
        }
        $i++
    }
}else{
    Write-Error The counts of the lists do not match
}

