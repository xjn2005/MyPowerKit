param(
    [string[]]$Target = @(
        'github.com',
        'cavill.site',
        'blog.cavill.site',
        'www.bilibili.com'
    )
)

Write-Host "`n== 网络连通性检查 ==" -ForegroundColor Cyan

$result = foreach ($hostName in $Target) {
    try {
        $ip = [System.Net.Dns]::GetHostAddresses($hostName) |
            Where-Object { $_.AddressFamily -eq 'InterNetwork' } |
            Select-Object -First 1 -ExpandProperty IPAddressToString

        $tcp443 = Test-NetConnection `
            -ComputerName $hostName `
            -Port 443 `
            -InformationLevel Quiet `
            -WarningAction SilentlyContinue

        [pscustomobject]@{
            主机 = $hostName
            IPv4 = $ip
            HTTPS443 = if ($tcp443) { '正常' } else { '失败' }
        }
    }
    catch {
        [pscustomobject]@{
            主机 = $hostName
            IPv4 = 'DNS 失败'
            HTTPS443 = '未测试'
        }
    }
}

$result | Format-Table -AutoSize
