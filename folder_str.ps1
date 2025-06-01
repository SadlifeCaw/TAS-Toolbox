function Show-Tree {
    param (
        [string]$Path,
        [int]$Depth = 3,
        [string]$Prefix = ""
    )

    if ($Depth -le 0) {
        return
    }

    $items = Get-ChildItem -LiteralPath $Path -Force | Where-Object {
        $_.Name -notin @('.next', 'node_modules')
    }
    $lastIndex = $items.Count - 1

    for ($i = 0; $i -lt $items.Count; $i++) {
        $item = $items[$i]
        $isLast = ($i -eq $lastIndex)

        if ($isLast) {
            $connector = "+-- "
        } else {
            $connector = "|-- "
        }

        Write-Host "$Prefix$connector$item"

        if ($item.PSIsContainer) {
            if ($isLast) {
                $newPrefix = $Prefix + "    "
            } else {
                $newPrefix = $Prefix + "|   "
            }

            Show-Tree -Path $item.FullName -Depth ($Depth - 1) -Prefix $newPrefix
        }
    }
}

# Start from current directory
$startPath = Get-Location
Write-Host "`nFolder structure of: $startPath`n"
Show-Tree -Path $startPath
