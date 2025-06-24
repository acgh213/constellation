<#
.SYNOPSIS
  Lightweight, severity-aware logging for Constellation.
#>
function Write-Log {
    [CmdletBinding()]
    param(
        [ValidateSet('DEBUG','INFO','WARN','ERROR')]
        [string]$Level   = 'INFO',
        [string]      $Message,
        [switch]      $NoTimestamp
    )
    $ts = if ($NoTimestamp) { '' } else { "[{0:yyyy-MM-dd HH:mm:ss}]" -f (Get-Date) }
    $line = "$ts [$Level] $Message"

    switch ($Level) {
        'ERROR' { Write-Host $line -ForegroundColor Red; break }
        'WARN'  { Write-Host $line -ForegroundColor Yellow; break }
        'INFO'  { Write-Host $line; break }
        'DEBUG' {
            if ($PSBoundParameters.ContainsKey('Debug')) { Write-Host $line }
        }
    }
}
