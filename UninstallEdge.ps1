#Requires -Version 5.1
<#
.SYNOPSIS
    Edge Profile Sync - Uninstall v1.0
    Removes scripts from Program Files and the all-users Start Menu shortcut.
    Runs as System (admin) via Intune.
    Edge profiles are left intact.

.NOTES
    Run context : System (admin)
    Version     : 1.0
#>

$ErrorActionPreference = 'Stop'

$ScriptsDir   = "$env:ProgramFiles\EdgeProfileSync"
$StartMenuDir = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonPrograms)
$ShortcutPath = "$StartMenuDir\Edge Profile Sync.lnk"
$LogDir       = "$env:ProgramData\Logs\EdgeProfileSync"
$LogFile      = "$LogDir\Uninstall_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $LogFile -Value $line
    Write-Host $line
}

Write-Log "=== Edge Profile Sync Uninstall v1.0 started ==="

if (Test-Path $ShortcutPath) {
    Remove-Item -Path $ShortcutPath -Force -ErrorAction SilentlyContinue
    Write-Log "Start Menu shortcut removed."
} else {
    Write-Log "Start Menu shortcut not found (skipping)." 'WARN'
}

if (Test-Path $ScriptsDir) {
    Remove-Item -Path $ScriptsDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Scripts folder removed: $ScriptsDir"
} else {
    Write-Log "Scripts folder not found (skipping)." 'WARN'
}

Write-Log "=== Uninstall complete. Edge profiles are not affected. ==="
exit 0
