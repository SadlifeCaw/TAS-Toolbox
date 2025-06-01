#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'


if($ordning_id -ne $false){

    DoesZipExist #Does data.zip exists

    $testPath = DoesFileExist -FileName RapportGruppe.csv

    if($testPath){
        
        Title -Title 'Set-RapportGruppe'

        $RapportGruppe_csv = Import-Csv -Path $path\RapportGruppe.csv

        foreach($r in $RapportGruppe_csv){
            
            $tekst = $r.TEKST
            $rapportAktiv = $r.RAPPORT_AKTIV
            $obl = $r.OBLIGATORISK
            $sort = isNull_int($r.SORT)
            $aktiv = $r.AKTIV
            $kategori = isNull_int($r.KATEGORI)

            #Create rapport gruppe if it doesnt already exist
            CreateRapportGruppe -Tekst $tekst -Aktiv $rapportAktiv

            $rapport_id = GetRapportGruppeId -Value $tekst

            $doesRapportGruppeSettingExist = DoesRapportGruppeSettingExist -Id $rapport_id -Tekst $tekst -Obl $obl -Sort $sort -Aktiv $aktiv -Kategori $kategori
            
            if(!$doesRapportGruppeSettingExist){

                $query = "INSERT INTO ORDNING_RAPPORTGRUPPE(ORDNING, RAPPORTGRUPPE_ID, OBLIGATORISK, SORT, AKTIV, KATEGORI) `r`n VALUES('$ordning', $rapport_id, '$obl', $sort, '$aktiv', '$kategori')"
                Write-Host $query
                try{

                    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
                    $connection.Open();
        
                    if($connection.State -eq "Open"){

                        #Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999

                        Write-Host Created new Rapport gruppe: 
                        Write-Host TEKST : $tekst -ForegroundColor Green
                        Write-Host ORDNING : $ordning -ForegroundColor Green
                        Write-Host
                    }
                            
                }catch{
                    Write-Error $_
                }finally{
                    $connection.Close()
                }


            }else{
                Write-Host RapportGruppe "'$tekst'" already exists. -ForegroundColor Yellow
                Write-Host 
            }
        }
    }
}