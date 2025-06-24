function Invoke-OSTCleanup {
    <#
    .SYNOPSIS
      Scan user profiles for oversized .OST files and optionally delete them.

    .EXAMPLE
      .\constellation.ps1 OSTCleanup -MinAgeDays 90 -MinSizeGB 1 -Purge
    #>
    [CmdletBinding()]
    param(
        [int]$MinAgeDays = 90,
        [int]$MinSizeGB  = 1,
        [string]$ProfilesRoot = "$env:SystemDrive\Users",
        [string]$ReportPath,
        [switch]$Purge,
        [switch]$DryRun
    )

    Write-Verbose "Scanning $ProfilesRoot (unused > $MinAgeDays days, *.ost > $MinSizeGB GB)"

    $thresholdDate = (Get-Date).AddDays(-$MinAgeDays)
    $minBytes      = $MinSizeGB * 1GB
    $results       = @()

    Get-ChildItem -Path $ProfilesRoot -Directory | ForEach-Object {
        $userProfile = $_
        # Best-effort “last used” via NTUSER.DAT timestamp; fall back to directory write time
        $ntuser = Join-Path $userProfile.FullName 'NTUSER.DAT'
        $lastUsed = if (Test-Path $ntuser) { (Get-Item $ntuser).LastWriteTime } else { $userProfile.LastWriteTime }

        if ($lastUsed -gt $thresholdDate) { return }  # Recent – skip

        Get-ChildItem -Path $userProfile.FullName -Recurse -Filter *.ost -ErrorAction SilentlyContinue |
            Where-Object Length -gt $minBytes |
            ForEach-Object {
                $results += [pscustomobject]@{
                    Profile   = $userProfile.Name
                    LastUsed  = $lastUsed
                    OSTFile   = $_.FullName
                    SizeGB    = '{0:N2}' -f ($_.Length / 1GB)
                }
            }
    }

    if ($results.Count -eq 0) {
        Write-Host "No matching .OST files found." -ForegroundColor Cyan
        return
    }

    # Output table
    $results | Format-Table -AutoSize

    # CSV/JSON report
    if ($ReportPath) {
        $ext = [IO.Path]::GetExtension($ReportPath)
        if ($ext -eq '.json') { $results | ConvertTo-Json -Depth 3 | Set-Content $ReportPath }
        else                  { $results | Export-Csv     $ReportPath -NoTypeInformation }
        Write-Host "`nReport written to $ReportPath"
    }

    # Purge
    if ($Purge) {
        $toDelete = $results.OSTFile
        if ($DryRun) {
            Write-Warning "`nDry-run: $($toDelete.Count) files *would* be deleted."
        } else {
            Write-Host "`nDeleting $($toDelete.Count) files…" -ForegroundColor Yellow
            $toDelete | Remove-Item -Force -Verbose
        }
    }
}
