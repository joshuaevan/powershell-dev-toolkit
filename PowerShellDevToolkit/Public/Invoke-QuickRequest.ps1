function Invoke-QuickRequest {
    <#
    .SYNOPSIS
        Quick HTTP requests from PowerShell.

    .DESCRIPTION
        Make HTTP requests without leaving the terminal.
        Supports GET, POST, PUT, DELETE, PATCH methods.

    .PARAMETER Method
        HTTP method (GET, POST, PUT, DELETE, PATCH).

    .PARAMETER Url
        The URL to request.

    .PARAMETER Body
        Request body (hashtable or string).

    .PARAMETER Headers
        Additional headers as hashtable.

    .PARAMETER AsJson
        Return response as parsed JSON object.

    .PARAMETER Raw
        Return raw response content only.

    .EXAMPLE
        Invoke-QuickRequest GET http://localhost:3000/api/health
        http POST http://localhost:3000/api/users -Body @{name='test'}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS')]
        [string]$Method = 'GET',

        [Parameter(Position = 1, Mandatory = $true)]
        [string]$Url,

        [Parameter(Position = 2)]
        $Body,

        [hashtable]$Headers = @{},

        [switch]$AsJson,
        [switch]$Raw
    )

    $params = @{
        Uri = $Url
        Method = $Method
        UseBasicParsing = $true
        ErrorAction = 'Stop'
    }

    $defaultHeaders = @{
        'Accept' = 'application/json'
        'User-Agent' = 'PowerShell-QuickRequest/1.0'
    }

    foreach ($key in $Headers.Keys) {
        $defaultHeaders[$key] = $Headers[$key]
    }
    $params.Headers = $defaultHeaders

    if ($Body -and $Method -in @('POST', 'PUT', 'PATCH')) {
        if ($Body -is [hashtable] -or $Body -is [PSCustomObject]) {
            $params.Body = $Body | ConvertTo-Json -Depth 10
            $params.ContentType = 'application/json'
        } else {
            $params.Body = $Body
        }
    }

    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest @params
        $stopwatch.Stop()

        $contentType = $response.Headers['Content-Type'] -join ''
        $isJson = $contentType -like '*json*'

        if ($Raw) {
            return $response.Content
        }

        if ($AsJson) {
            $result = [ordered]@{
                status = $response.StatusCode
                statusDescription = $response.StatusDescription
                contentType = $contentType
                contentLength = $response.Content.Length
                elapsed = "$($stopwatch.ElapsedMilliseconds)ms"
            }

            if ($isJson) {
                try {
                    $result.body = $response.Content | ConvertFrom-Json
                } catch {
                    $result.body = $response.Content
                }
            } else {
                $result.body = $response.Content
            }

            return $result | ConvertTo-Json -Depth 10
        }

        Write-Host ""
        Write-Host "$Method " -NoNewline -ForegroundColor Cyan
        Write-Host $Url -ForegroundColor White
        Write-Host ""

        $statusColor = if ($response.StatusCode -lt 300) { 'Green' }
                       elseif ($response.StatusCode -lt 400) { 'Yellow' }
                       else { 'Red' }
        Write-Host "Status: " -NoNewline -ForegroundColor Gray
        Write-Host "$($response.StatusCode) $($response.StatusDescription)" -ForegroundColor $statusColor
        Write-Host "Time:   " -NoNewline -ForegroundColor Gray
        Write-Host "$($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor White
        Write-Host "Type:   " -NoNewline -ForegroundColor Gray
        Write-Host $contentType -ForegroundColor White
        Write-Host ""

        if ($response.Content) {
            if ($isJson) {
                try {
                    $parsed = $response.Content | ConvertFrom-Json
                    $formatted = $parsed | ConvertTo-Json -Depth 10
                    Write-Host $formatted -ForegroundColor Yellow
                } catch {
                    Write-Host $response.Content
                }
            } else {
                if ($response.Content.Length -gt 2000) {
                    Write-Host ($response.Content.Substring(0, 2000)) -ForegroundColor White
                    Write-Host "`n... (truncated, $($response.Content.Length) bytes total)" -ForegroundColor DarkGray
                } else {
                    Write-Host $response.Content -ForegroundColor White
                }
            }
        }
        Write-Host ""

    } catch {
        $errorResponse = $_.Exception.Response

        if ($AsJson) {
            $result = [ordered]@{
                status = if ($errorResponse) { [int]$errorResponse.StatusCode } else { 0 }
                error = $_.Exception.Message
            }

            if ($errorResponse) {
                try {
                    $reader = [System.IO.StreamReader]::new($errorResponse.GetResponseStream())
                    $result.body = $reader.ReadToEnd()
                    $reader.Close()
                } catch {}
            }

            return $result | ConvertTo-Json -Depth 5
        }

        Write-Host ""
        Write-Host "Request Failed" -ForegroundColor Red
        Write-Host ""

        if ($errorResponse) {
            Write-Host "Status: " -NoNewline -ForegroundColor Gray
            Write-Host "$([int]$errorResponse.StatusCode) $($errorResponse.StatusDescription)" -ForegroundColor Red
        }

        Write-Host "Error:  " -NoNewline -ForegroundColor Gray
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""
    }
}
