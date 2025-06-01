#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading Configs 
. "$path\Methods.ps1" #Loading Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'

if(($ordning -ne '')){
    try{ 

        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        $connection.Open();

        if($connection.State -eq "Open"){
            Write-Host "SQL connection is successufull"

            ####################################
            ### Getting Word settings ####
            ####################################
            
            if([string]::IsNullOrEmpty($projektType)){
                $query = "select a.AKTIVITET_KODE, w.PROJEKTTYPE, w.DOC_TITLE, w.DOC_DESCRIBE, convert(varchar(max),convert(varbinary(max), w.DOC),2) AS 'DOC', w.TYPE, w.BUDGET_OMRAADE_ID, w.PRIVAT, w.KONTOR, w.ROLLE_1, w.ROLLE_2, w.ROLLE_3, w.STD_DOC_ID, w.KODE
                        from WORD_DOC_STD w
                        left join AKTIVITET a 
                        on w.AKTIVITET_ID = a.AKTIVITET_ID
                        where ORDNING = '$ordning' AND PROJEKTTYPE IS NULL"

            }else{
                $query = "select a.AKTIVITET_KODE, w.PROJEKTTYPE, w.DOC_TITLE, w.DOC_DESCRIBE, convert(varchar(max),convert(varbinary(max), w.DOC),2) AS 'DOC', w.TYPE, w.BUDGET_OMRAADE_ID, w.PRIVAT, w.KONTOR, w.ROLLE_1, w.ROLLE_2, w.ROLLE_3, w.STD_DOC_ID, w.KODE
                        from WORD_DOC_STD w
                        left join AKTIVITET a 
                        on w.AKTIVITET_ID = a.AKTIVITET_ID
                        where ORDNING = '$ordning' AND PROJEKTTYPE = '$projektType'"
            }
            

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
            Write-Host "Output exported in the given path $path" `r`n 

            Write-Host Number of rows: $result.Count -ForegroundColor Green
        }

    }catch{
        $_
    }
}else{
    Write-Host 'Ordning' and/or 'ProjektType' variables are empty. They have to be specified. -ForegroundColor Yellow
}

