# Actual location of your SQL files
$rootPath = "Backend\data\SQL Scripts"
$absoluteRoot = (Resolve-Path $rootPath).Path

$sqlFiles = Get-ChildItem -Path $absoluteRoot -Recurse -Include "*.sql" -File
$result = @()

foreach ($file in $sqlFiles) {
    $topicFolder = Split-Path $file.DirectoryName -Leaf
    $scriptName = $file.Name

    # Path relative to SQL Scripts (for API fetch to work)
    $relativePath = $file.FullName.Substring($absoluteRoot.Length).TrimStart('\') -replace '\\', '/'
    $filePath = "SQL Scripts/$relativePath"

    $result += [PSCustomObject]@{
        topic    = $topicFolder
        script   = $scriptName
        filePath = $filePath
    }
}

# Output JSON to helper folder
$outputPath = "src\helper\script-sql-map.json"
$json = $result | ConvertTo-Json -Depth 5
$json | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "SQL scripts JSON written to $outputPath" -ForegroundColor Green
