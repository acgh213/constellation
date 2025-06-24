function Invoke-IPScanner {
    <#
    .SYNOPSIS
      Quick subnet ping/port scan (Angry-IP style).

    .EXAMPLE
      .\constellation.ps1 IPScanner -Subnet 192.168.1.0/24 -Ports 22,80,443 -TimeoutMS 200
    #>
    [CmdletBinding()]
    param(
        [string]$Subnet = 'auto',         # 192.168.1.0/24 or 'auto'
        [int]$TimeoutMS = 250,
        [int[]]$Ports   = @(22, 80, 443),
        [switch]$OnlyAlive,
        [string]$ExportCsv
    )

    # -------- subnet detection ----------
    if ($Subnet -eq 'auto') {
        $if = Get-NetIPAddress -AddressFamily IPv4 |
              Where-Object { $_.IPAddress -notmatch '^169\.254' -and $_.PrefixOrigin -ne 'WellKnown' } |
              Sort-Object InterfaceMetric |
              Select-Object -First 1
        if (-not $if) { throw "Couldn't auto-detect subnet." }
        $Subnet = "$($if.IPAddress)/$($if.PrefixLength)"
    }

    # -------- expand subnet -------------
    function Get-IPRange($cidr) {
        $ip, $mask = $cidr -split '/'
        $ipBytes   = [System.Net.IPAddress]::Parse($ip).GetAddressBytes()
        $maskBits  = 32 - [int]$mask
        $hostCount = [math]::Pow(2,$maskBits) - 2          # drop network + broadcast
        $base      = [System.BitConverter]::ToUInt32($ipBytes[3..0],0)
        1..$hostCount | ForEach-Object {
            $addr = $base + $_
            [System.Net.IPAddress]::Parse(($addr -band 0xFFFFFFFF))  # UInt32→IP
        }
    }

    $targets = Get-IPRange $Subnet
    Write-Verbose "Scanning $($targets.Count) hosts…"

    # -------- ping sweep ---------------
    $results = @()
$results = @()

if ($PSVersionTable.PSVersion.Major -ge 7) {
    $results = $targets | ForEach-Object -Parallel {
        param($ip, $ports, $timeout)
        $alive = Test-Connection -Quiet -Count 1 -TimeoutMilliseconds $timeout -TargetName $ip
        if (-not $alive) { return }
        $open = @()
        foreach ($p in $ports) {
            try {
                $tcp = New-Object System.Net.Sockets.TcpClient
                $iar = $tcp.BeginConnect($ip, $p, $null, $null)
                $iar.AsyncWaitHandle.WaitOne($timeout) | Out-Null
                if ($tcp.Connected) { $open += $p }
                $tcp.Close()
            } catch { }
        }
        [pscustomobject]@{
            IP        = $ip
            OpenPorts = ($open -join ',')
        }
    } -ArgumentList $Ports, $TimeoutMS
} else {
    foreach ($t in $targets) {
        Start-Job -ScriptBlock {
            param($ip, $ports, $timeout)
            $alive = Test-Connection -Quiet -Count 1 -TimeoutMilliseconds $timeout -TargetName $ip
            if (-not $alive) { return }
            $open = @()
            foreach ($p in $ports) {
                try {
                    $tcp = New-Object System.Net.Sockets.TcpClient
                    $iar = $tcp.BeginConnect($ip, $p, $null, $null)
                    $iar.AsyncWaitHandle.WaitOne($timeout) | Out-Null
                    if ($tcp.Connected) { $open += $p }
                    $tcp.Close()
                } catch { }
            }
            [pscustomobject]@{
                IP        = $ip
                OpenPorts = ($open -join ',')
            }
        } -ArgumentList $t, $Ports, $TimeoutMS
    }
    Receive-Job -Wait -AutoRemoveJob | ForEach-Object { $results += $_ }
}
    if ($OnlyAlive) { $results = $results | Where-Object IP }

    if (-not $results) {
        Write-Host "No hosts responded."
        return
    }

    $results | Sort-Object IP | Format-Table -AutoSize

    if ($ExportCsv) {
        $results | Export-Csv $ExportCsv -NoTypeInformation
        Write-Host "`nCSV exported to $ExportCsv"
    }
}
