Import-Module "$PSScriptRoot\Config.ps1"
# ==== FILE PATHS ====
$ScriptFolder = $PSScriptRoot
$RunScriptName = "Run_stored_procedure.ps1"
$LogFile = "$ScriptFolder\Log_Run_sp_indsendNotifikation.txt"

# ==== SCHEDULED TASK CONFIG ====
$TaskName = "Run_$StoredProcedureName"
$Description = "Executes a stored procedure daily at 23:00 to detect and log potential failures in journalizing that may block email dispatches."
$ScheduleTime = "23:00"  # Format: HH:mm

# Color definitions
$stepColor = "White"
$infoColor = "Gray"
$successColor = "Green"
$errorColor = "Red"

function Show-Step {
    param([string]$message)
    Write-Host ""
    Write-Host "=== $message ===" -ForegroundColor $stepColor
}

# STEP 1: Install stored procedure
Show-Step "STEP 1: Installing Stored Procedure on $SqlServer\$Database"

# Read all lines from the original SQL file
$sqlContent = Get-Content -Path $sqlFile

# Replace the USE statement (assumes it's the first non-empty line)
for ($i = 0; $i -lt $sqlContent.Length; $i++) {
    if ($sqlContent[$i] -match '^\s*USE\s+\[.*\]') {
        $sqlContent[$i] = "USE [$Database]"
        break
    }
}

# Write the modified content to a temp file
$tempSqlFile = Join-Path $env:TEMP "temp_sp_indsendNotifikation.sql"
$sqlContent | Set-Content -Path $tempSqlFile -Encoding UTF8

Write-Host $tempSQLFile

try {
    Invoke-Sqlcmd -ServerInstance $SqlServer -Database $Database -InputFile $tempSqlFile -ErrorAction Stop
    Write-Host "Stored procedure installed successfully." -ForegroundColor $successColor
} catch {
    Write-Host "`nError installing stored procedure:" -ForegroundColor $errorColor
    Write-Host $_.Exception.Message -ForegroundColor $errorColor
    exit 1
}

# STEP 2: Create run script
Show-Step "STEP 2: Creating Run Script"

$runScriptPath = "$ScriptFolder\$RunScriptName"
$runScriptContent = @"
Import-Module SqlServer
\$connectionString = "Data Source=$SqlServer;Initial Catalog=$Database;Integrated Security=True;Connection timeout=60" 
\$log = "$LogFile"
\$query = "EXEC dbo.$StoredProcedureName"

try {
    Invoke-Sqlcmd -ConnectionString \$connectionString -Query \$query -ErrorAction Stop
    "[\$(Get-Date -Format u)] SUCCESS: Procedure executed successfully." | Out-File -Append -FilePath \$log
} catch {
    "[\$(Get-Date -Format u)] ERROR: \$($_.Exception.Message)" | Out-File -Append -FilePath \$log
}
"@
Set-Content -Path $runScriptPath -Value $runScriptContent -Encoding UTF8
Write-Host "Run script created at: $runScriptPath" -ForegroundColor $successColor

# STEP 3: Create scheduled task
Show-Step "STEP 3: Creating Scheduled Task"

Write-Host "Checking for existing scheduled task '$TaskName'..." -ForegroundColor $infoColor

try {
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    Write-Host "Scheduled task '$TaskName' already exists. Aborting." -ForegroundColor $errorColor
    exit 1
} catch {
    Write-Host "No existing scheduled task found. Creating new task..." -ForegroundColor $infoColor
}

$credential = Get-Credential

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$runScriptPath`""
$trigger = New-ScheduledTaskTrigger -Daily -At ([datetime]::ParseExact($ScheduleTime, "HH:mm", $null))
$principal = New-ScheduledTaskPrincipal -UserId $credential.UserName -LogonType Password -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet

$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings `
    -Description $Description

Register-ScheduledTask -TaskName $TaskName -InputObject $task -User $credential.UserName -Password ($credential.GetNetworkCredential().Password) -Force

Write-Host "Scheduled task '$TaskName' created to run daily at $ScheduleTime." -ForegroundColor $successColor
