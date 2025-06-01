#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'


if($ordning_id -ne $false){

    DoesZipExist #Does data.zip exists

    $testPath = DoesFileExist -FileName KontorOrdning.csv

    if($testPath){
        
        Title -Title 'Set-KontorOrdning'

        $KontorOrdning_csv = Import-Csv -Path $path\KontorOrdning.csv

        foreach($k in $KontorOrdning_csv){
            
            $kontor = $k.KONTOR
            $ejer = $k.EJER

            $doesKontorExist = DoesKontorExist -Kontor $kontor -Ejer $ejer
            
            if(!$doesKontorExist){
                
                $query = "INSERT INTO ORDNING_KONTOR(ORDNING, KONTOR, EJER) `r`n VALUES('$ordning', '$kontor', '$ejer')"

                try{
                    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        
                    $connection.Open();
        
                    if($connection.State -eq "Open"){
                        
                        Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength 9999999
                        Write-Host Query Executed
                        
                        Write-Host Created Kontor: 
                        Write-Host Kontor : $kontor -ForegroundColor Green
                        Write-Host Ejer : $ejer -ForegroundColor Green
                        Write-Host Ordning : $ordning -ForegroundColor Green
                    }
                    
                }catch{
                    Write-Error $_
                }
            
            }
        }
    }
}