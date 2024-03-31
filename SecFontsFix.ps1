# Function to check if running as administrator
function Run-as-admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Main script execution
if (-not (Run-as-admin)) {
    # Relaunch script as administrator
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Write-Host "Running your PowerShell script with elevated privileges..."

function Show-Menu {
    Write-Host "Select an option:"
    Write-Host "1. Sec Fonts Render Fix"
    Write-Host "2. Restore Stock Fonts"
    Write-Host "3. Exit"
}

# Function to merge XML contents
function Merge-XmlContents {
    param (
        [xml]$mainXml,
        [xml]$patchXml
    )
    # Find the <familyset> node in the main XML
    $familysetNode = $mainXml.SelectSingleNode("//familyset")
    if ($familysetNode -eq $null) {
        Write-Host "Error: <familyset> node not found in the main XML."
        return
    }
    # Iterate through <family> nodes in patch XML and append them to main XML
    foreach ($familyNode in $patchXml.SelectNodes("//family")) {
        $importedNode = $mainXml.ImportNode($familyNode, $true)
        [void]$familysetNode.AppendChild($importedNode)
    }
}


# Function to run Script 1
function Run-SecFontsFix {
    Write-Host "Start Sec Fonts Render Fix..."
    $secFontsPath = "$PSScriptRoot\secfonts"
    Set-Location "$env:ProgramFiles\Android"
    Get-ChildItem -Directory | ForEach-Object {
        $dir = $_.FullName
		$fontsDirectory = "$dir\plugins\design-tools\resources\layoutlib\data\fonts"
		if (!(Test-Path $fontsDirectory)) {
            Write-Host "plugins\design-tools\resources\layoutlib\data\fonts not found in $dir, skipping..."
            continue
        }
        $fontsBackupDirectory = "$dir\plugins\design-tools\resources\layoutlib\data\fonts_backup"
        if (!(Test-Path $fontsBackupDirectory)) {
            Write-Host "Creating backup of original fonts..."
            Copy-Item -Path $fontsDirectory -Destination $fontsBackupDirectory -Recurse
        } else {
            Write-Host "Fonts backup already exists, skipping backup..."
        }
        Write-Host "Copying sec font tff files..."
		robocopy $secFontsPath $fontsDirectory *.ttf /IS /IM /XC /XN /njh /njs /ndl /nc /ns /np /nfl /ndl
       
        # Merge contents of fonts.xml with patch
		Write-Host "Merging sec fonts.xml..."
        $fontsXmlPath = Join-Path $fontsDirectory "fonts.xml"
        $patchFilePath = Join-Path $secFontsPath "fonts.xml"
        $mainXml = [xml](Get-Content $fontsXmlPath)
        $patchXml = [xml](Get-Content $patchFilePath)
        Merge-XmlContents -mainXml $mainXml -patchXml $patchXml
        $mainXml.Save($fontsXmlPath)
    }
    Write-Host "Done!"
	pause
}

# Function to run Script 2
function Run-RestoreStockFonts {
    Set-Location "$env:ProgramFiles\Android"
    Get-ChildItem -Directory | ForEach-Object {
        $dir = $_.FullName
        if (Test-Path "$dir\plugins\design-tools\resources\layoutlib\data\fonts_backup") {
            Write-Host "Restoring original fonts from backup..."
            Remove-Item -Path "$dir\plugins\design-tools\resources\layoutlib\data\fonts" -Recurse -Force
            Rename-Item "$dir\plugins\design-tools\resources\layoutlib\data\fonts_backup" fonts
        }
    }
    Write-Host "Done!"
    Pause
}


# Main script loop
$continue = $true
while ($continue) {
    Clear-Host
    Show-Menu
    $choice = Read-Host "Enter your choice"
    switch ($choice) {
        '1' {
            Run-SecFontsFix
        }
        '2' {
            Run-RestoreStockFonts
        }
        '3' {
            Write-Host "Exiting..."
			sleep 1
			$continue = $false
        }
        default {
            Write-Host "Invalid choice. Please select again."
            Start-Sleep -Seconds 1
        }
    }
}

