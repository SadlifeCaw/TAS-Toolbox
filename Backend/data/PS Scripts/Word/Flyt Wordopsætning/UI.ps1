# Define the config and run script file paths
$configFile = "config.ps1"
$runFile = "run.ps1"

# Function to load the configuration file
function Load-Config {
    if (Test-Path $configFile) {
        . $configFile
    } else {
        # Default values if the config file doesn't exist
        $source = "TAS-SHS-SQLT01\CU2303"
        $db = "CU2303_ENS_TAS_TEST"
        $projektType = "GRL"
        $ordning = "GRL"
    }
}

# Function to save the configuration
function Save-Config {
    @"
`$source = '$($sourceTextbox.Text)'
`$db = '$($dbTextbox.Text)'
`$projektType = '$($projektTypeTextbox.Text)'
`$ordning = '$($ordningTextbox.Text)'
"@ | Out-File -FilePath $configFile -Encoding UTF8
    [System.Windows.MessageBox]::Show("Configuration saved successfully.")
}

# Function to run the script and capture output
function Run-Script {
    if (-Not (Test-Path $runFile)) {
        [System.Windows.MessageBox]::Show("Run file not found: $runFile")
        return
    }
    try {
        $output = & powershell.exe -ExecutionPolicy Bypass -File $runFile 2>&1
        $outputBox.Text = $output -join "`n"
    } catch {
        $outputBox.Text = "Error: $_"
    }
}

# Load configuration
Load-Config

# Create the UI
Add-Type -AssemblyName PresentationFramework

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$form = New-Object System.Windows.Forms.Form
$form.Text = "Config Editor & Runner"
$form.Width = 600
$form.Height = 400

# Create labels and textboxes
$labels = @("Source", "Database", "Project Type", "Ordning")
$fields = @()

for ($i = 0; $i -lt $labels.Count; $i++) {
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $labels[$i]
    $label.Top = 20 + ($i * 40)
    $label.Left = 10
    $label.Width = 100
    $form.Controls.Add($label)

    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Top = $label.Top
    $textbox.Left = 120
    $textbox.Width = 200
    $fields += $textbox
    $form.Controls.Add($textbox)
}

# Assign field values from config
$fields[0].Text = $source
$fields[1].Text = $db
$fields[2].Text = $projektType
$fields[3].Text = $ordning

# Buttons
$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = "Save Config"
$saveButton.Top = $fields[3].Top + 50
$saveButton.Left = 50
$saveButton.Width = 120
$saveButton.Add_Click({
    $sourceTextbox = $fields[0]
    $dbTextbox = $fields[1]
    $projektTypeTextbox = $fields[2]
    $ordningTextbox = $fields[3]
    Save-Config
})
$form.Controls.Add($saveButton)

$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "Run"
$runButton.Top = $saveButton.Top
$runButton.Left = 200
$runButton.Width = 120
$runButton.Add_Click({
    Run-Script
})
$form.Controls.Add($runButton)

# Output box for script logs
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.Top = $runButton.Top + 50
$outputBox.Left = 10
$outputBox.Width = 550
$outputBox.Height = 200
$form.Controls.Add($outputBox)

# Show the form
[void]$form.ShowDialog()
