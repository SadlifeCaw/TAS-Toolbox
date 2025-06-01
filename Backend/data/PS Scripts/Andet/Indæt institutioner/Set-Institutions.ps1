#Author : Casper Wassa Skourup

#Getting all the methods and database connection information
#$path = Split-Path $psise.CurrentFile.FullPath
$path = $PWD.Path
. "C:\Users\P-X153157\Desktop\Indæt institutioner\Methods.ps1" 
. "C:\Users\P-X153157\Desktop\Indæt institutioner\Configs.ps1"

$update = @{} # Hashtable instead of array
$insert = ""
$InsertCount = 0
$UpdateCount = 0

if(DoesFileExist -FileName 'Institutioner.csv'){

    $institutioner_csv = Import-Csv -Path $path\Institutioner.csv -Delimiter ';'
    
        try {
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionstring
        $connection.Open()

        $query = "SELECT CVRNR, INSTITUTIONSNAVN FROM STATSLIG_KREDITOR"
        $SQLresult = Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
        $CurrentInstitutions = $SQLresult | ForEach-Object { 
            [PSCustomObject]@{
                CVRNR = $_.CVRNR
                InstitutionsNavn = $_.INSTITUTIONSNAVN
            }
        }

        foreach($f in $institutioner_csv) {
            if($f.Type -in 1,3,4) {
                $virksomhed = isNull($f.Virksomhed)
                $navn = isNull($f.Navn)

                $existingCVR = $CurrentInstitutions | Where-Object { 
                    $_.CVRNR -eq [int]($virksomhed.Replace("'", ""))
                }

                if ($existingCVR) {
                    if ($existingCVR.InstitutionsNavn -eq $navn.Replace("'", "")) {
                        #Write-Host "Institution: $navn ($virksomhed) already exists with the same name -ForegroundColor Yellow"
                    } else {
                        Write-Host "Updating Existing Institution - $virksomhed exists but with a different insitution name" "("$existingCVR.InstitutionsNavn")" -ForegroundColor Green
                        $update[[int]($virksomhed.Replace("'", ""))] = $navn # Update with the new name
                        $UpdateCount += 1
                    }
                } else {
                    Write-Host "Creating new Institution - $navn ($virksomhed)" -ForegroundColor Green
                    $insert = $insert + "($virksomhed, $navn), `r`n"
                    $InsertCount += 1
                }
            }
        }

        if($insert -ne ''){
            $insert = "INSERT INTO STATSLIG_KREDITOR(CVRNR, INSTITUTIONSNAVN) `r`n" + 'VALUES' + $insert
            $insert = $insert.Substring(0,$insert.Length-4) #remove the last ','

            $title    = 'Invoke insertion script in Database'
            $question = 'Uploading ' + $InsertCount +' Institution(s) to the database. Are you sure you want to proceed?'
            $choices  = '&Yes', '&No'

            $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
            if ($decision -eq 0) {
                Invoke-Sqlcmd -Query $insert -ConnectionString $connectionstring -MaxCharLength $maxCharLength
                Write-Host Query executed -ForegroundColor Green
            } else {
                Write-Host "Didn't Execute Insert." -ForegroundColor Yellow
            }
        } else {
             Write-Host "Nothing to insert."
        }

        if($update.Count -gt 0){
            $title    = 'Invoke update script in Database'
            $question = 'Updating ' + $UpdateCount +' Institution(s) in the database. Are you sure you want to proceed?'
            $choices  = '&Yes', '&No'

            $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
            if ($decision -eq 0) {
                foreach ($key in $update.Keys){
                    $CVR = $key
                    $InstitutionsNavn = $update[$key]
                      
                    $query = "UPDATE STATSLIG_KREDITOR
                                SET INSTITUTIONSNAVN = $InstitutionsNavn
                                WHERE CVRNR = $CVR AND INSTITUTIONSNAVN <> $InstitutionsNavn"
                    Invoke-Sqlcmd -Query $query -ConnectionString $connectionstring -MaxCharLength $maxCharLength
                    Write-Host Updated $CVR to name: $InstitutionsNavn -ForegroundColor Green
                }
            } else {
                Write-Host "Didn't Execute Update." -ForegroundColor Yellow
            }
        } else {
             Write-Host "Nothing to update." -ForegroundColor Yellow
        }

        $connection.Close()
    } catch {
        Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
    }    
}
