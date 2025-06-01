#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'

if($ordning_id -ne $false){
    Title -Title 'Get-RapportGruppe'
    try{
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring

        $connection.Open();

        if($connection.State -eq "Open"){cls
            Write-Host "SQL connection is successufull"

            ####################################
            ### Getting the Schema settings ####
            ####################################
        
            $query = "select org.OBLIGATORISK, org.SORT, org.AKTIV, org.KATEGORI, r.TEKST, r.AKTIV AS 'RAPPORT_AKTIV'
                        from ORDNING_RAPPORTGRUPPE org
                        left join RAPPORTGRUPPE r
                        on org.RAPPORTGRUPPE_ID = r.RAPPORTGRUPPE_ID
                        where ORDNING = '$ordning'"
        
            
            $result = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
            Write-Host Query executed
        
            Write-Host `r`n Retrieved $result.Count Rapport groups: 
            ForEach($item in $result){
                Write-Host $item.TEKST -ForegroundColor Green
            } 

            $result | Export-Csv -Path $path\RapportGruppe.csv -NoTypeInformation -Encoding UTF8
            Write-Host "Output exported in the given path $path" `r`n

        }
    }catch{
        $_
    }
}