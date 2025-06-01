#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'


if($ordning_id -ne $false){

    DoesZipExist #Does data.zip exists

    $testPath = DoesFileExist -FileName Omkostningsart.csv

    if($testPath){
        
        Title -Title 'Set-Omkostningsart'

        $Omkostningsart_csv = Import-Csv -Path $path\Omkostningsart.csv

        foreach($o in $Omkostningsart_csv){
            
            $omk = $o.OMKOSTNING_ART
            $tekst = $o.TEKST
            $systemArt = isNull($o.SYSTEM_ART)
            $niveu = isNull_int($o.NIVEU)
            $aktiv = $o.AKTIV

            #Checking if the Omkostning art exist. If not, it will be created
            $doesOmkostningsArtExist = DoesOmkostningArtExist -OmkostningsArt $omk -Tekst $tekst -SystemArt $systemArt -Niveu $niveu -Aktiv $aktiv

            if(!$doesOmkostningsArtExist){
                
                $budget = isNull_int($o.BUDGET_AFVIGELSE.Replace(',','.'))
                $tilsagn = $o.TILSAGN_PROCENT.Replace(',','.')
                $default = $o.DEFAULT_JN
                $omkAktiv = $o.OMK_AKTIV
                $sort = isNull_int($o.SORT)
                $tilsagnDefault = isNull_int($o.TILSAGN_PROCENT_DEFAULT)

                $query = "INSERT INTO ORDNING_OMK(ORDNING, OMKOSTNING_ART, BUDGET_AFVIGELSE, TILSAGN_PROCENT, DEFAULT_JN, AKTIV, SORT, TILSAGN_PROCENT_DEFAULT) `r`n VALUES('$ordning', '$omk', $budget, $tilsagn, '$default', '$omkAktiv', $sort, $tilsagnDefault) "
                #Write-Host $query
                try{
                    
                    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
                    $connection.Open();
        
                    if($connection.State -eq "Open"){

                        Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
                        
                        Write-Host Created OmkostningArt: 
                        Write-Host OMKOSTNING_ART : $omk -ForegroundColor Green
                        Write-Host TEKST : $tekst -ForegroundColor Green
                        Write-Host Ordning : $ordning -ForegroundColor Green
                        Write-Host
                    }
                }catch{
                    Write-Error $_
                }finally{
                    $connection.Close()
                }

            }else{
                Write-Host OmkostningArt already exists: 
                Write-Host OMKOSTNING_ART : $omk -ForegroundColor Yellow 
                Write-Host TEKST : $tekst -ForegroundColor Yellow
                Write-Host Ordning : $ordning -ForegroundColor Yellow
                Write-Host
            }
        }
    }
}