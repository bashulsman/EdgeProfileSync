#Requires -Version 5.1
<#
.SYNOPSIS
    Edge Profile Sync - Detection Script v1.0
    Detected (exit 0) when scripts exist in Program Files and the
    all-users Start Menu shortcut is present.

.NOTES
    Run context : System (admin) or User
    Version     : 1.0
#>

$ScriptsDir   = "$env:ProgramFiles\EdgeProfileSync"
$StartMenuDir = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonPrograms)
$ShortcutPath = "$StartMenuDir\Edge Profile Sync.lnk"

$scriptsOK  = Test-Path (Join-Path $ScriptsDir 'InstallEdge.ps1')
$shortcutOK = Test-Path $ShortcutPath

if ($scriptsOK -and $shortcutOK) {
    Write-Host "Detected: Edge Profile Sync v1.0 is installed."
    exit 0
} else {
    if (-not $scriptsOK)  { Write-Host "Not detected: InstallEdge.ps1 not found in $ScriptsDir" }
    if (-not $shortcutOK) { Write-Host "Not detected: Start Menu shortcut not found." }
    exit 1
}
