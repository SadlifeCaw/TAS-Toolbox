#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs and Methods
. "$path\Methods.ps1"

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
        
            $query = "select f.TEKST,o.ORDNING, a.AKTIVITET_KODE AS 'AKTIVITET_KODE', a2.AKTIVITET_KODE AS 'LUK_AKTIVITET_KODE',o.ORDNING_FORSYSTEM_ID,a3.AKTIVITET_KODE AS 'GENAABEN_AKTIVITET_ID',
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
                            where o.ORDNING = '$ordning'"
        
        
            $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
            Write-Host Query executed

            foreach($r in $result){
                $r.AKTIVITET_KODE = $r.AKTIVITET_KODE.replace($InitialFra,$InitialTil)
                
                if(!([string]::IsNullOrEmpty($r.LUK_AKTIVITET_KODE))){
                    $r.LUK_AKTIVITET_KODE = $r.LUK_AKTIVITET_KODE.replace($InitialFra,$InitialTil)
                }

                if(!([string]::IsNullOrEmpty($_.GENAABEN_AKTIVITET_ID))){
                    $r.GENAABEN_AKTIVITET_ID = $r.GENAABEN_AKTIVITET_ID.replace($InitialFra,$InitialTil)
                }

                if(!([string]::IsNullOrEmpty($_.NextActivityId))){
                    $r.NextActivityId = $r.NextActivityId.replace($InitialFra,$InitialTil)
                }
                
            }
        
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