function Invoke-PartitionFinder {
    <#
    .SYNOPSIS
      Show volumes below a free-space threshold or analyse a single volume.

    .EXAMPLE
      .\constellation.ps1 PartitionFinder -MinFreePct 15
      .\constellation.ps1 PartitionFinder -Volume C: -Analyse -TopN 5
    #>
    [CmdletBinding(DefaultParameterSetName = 'List')]
    param(
        [Parameter(ParameterSetName='List')]
        [int]$MinFreePct = 10,

        [Parameter(ParameterSetName='Analyse')]
        [string]$Volume,

        [Parameter(ParameterSetName='Analyse')]
        [int]$TopN = 10,

        [Parameter(ParameterSetName='Analyse')]
        [switch]$Analyse,

        [string]$OutputJson
    )

    if ($PSCmdlet.ParameterSetName -eq 'List') {
        Get-CimInstance -Class Win32_LogicalDisk -Filter "DriveType = 3" |
            Select-Object @{n='Volume';e={$_.DeviceID}},
                          @{n='Label'; e={$_.VolumeName}},
                          @{n='Free%'; e={[math]::Round($_.FreeSpace / $_.Size * 100,1)}},
                          @{n='SizeGB';e={[math]::Round($_.Size / 1GB,1)}} |
            Where-Object { $_.'Free%' -lt $MinFreePct } |
            Format-Table -AutoSize
        return
    }

    # -- Analyse mode --------------------------------------------------------
    if (-not (Test-Path "$Volume\")) {
        Write-Error "Volume $Volume not found."
        return
    }

    Write-Host "Analysing $Volume (top $TopN folders)…`n"

    $folderSizes = Get-ChildItem "$Volume\" -Directory |
        ForEach-Object {
            $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue |
                     Measure-Object Length -Sum).Sum
            [pscustomobject]@{ Folder = $_.FullName; SizeGB = [math]::Round($size / 1GB, 2) }
        } |
        Sort-Object SizeGB -Descending |
        Select-Object -First $TopN

    $folderSizes | Format-Table -AutoSize

    if ($OutputJson) {
        $folderSizes | ConvertTo-Json | Set-Content $OutputJson
        Write-Host "`nJSON saved to $OutputJson"
    }
}
