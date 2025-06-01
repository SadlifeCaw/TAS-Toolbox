#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'


if($ordning_id -ne $false){

    DoesZipExist #Does data.zip exists

    $testPath = DoesFileExist -FileName StatistikKode.csv

    if($testPath){
        
        Title -Title 'Set-StatistikKode'

        $StatistikKode_csv = Import-Csv -Path $path\StatistikKode.csv

        foreach($s in $StatistikKode_csv){
            
            $kode = $s.STATISTIK_KODE
            $sort = $s.SORT

            $doesStatistikKodeExist = DoesStatistikKodeExist -Kode $kode -Sort $sort
            
            if(!$doesStatistikKodeExist){
                
                if([string]::IsNullOrEmpty($sort)){
                    $sort = isNull_int($sort)    
                }else{
                    $sort = $sort.Replace(',','.')
                }

                $query = "INSERT INTO ORDNING_STATISTIK(ORDNING, STATISTIK_KODE, SORT) `r`n VALUES('$ordning','$kode',$sort)"
               Write-Host $query
                try{

                    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
                    $connection.Open();
        
                    if($connection.State -eq "Open"){

                        #Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999

                        Write-Host Created new Statistik Kode: 
                        Write-Host STATISTIK_KODE : $kode -ForegroundColor Green
                        Write-Host Ordning : $ordning -ForegroundColor Green
                        Write-Host
                    }
                            
                }catch{
                    Write-Error $_
                }finally{
                    $connection.Close()
                }
            }else{
                Write-Host Statistik Kode "'$kode'" already exists. -ForegroundColor Yellow
                Write-Host
            }



            continue
            $emne = $e.EMNE_ORD

            $doesEmneOrdExist = DoesEmneOrdExist -Value $emne

            if(!$doesEmneOrdExist){

                $query = "INSERT INTO ORDNING_EMNEORD(ORDNING,EMNE_ORD) `r`n VALUES('$ordning', '$emne')"
               
                try{

                    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
                    $connection.Open();
        
                    if($connection.State -eq "Open"){

                        #Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999

                        Write-Host Created new Emne ord: 
                        Write-Host EMNE_ORD : $emne -ForegroundColor Green
                        Write-Host Ordning : $ordning -ForegroundColor Green
                        Write-Host
                    }
                            
                }catch{
                    Write-Error $_
                }finally{
                    $connection.Close()
                }

            }else{
                Write-Host Emne Ord "'$emne'" already exists. -ForegroundColor Yellow
                Write-Host
            }
        }
    }
}