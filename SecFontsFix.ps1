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
	Write-Host "`n`n`n"
    Write-Host "Start Sec Fonts Render Fix..."
    $secFontsPath = "$PSScriptRoot\secfonts"
    Set-Location "$env:ProgramFiles\Android"

    $found = $false

    Get-ChildItem -Directory | ForEach-Object {
        $dir = $_.FullName
        $fontsDirectory = "$dir\plugins\design-tools\resources\layoutlib\data\fonts"
        if (Test-Path $fontsDirectory) {
			Write-Host "Working on $fontsDirectory..."
            $found = $true
            $fontsBackupDirectory = "$dir\plugins\design-tools\resources\layoutlib\data\fonts_backup"
            if (!(Test-Path $fontsBackupDirectory)) {
                Write-Host "Creating backup of original fonts..."
                Copy-Item -Path $fontsDirectory -Destination $fontsBackupDirectory -Recurse
            } else {
                Write-Host "Fonts backup already exists, skipping backup..."
            }
            Write-Host "Copying sec font ttf files..."
            robocopy $secFontsPath $fontsDirectory *.ttf /IS /IM /XC /XN /njh /njs /ndl /nc /ns /np /nfl /ndl
            Write-Host "... done!"
            Write-Host ""
			# Merge contents of fonts.xml with patch to AS fonts.xml
            $fontsXmlPath = Join-Path $fontsDirectory "fonts.xml"
			if (Test-Path $fontsXmlPath) {
				Write-Host "Merging sec fonts.xml to android studio fonts.xml..."
				$patchFilePath = Join-Path $secFontsPath "fonts.xml"
				$mainXml = [xml](Get-Content $fontsXmlPath)
				$patchXml = [xml](Get-Content $patchFilePath)
				Merge-XmlContents -mainXml $mainXml -patchXml $patchXml
				$mainXml.Save($fontsXmlPath)
				Write-Host "... done!"
			} else {
				Write-Host "fonts.xml not found in android studio fonts directory!"
			}
			Write-Host ""
			
			# Merge contents of fonts.xml with patch to AS font_fallback.xml
            
            $fontFallbackXmlPath = Join-Path $fontsDirectory "font_fallback.xml"
			if (Test-Path $fontFallbackXmlPath) {
				Write-Host "Merging sec fonts.xml to android font_fallback.xml..."
				$patchFilePath = Join-Path $secFontsPath "fonts.xml"
				$mainXmlFallback = [xml](Get-Content $fontFallbackXmlPath)
				$patchXml = [xml](Get-Content $patchFilePath)
				Merge-XmlContents -mainXml $mainXmlFallback -patchXml $patchXml
				$mainXmlFallback.Save($fontFallbackXmlPath)
				Write-Host "... done!"
			} else {
				Write-Host "font_fallback.xml not found in android studio fonts directory!"
			}
        } else {
            Write-Host "plugins\design-tools\resources\layoutlib\data\fonts not found in $dir, skipping..."
        }
		Write-Host "`n`n`n"
    }

    if (-not $found) {
        Write-Host "Error: No plugins\design-tools\resources\layoutlib\data\fonts directory found in any subfolder of ProgramFiles\Android." -ForegroundColor Red
    } else {
        Write-Host "Done!"
		Write-Host "Restart android studio to take effect."
    }

    Pause
}

# Function to run Script 2
function Run-RestoreStockFonts {
    Set-Location "$env:ProgramFiles\Android"
    Get-ChildItem -Directory | ForEach-Object {
        $dir = $_.FullName
        if (Test-Path "$dir\plugins\design-tools\resources\layoutlib\data\fonts_backup") {
            Write-Host "Restoring original fonts for $dir from backup..."
            Remove-Item -Path "$dir\plugins\design-tools\resources\layoutlib\data\fonts" -Recurse -Force
            Rename-Item "$dir\plugins\design-tools\resources\layoutlib\data\fonts_backup" fonts
            Write-Host "Done!"
			Write-Host ""
        } else {
            Write-Host "Error: fonts_backup folder not found for $dir!"
        }
    }

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
