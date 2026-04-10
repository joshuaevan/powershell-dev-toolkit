function Clear-DNSCache {
    <#
    .SYNOPSIS
        Flush the Windows DNS resolver cache.

    .DESCRIPTION
        Calls the built-in Clear-DnsClientCache cmdlet and confirms success.
        Requires administrator privileges.

    .EXAMPLE
        Clear-DNSCache
        Flush-DNS
    #>
    [CmdletBinding()]
    param()

    try {
        Clear-DnsClientCache -ErrorAction Stop
        Write-Host "DNS cache flushed successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to flush DNS cache: $_"
        Write-Host "Tip: Run as administrator (sudo Clear-DNSCache)." -ForegroundColor Yellow
    }
}
