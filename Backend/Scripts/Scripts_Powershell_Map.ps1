$rootPath = "Backend\data\PS Scripts"

$configFiles = Get-ChildItem -Path $rootPath -Recurse -Include "Config*.ps1" -File
$result = @()

# Define ignore list
$ignoreVariables = @(
    '$true', '$false', '$null', '$args', '$PSItem', '$this', '$using',
    '$input', '$env', '$host', '$error', '$maxCharLength', '$connectionstring'
)

foreach ($file in $configFiles) {
    $scriptFolder = Split-Path $file.DirectoryName -Leaf
    $topicFolder  = Split-Path (Split-Path $file.DirectoryName -Parent) -Leaf
    $content = Get-Content $file.FullName

    $variables = @()

    foreach ($line in $content) {
        # Remove comments from the line
        $code = $line -replace '#.*$', '' 
        $code = $line -replace '\) -.*$', ')'
        if ($code -match '^\s*\$(\w+)\s*=\s*(.+)') {
            $name = "$" + $matches[1]
            $value = $matches[2].Trim()

            if (-not ($ignoreVariables -contains $name)) {
                # Infer type
                $type = switch -Regex ($value) {
                    '^".*"$'         { 'string'; break }
                    "^\'.*\'$"       { 'string'; break }
                    '^\d+$'          { 'int'; break }
                    '^\d+\.\d+$'     { 'float'; break }
                    '^\$true|\$false$' { 'bool'; break }
                    '^\@\(.*\)$'     { 'array'; break }
                    '^\@\{.*\}$'     { 'hashtable'; break }
                    '^\$null$'       { 'null'; break }
                    default          { 'string' }
                }

                $variables += [PSCustomObject]@{
                    name    = $name
                    type    = $type
                    example = $value
                }
            }
        }
    }

    $result += [PSCustomObject]@{
        topic      = $topicFolder
        script     = $scriptFolder
        configPath = "$topicFolder/$scriptFolder"
        variables  = $variables | Sort-Object name
    }
}

# Export to JSON
$json = $result | ConvertTo-Json -Depth 5

# Remove \" and \u0027 entirely
$json = $json -replace '\\"', ''     # Remove all instances of \"
$json = $json -replace '\\u0027', '' # Remove all instances of \u0027

# Write to file
$json | Out-File -FilePath "$rootPath\..\..\..\src\helper\script-powershell-map.json" -Encoding UTF8

Write-Host "Cleaned JSON written to $rootPath\..\..\..\src\helper\script-powershell-map.json" -ForegroundColor Green
