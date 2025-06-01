#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'
    
DoesZipExist #Does data.zip exists
   
$testPath = DoesFileExist -FileName Activities.csv

if($testPath){

    Title -Title 'Set-FinansKontoPlan'

    #Getting data 
    $activities_csv = Import-Csv -Path $path/Activities.csv -Encoding UTF8
        
    foreach($tk in $activities_csv){
        try{
            $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
            $connection.Open();

            if(![string]::IsNullOrEmpty($tk.SCR_KONTO)){
                $scr = isNull($tk.SCR_KONTO)
                $konto = isNull($tk.TAS_KONTO)
                $deb_kre_finans = isNull($tk.DEB_KRE_FINANS)
                $procent = $tk.RSK_PROCENT
                $deb_kre = isNull($tk.RSK_DEB_KRE)
                $modkonto = isNull($tk.MODKONTO)
                $year = isNull_int($tk.YEAR)
                $kontering_gruppe = isNull_int($tk.RG_KONTERING_GRUPPE)
                $ramme = isNull($tk.RAMME)
                $udligning = isNull($tk.UDLIGNING)
                $transaktion = isNull_int($tk.TRANSAKTIONSTYPE)
                $fond = isNull($tk.FOND)

                $doesFinanskontoExist = DoesFinansKontoExist -TasKonto $konto -ScrKonto $scr -DEB_KRE_FINANS $deb_kre_finans -Procent $procent -DEB_KRE $deb_kre -Modkonto $modkonto -Year $year -KonteringGruppe $kontering_gruppe -Ramme $ramme -Udligning $udligning -TransaktionsType $transaktion -Fond $fond

                if(!$doesFinanskontoExist){
                    $insert = "INSERT INTO RG_SCR_KONTOPLAN(SCR_KONTO, TAS_KONTO, DEB_KRE_FINANS, PROCENT, DEB_KRE, MODKONTO, YEAR, RG_KONTERING_GRUPPE, RAMME, UDLIGNING, TRANSAKTIONSTYPE,FOND) `r`n VALUES($scr, $konto, $deb_kre_finans, $procent, $deb_kre, $modkonto, $year, $konto_gruppe_id, $ramme, $udligning, $transaktion, $fond)"
                
                        #Invoke-Sqlcmd -Query $insert -ConnectionString $connectionstring -MaxCharLength $maxCharLength
				
			            write-host Created the Finans Kontoplan with following information: -ForegroundColor Green
                        Write-Host SCR_KONTO : $scr -ForegroundColor Green
                        Write-Host TAS_KONTO : $konto -ForegroundColor Green
                        Write-Host DEB_KRE_FINANS : $deb_kre_finans -ForegroundColor Green
                        Write-Host PROCENT : $procent -ForegroundColor Green
                        Write-Host DEB_KRE : $deb_kre -ForegroundColor Green
                        Write-Host MODKONTO : $modkonto -ForegroundColor Green
                        Write-Host YEAR : $year -ForegroundColor Green
                        Write-Host RG_KONTERING_GRUPPE : $konto_gruppe_id -ForegroundColor Green
                        Write-Host RAMME : $ramme -ForegroundColor Green
                        Write-Host UDLIGNING : $udligning -ForegroundColor Green
                        Write-Host TRANSAKTIONSTYPE : $transaktion -ForegroundColor Green
                        Write-Host FOND : $fond -ForegroundColor Green
                        Write-Host
                
                }else{
                    Write-Host Finanskonto Plan already exists: -ForegroundColor Yellow
                    Write-Host SCR_KONTO : $scr -ForegroundColor Yellow
                    Write-Host TAS_KONTO : $konto -ForegroundColor Yellow
                    Write-Host DEB_KRE_FINANS : $deb_kre_finans -ForegroundColor Yellow 
                    Write-Host PROCENT : $procent -ForegroundColor Yellow
                    Write-Host DEB_KRE : $deb_kre -ForegroundColor Yellow
                    Write-Host MODKONTO : $modkonto -ForegroundColor Yellow
                    Write-Host YEAR : $year -ForegroundColor Yellow
                    Write-Host RG_KONTERING_GRUPPE : $konto_gruppe_id -ForegroundColor Yellow
                    Write-Host RAMME : $ramme -ForegroundColor Yellow
                    Write-Host UDLIGNING : $udligning -ForegroundColor Yellow
                    Write-Host TRANSAKTIONSTYPE : $transaktion -ForegroundColor Yellow
                    Write-Host FOND : $fond -ForegroundColor Yellow
                    Write-Host
                }
            }
        }catch{
            Write-Error $_
        }finally{
            #Closing db connection
            $connection.Close() 
        }             
    }
}