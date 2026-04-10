function Get-IPAddress {
    <#
    .SYNOPSIS
        Show the machine's active IPv4 addresses.

    .DESCRIPTION
        Returns all IPv4 addresses assigned to network adapters, excluding
        APIPA/link-local addresses (169.254.x.x) and the loopback address.

    .EXAMPLE
        ip
        Get-IPAddress
    #>
    [CmdletBinding()]
    param()

    $addresses = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -notmatch '^169\.254\.' -and $_.IPAddress -ne '127.0.0.1' } |
        Select-Object -ExpandProperty IPAddress

    if ($addresses) {
        $addresses
    } else {
        $fallback = [System.Net.Dns]::GetHostAddresses([System.Net.Dns]::GetHostName()) |
            Where-Object { $_.AddressFamily -eq 'InterNetwork' -and $_.ToString() -notmatch '^169\.254\.' -and $_.ToString() -ne '127.0.0.1' } |
            ForEach-Object { $_.ToString() }
        $fallback
    }
}
