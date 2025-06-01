#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'

if($ordning_id -ne $false){
    Title -Title 'Get-SchemaSettings'
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){cls
            Write-Host "SQL connection is successufull"

            ####################################
            ### Getting the Schema settings ####
            ####################################
            
            if([string]::IsNullOrEmpty($RegelsætName)){
                $query = "select f.TEKST,o.ORDNING, a.AKTIVITET_KODE AS 'AKTIVITET_KODE', a2.AKTIVITET_KODE AS 'LUK_AKTIVITET_KODE',o.ORDNING_FORSYSTEM_ID,a3.AKTIVITET_KODE AS 'GENAABEN_AKTIVITET_ID',
                        o.IsPublic,op.PARM,op.OBJEKT,a4.AKTIVITET_KODE AS 'NextActivityId', djs.ApproveActivity, djs.NumberOfRespiteDays, djs.CaseLogState, djs.ActionOnCompletion, o.TJEKLISTEDATA_TJEKLISTEID
                            from ORDNING_FORSYSTEM o
                            left join AKTIVITET a
                            on o.AKTIVITET_ID = a.AKTIVITET_ID
                            left join AKTIVITET a2
                            on o.LUK_AKTIVITET_ID = a2.AKTIVITET_ID
                            left join AKTIVITET a3
                            on o.GENAABEN_AKTIVITET_ID = a3.AKTIVITET_ID OR (o.GENAABEN_AKTIVITET_ID IS NULL AND a3.AKTIVITET_ID = o.GENAABEN_AKTIVITET_ID)
                            left join FORSYSTEM f
                            on f.FORSYSTEM_ID = o.FORSYSTEM_ID
                            left join ORDNING_FORSYSTEM_PARM op
                            on o.ORDNING_FORSYSTEM_ID = op.ORDNING_FORSYSTEM_ID
                            left join DATASYNC_JOB_SETUP djs
                            on djs.SchemeFrontSystemId = op.ORDNING_FORSYSTEM_ID
                            left join AKTIVITET a4
                            on djs.NextActivityId = a4.AKTIVITET_ID
                            where o.ORDNING = '$ordning'"
            }else{
                $query = "select f.TEKST,o.ORDNING, a.AKTIVITET_KODE AS 'AKTIVITET_KODE', a2.AKTIVITET_KODE AS 'LUK_AKTIVITET_KODE',o.ORDNING_FORSYSTEM_ID,a3.AKTIVITET_KODE AS 'GENAABEN_AKTIVITET_ID',
                       o.IsPublic,op.PARM,op.OBJEKT,a4.AKTIVITET_KODE AS 'NextActivityId', djs.ApproveActivity, djs.NumberOfRespiteDays, djs.CaseLogState, djs.ActionOnCompletion, o.TJEKLISTEDATA_TJEKLISTEID
                            from ORDNING_FORSYSTEM o
                            left join AKTIVITET a
                            on o.AKTIVITET_ID = a.AKTIVITET_ID
                            left join AKTIVITET a2
                            on o.LUK_AKTIVITET_ID = a2.AKTIVITET_ID
                            left join AKTIVITET a3
                            on o.GENAABEN_AKTIVITET_ID = a3.AKTIVITET_ID OR (o.GENAABEN_AKTIVITET_ID IS NULL AND a3.AKTIVITET_ID = o.GENAABEN_AKTIVITET_ID)
                            left join FORSYSTEM f
                            on f.FORSYSTEM_ID = o.FORSYSTEM_ID
                            left join ORDNING_FORSYSTEM_PARM op
                            on o.ORDNING_FORSYSTEM_ID = op.ORDNING_FORSYSTEM_ID
                            left join DATASYNC_JOB_SETUP djs
                            on djs.SchemeFrontSystemId = op.ORDNING_FORSYSTEM_ID
                            left join AKTIVITET a4
                            on djs.NextActivityId = a4.AKTIVITET_ID
                            where o.ORDNING = '$ordning' and a.AKTIVITET_KODE IN(
								select distinct AKTIVITET_KODE 
								from AKTIVITET 
								where AKTIVITET_ID IN(
									select AKTIVITET_ID
									from AKTIVITET_REGEL
									where REGELSAET_ID = $regelsæt_id
									UNION ALL
									select AKTIVITET_ID
									from AKTIVITET_REGEL_GENEREL
									where REGELSAET_ID = $regelsæt_id))"
            }
            
            Write-Host $query
        
            $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
            Write-Host Query executed
        
            Write-Host `r`n Retrieved Schema settings
            foreach($item in $result){
                Write-Host $item.TEKST - $item.AKTIVITET_KODE -ForegroundColor Green
            } 

            $result | Export-Csv -Path $path\SchemaSettings.csv -NoTypeInformation -Encoding UTF8
            Write-Host "Output exported in the given path $path" `r`n

            Write-Host Number of rows : $result.Count -ForegroundColor Green
        }
    }catch{
        $_
    }
}