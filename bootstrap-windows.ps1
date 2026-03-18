[CmdletBinding()]
param(
    [switch]$SkipHostApps,
    [switch]$SkipWsl
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message"
}

function Fail {
    param([string]$Message)
    throw $Message
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-WingetPackage {
    param([string]$Id)

    if (winget list --id $Id --exact | Select-String -SimpleMatch $Id) {
        Write-Step "$Id already installed"
        return
    }

    Write-Step "Installing $Id with winget"
    winget install --id $Id --exact --accept-package-agreements --accept-source-agreements
}

function Convert-ToWslPath {
    param([string]$WindowsPath)

    $resolved = (Resolve-Path $WindowsPath).Path
    $drive = $resolved.Substring(0, 1).ToLowerInvariant()
    $pathWithoutDrive = $resolved.Substring(2).Replace('\', '/')
    return "/mnt/$drive$pathWithoutDrive"
}

function Get-InstalledDistros {
    $output = & wsl.exe -l -q 2>$null
    if (-not $output) {
        return @()
    }

    return $output |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ }
}

$RepoRoot = (Resolve-Path $PSScriptRoot).Path

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Fail "winget is required on the Windows host."
}

if (-not $SkipHostApps) {
    Install-WingetPackage "WezTerm.WezTerm"
    Install-WingetPackage "Microsoft.VisualStudioCode"

    Write-Step "Installing WezTerm config"
    Copy-Item -Force (Join-Path $RepoRoot "config/wezterm/wezterm.lua") (Join-Path $HOME ".wezterm.lua")
}

if (-not $SkipWsl) {
    $distros = Get-InstalledDistros

    if ($distros -notcontains "Ubuntu") {
        if (-not (Test-Administrator)) {
            Fail "Run bootstrap-windows.ps1 as Administrator to install WSL Ubuntu."
        }

        Write-Step "Installing WSL Ubuntu"
        & wsl.exe --install -d Ubuntu
        Write-Step "WSL installation started. Reboot if Windows asks, then rerun bootstrap-windows.ps1."
        exit 0
    }

    Write-Step "Running shared developer bootstrap inside WSL Ubuntu"
    $wslRepoRoot = Convert-ToWslPath $RepoRoot
    & wsl.exe -d Ubuntu -- bash -lc "cd '$wslRepoRoot' && ./scripts/dev-unix.sh --target wsl-ubuntu"
}

Write-Step "Windows bootstrap complete"
