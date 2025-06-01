#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs
. "$path\1. Methods - v2.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'

if($ordning_forsystem_ids.Length -ne 0){
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){
            Write-Host "SQL connection is successufull"

        
                    
            $query = "select f.TEKST,o.ORDNING, a.AKTIVITET_KODE AS 'AKTIVITET_ID', a2.AKTIVITET_KODE AS 'LUK_AKTIVITET_ID',o.ORDNING_FORSYSTEM_ID,a3.AKTIVITET_KODE AS 'GENAABEN_AKTIVITET_ID',
                        o.IsPublic,op.PARM,op.OBJEKT,a4.AKTIVITET_KODE AS 'NextActivityId', djs.ApproveActivity, djs.NumberOfRespiteDays, djs.CaseLogState, djs.ActionOnCompletion
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
                            where o.ORDNING_FORSYSTEM_ID IN ($ordning_forsystem_ids)"
            
            
            
            <#$query = "select f.TEKST,o.ORDNING, a.AKTIVITET_KODE AS 'AKTIVITET_ID', a2.AKTIVITET_KODE AS 'LUK_AKTIVITET_ID',o.ORDNING_FORSYSTEM_ID,a3.AKTIVITET_KODE AS 'GENAABEN_AKTIVITET_ID',
                        o.IsPublic,op.PARM,op.OBJEKT,a4.AKTIVITET_KODE AS 'NextActivityId', djs.ApproveActivity, djs.NumberOfRespiteDays, djs.CaseLogState, djs.ActionOnCompletion
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
                            where o.ORDNING = '$ordning' AND o.ORDNING_FORSYSTEM_ID IN (
                                select ORDNING_FORSYSTEM_ID from ORDNING_FORSYSTEM
                                where ORDNING = 'Master1'
                                and FORSYSTEM_ID = 206
                                and AKTIVITET_ID in (select distinct AKTIVITET_ID
                                from AKTIVITET_REGEL
                                where REGELSAET_ID IN(14,18)
                                union all
                                select distinct AKTIVITET_ID
                                from AKTIVITET_REGEL_GENEREL
                                where REGELSAET_ID IN(14,18))
                            )"
                            #>
            <#$query = "select f.TEKST,o.ORDNING, a.AKTIVITET_KODE AS 'AKTIVITET_ID', a2.AKTIVITET_KODE AS 'LUK_AKTIVITET_ID',o.ORDNING_FORSYSTEM_ID,a3.AKTIVITET_KODE AS 'GENAABEN_AKTIVITET_ID',
                        o.IsPublic,op.PARM,op.OBJEKT,a4.AKTIVITET_KODE AS 'NextActivityId', djs.ApproveActivity, djs.NumberOfRespiteDays, djs.CaseLogState, djs.ActionOnCompletion
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
							left join ORDNING_PROJEKTTYPE opt
							on o.ORDNING = opt.ORDNING
                            where o.ORDNING_FORSYSTEM_ID IN (632) and opt.PROJEKTTYPE = 'Kursus'"
                            #>

            $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
            Write-Host Query executed
        
            Write-Host `r`n Retrieved $result.Count Schema settings
            foreach($item in $result){
                Write-Host $item.TEKST - $item.AKTIVITET_ID -ForegroundColor Green
            } 

            $result | Export-Csv -Path $path\SpecificSchemaSettings.csv -NoTypeInformation -Encoding UTF8
            Write-Host "Output exported in the given path $path" `r`n
        }

    }catch{
        Write-Error $_
    }finally{
        $connection.Close()
    }
}else{
    Write-Error "ORDNING AND/OR List of Ordning forsystem ids cannot be emtpy"
}