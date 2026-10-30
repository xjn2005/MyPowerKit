param(
    [switch]$Detail
)

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem

$total = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
$free = [math]::Round(($os.FreePhysicalMemory * 1KB) / 1GB, 1)
$used = [math]::Round($total - $free, 1)

Write-Host "`n内存：$used GB 已用 / $total GB，总可用：$free GB" -ForegroundColor Cyan
Write-Host "`n== 占用最多的程序 ==" -ForegroundColor Cyan

Get-Process |
    Where-Object { $_.WorkingSet64 -gt 20MB } |
    Group-Object ProcessName |
    ForEach-Object {
        $bytes = ($_.Group.WorkingSet64 | Measure-Object -Sum).Sum

        [pscustomobject]@{
            程序   = $_.Name
            进程数 = $_.Count
            内存GB = [math]::Round($bytes / 1GB, 2)
            Bytes  = $bytes
        }
    } |
    Sort-Object Bytes -Descending |
    Select-Object -First 12 程序, 进程数, 内存GB |
    Format-Table -AutoSize

if ($Detail) {
    Write-Host "`n== 单个进程明细 ==" -ForegroundColor Yellow

    Get-Process |
        Sort-Object WorkingSet64 -Descending |
        Select-Object -First 20 Name, Id,
            @{Name='内存(GB)'; Expression={[math]::Round($_.WorkingSet64 / 1GB, 2)}} |
        Format-Table -AutoSize
}
