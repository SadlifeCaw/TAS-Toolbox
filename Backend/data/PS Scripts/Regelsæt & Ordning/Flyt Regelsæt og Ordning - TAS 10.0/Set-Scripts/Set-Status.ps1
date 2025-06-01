#Author : Nevethan Alagaratnam

#Getting all the methods and configs.
$path = Split-Path $psise.CurrentFile.FullPath
. "$path\Configs.ps1" #Loading all Configs 
. "$path\Methods.ps1" #Loading all Methods

Preprocess # Making sure powershell has installed the module 'SqlServer'

DoesZipExist #Does data.zip exists

$testPath = DoesFileExist -FileName Status.csv

if($testpath){
    Title -Title 'Set-Status'

    $status_csv = Import-Csv -Path $path\Status.csv

    $insert = ''
    $update = ''
    $query = ''
    
    $names = @()

    foreach($s in $status_csv){
    
        $status = $s.STATUS
        $TEKST = $s.TEKST
        $ctrl = $s.CTRL_DATA
        $afløb = $s.AFLOB
        $public = $s.PublicStatus
    
        $exist = DoesStatusExist -StatusCode $status

        if ($exist -eq $false){
            $TEKST = ReplaceParenthesis -Text $TEKST
            
            if(![string]::IsNullOrEmpty($public)){
                $public= ReplaceParenthesis -Text $public
            }

            $insert = $insert + "('$status',NULL,'$TEKST','$ctrl','$afløb',NULL,NULL,'$public'), `r`n"  
        }else{
            $TEKST = ReplaceParenthesis -Text $TEKST

            if(![string]::IsNullOrEmpty($public)){
                $public= ReplaceParenthesis -Text $public
            }

            $update = $update + "UPDATE STATUS `r`n SET TEKST = '$TEKST', PublicStatus = '$public' `r`n WHERE STATUS = '$status' `r`n"
        }

        $names += $status
    }
    
    if(!([string]::IsNullOrEmpty($insert))){
        write-host "The INSERT query has been created.`r`n"
        $insert = "INSERT INTO STATUS (STATUS, STATUS_ID, TEKST, CTRL_DATA, AFLOB, INITIALER, DATO_AENDRING, PublicStatus) `r`n" + 'VALUES' + $insert
        $insert = $insert.Substring(0,$insert.Length-4) #remove the last ','
    }


    try{

        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        $connection.Open()
    
        $query = $insert + "`r`n" + $update

        #Write-Host $query
        Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength

        Write-Host Inserted/Update $names.Count elements. They are the following: -ForegroundColor Green
        $names | ForEach-Object -Process {Write-Host $_ }

        #Closing db connection
        $connection.Close()
        Write-Host "DB connection closed."

    }catch{
        $_
    }
}




