#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'

if($ordning_id -ne $false){
    Title -Title 'Get-Omkostningsart'
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){cls
            Write-Host "SQL connection is successufull"

            ####################################
            ### Getting the Schema settings ####
            ####################################
        
            $query = "select o.OMKOSTNING_ART, o.TEKST, o.SYSTEM_ART, o.NIVEAU, o.AKTIV, oo.BUDGET_AFVIGELSE, oo.TILSAGN_PROCENT, oo.DEFAULT_JN, oo.AKTIV AS 'OMK_AKTIV', oo.SORT, oo.TILSAGN_PROCENT_DEFAULT
                        from OMKOSTNINGSART o
                        left join ORDNING_OMK oo
                        on o.OMKOSTNING_ART = oo.OMKOSTNING_ART
                        where oo.ORDNING = '$ordning'"
        
            
            $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
            Write-Host Query executed
        
            Write-Host `r`n Retrieved $result.Count Omkostningsart settings: 
            ForEach($item in $result){
                Write-Host $item.OMKOSTNING_ART -ForegroundColor Green
            } 

            $result | Export-Csv -Path $path\Omkostningsart.csv -NoTypeInformation -Encoding UTF8
            Write-Host "Output exported in the given path $path" `r`n

        }
    }catch{
        $_
    }
}