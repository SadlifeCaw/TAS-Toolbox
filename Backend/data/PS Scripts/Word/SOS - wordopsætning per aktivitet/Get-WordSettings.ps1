#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs
. "$path\1. Methods - v2.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'

$ordning = @("'XNEALTRANS'","'xALBOTrans'")

if($ordning -ne ''){

    $ordning = $ordning -join ','

    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){
            Write-Host "SQL connection is successufull"

            ####################################
            ### Getting Word settings ####
            ####################################
        
            $query = "select a.AKTIVITET_KODE, w.PDF, w.PROJEKTTYPE, w.DOC_TITLE, w.DOC_DESCRIBE, convert(varchar(max),convert(varbinary(max), w.DOC),2) AS 'DOC', w.TYPE, w.BUDGET_OMRAADE_ID, w.PRIVAT, w.KONTOR, w.ROLLE_1, w.ROLLE_2, w.ROLLE_3, w.STD_DOC_ID, w.KODE
                        from WORD_DOC_STD w
                        left join AKTIVITET a 
                        on w.AKTIVITET_ID = a.AKTIVITET_ID
                        where ORDNING IN($ordning) AND a.AKTIVITET_KODE IN ('xNEAL008','xALBO008') "
            write-host $query 
            $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
                       
            Write-Host Query executed

            #Making sure the 'DOC' has the proper start '0x'
            foreach($doc in $result){
                $doc.DOC = '0x' + $doc.DOC
            }

            $count = 0
            Write-Host `r`n Retrieved word settings
            foreach($item in $result){
                Write-Host $item.AKTIVITET_KODE - $item.DOC_TITLE
                $count++
            } 

            
            $result | Export-Csv -Path $path\WordSettings.csv -NoTypeInformation -Encoding UTF8
            Write-Host "Output exported in the given path $path" `r`n

            Write-Host Number of rows : $count
        }

    }catch{
        $_
    }
}

