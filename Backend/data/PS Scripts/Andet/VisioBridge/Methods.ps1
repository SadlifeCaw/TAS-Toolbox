function Get-Status {
    param (
        [string]$visioFilePath
    )

    # Start Visio application
    $visio = New-Object -ComObject Visio.Application
    $visio.Visible = $false

    # Open the document
    $document = $visio.Documents.Open($visioFilePath)
    $ellipseTexts = @()

    try {
        foreach ($page in $document.Pages) {
            foreach ($shape in $page.Shapes) {
                if ($shape.Master -and $shape.NameU -like '*ellipse*') {
                    if ($shape.Text -ne "") {
                        $ellipseTexts += $shape.Text
                    }
                } elseif ($shape.Type -eq 2) {  # Grouped shapes
                    foreach ($subShape in $shape.Shapes) {
                        if ($subShape.Master -and $subShape.NameU -like '*ellipse*') {
                            if ($subShape.Text -ne "") {
                                $ellipseTexts += $subShape.Text
                            }
                        }
                    }
                }
            }
        }
    }
    finally {
        # Close the document without saving
        $document.Close($false)
        $visio.Quit()
    }

    # Ensure output is always an array
    return ,$ellipseTexts
}

