# Function to check if running as administrator
function Run-as-admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent() )
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
    param (
        [string]$CurrentInstallDir
    )
    Write-Host "Select an option:"
    if ($CurrentInstallDir) {
        Write-Host "1. Set Android Studio's Installation Directory (Current: $CurrentInstallDir)"
    } else {
        Write-Host "1. Set Android Studio's Installation Directory (No directory set)"
    }
    Write-Host "2. Sec Fonts Render Fix"
    Write-Host "3. Restore Stock Fonts"
    Write-Host "4. Exit"
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

# Path to config file
$configFile = Join-Path $PSScriptRoot "config.txt"

# Function to get or set install directory
function Get-InstallDirectory {
    param (
        [string]$ConfigFilePath
    )
    if (Test-Path $ConfigFilePath) {
        $dir = Get-Content $ConfigFilePath -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($dir -and (Test-Path $dir)) {
            return $dir
        }
    }
    return $null
}

function Set-InstallDirectory {
    param (
        [string]$ConfigFilePath
    )
    Write-Host "Enter the  installation directory path of android studio. E.g: C:\Program Files\Android\Android Studio"
    $userDir = Read-Host "Hit Enter key when done or to go back to the main menu"
    $userDir = $userDir.Trim()
    if ([string]::IsNullOrWhiteSpace($userDir)) {
        Write-Host "No directory entered."
        Start-Sleep -Seconds 2
        return $null
    }
    if (-not (Test-Path $userDir)) {
        Write-Host "Directory does not exist." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return $null
    } else {
        $fontsDirectory = Join-Path $userDir "plugins\design-tools\resources\layoutlib\data\fonts"
        if (-not (Test-Path $fontsDirectory)){
            Write-Host "Invalid directory; $fontsDirectory not found." -ForegroundColor Red
            Start-Sleep -Seconds 2
            return $null
        }
    }
    Set-Content -Path $ConfigFilePath -Value $userDir
    Write-Host "Installation directory set to: $userDir"
    return $userDir
}

$installDir = Get-InstallDirectory -ConfigFilePath $configFile

# Function to run Script 1
function Run-SecFontsFix {
    Write-Host "`n`n"
    Write-Host "Start Sec Fonts Render Fix..."
    $secFontsPath = "$PSScriptRoot\secfonts"
    $found = $false

    if (Test-Path $installDir) {
        $fontsDirectory = Join-Path $installDir "plugins\design-tools\resources\layoutlib\data\fonts"
        if (Test-Path $fontsDirectory) {
            Write-Host "Working on $fontsDirectory..."
            $found = $true
            $fontsBackupDirectory = Join-Path $installDir "plugins\design-tools\resources\layoutlib\data\fonts_backup"
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
        }

        if (-not $found) {
            Write-Host "$fontsDirectory not found." -ForegroundColor Red
        } else {
            Write-Host "Done!"
            Write-Host "Restart android studio to take effect."
        }
    } else {
        Write-Host "$installDir does not exist." -ForegroundColor Red
    }

    Pause
}

# Function to run Script 2
function Run-RestoreStockFonts {
    if (Test-Path $installDir) {
        $backupFontsDir = Join-Path $installDir "plugins\design-tools\resources\layoutlib\data\fonts_backup"
        $fontsDir = Join-Path $installDir "plugins\design-tools\resources\layoutlib\data\fonts"
        if (Test-Path $backupFontsDir) {
            Write-Host "Restoring $installDir original fonts from backup..."
            Remove-Item -Path "$fontsDir" -Recurse -Force
            Rename-Item "$backupFontsDir" fonts
            Write-Host "Done!"
            Write-Host ""
        } else {
            if (Test-Path $fontsDir) {
                Write-Host "$backupFontsDir not found."
            } else {
                Write-Host "$installDir directory is invalid." -ForegroundColor Red
            }
        }
    } else {
        Write-Host "$installDir does not exist." -ForegroundColor Red
    }

    Pause
}

# Main menu loop
$continue = $true
while ($continue) {
    Clear-Host
    Show-Menu -CurrentInstallDir $installDir
    $choice = Read-Host "Enter your choice (1-4)"
    switch ($choice) {
        "1" {
            $installDir = Set-InstallDirectory -ConfigFilePath $configFile
        }
        "2" {
            Run-SecFontsFix
        }
        "3" {
            Run-RestoreStockFonts
        }
        "4" {
            Write-Host "Exiting..."
            sleep 1
            $continue = $false
        }
        default {
            Write-Host "Invalid selection. Please choose 1-4."
            Start-Sleep -Seconds 1
        }
    }
}
