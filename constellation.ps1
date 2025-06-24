<#  
.SYNOPSIS
  Constellation CLI launcher.

.DESCRIPTION
  Dot-sources the requested module from .\modules and invokes its
  exposed entry point (Invoke-<ModuleName>) with any remaining args.

.EXAMPLE
  .\constellation.ps1 IPScanner -Subnet 192.168.10.0/24 -Ports 22,80,443
#>

param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$Module,

    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$ModuleArgs
)

# Load shared logging
. "$PSScriptRoot\utils\logging.ps1"

# Auto-help / module discovery
if (-not $Module -or $Module -in @('help','--help','-h')) {
    Write-Log -Level INFO -Message "Available modules:`n"
    Get-ChildItem "$PSScriptRoot\modules" -Filter '*.ps1' | ForEach-Object {
        $synopsis = (Select-String -Path $_.FullName -Pattern '^\.SYNOPSIS' -Context 0,1 |
                     ForEach-Object { $_.Context.PostContext[0].Trim() })
        Write-Host ("  {0,-20} {1}" -f $_.BaseName, $synopsis)
    }
    exit 0
}

# Load JSON defaults
$configPath = Join-Path $PSScriptRoot 'constellation.json'
if (Test-Path $configPath) {
    try {
        $Config = Get-Content $configPath -Raw | ConvertFrom-Json
        Write-Log -Level DEBUG -Message "Loaded config from $configPath"
    } catch {
        Write-Log -Level WARN  -Message "Failed parsing ${configPath}: $_"
        $Config = @{}
    }
} else {
    $Config = @{}
}

# Inject defaults if missing
if ($Config.$Module) {
    foreach ($prop in $Config.$Module.PSObject.Properties.Name) {
        if (-not ($ModuleArgs -contains "-$prop")) {
            $value = $Config.$Module.$prop
            $ModuleArgs += "-$prop"; $ModuleArgs += $value
            Write-Log -Level DEBUG -Message "Injected default -$prop $value"
        }
    }
}

# Locate and load module
$moduleFile = Join-Path $PSScriptRoot "modules\$Module.ps1"
if (-not (Test-Path $moduleFile)) {
    Write-Error "Module '$Module' not found in .\modules\"
    exit 1
}

. $moduleFile

$entryPoint = "Invoke-$Module"
if (-not (Get-Command $entryPoint -ErrorAction SilentlyContinue)) {
    Write-Error "Entry point '$entryPoint' not exported by $moduleFile"
    exit 1
}