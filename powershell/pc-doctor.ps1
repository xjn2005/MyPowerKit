$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor

$total = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
$free = [math]::Round(($os.FreePhysicalMemory * 1KB) / 1GB, 1)
$used = [math]::Round($total - $free, 1)

Write-Host "`n== 电脑概览 ==" -ForegroundColor Cyan
Write-Host "型号：$($cs.Manufacturer) $($cs.Model)"
Write-Host "CPU ：$($cpu.Name)"
Write-Host "内存：$used GB 已用 / $total GB 总计"

Write-Host "`n== 磁盘空间 ==" -ForegroundColor Cyan
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID,
        @{Name='可用(GB)'; Expression={[math]::Round($_.FreeSpace / 1GB, 1)}},
        @{Name='总计(GB)'; Expression={[math]::Round($_.Size / 1GB, 1)}} |
    Format-Table -AutoSize

Write-Host "== 内存占用前 8 ==" -ForegroundColor Cyan
Get-Process |
    Sort-Object WorkingSet64 -Descending |
    Select-Object -First 8 Name, Id,
        @{Name='内存(GB)'; Expression={[math]::Round($_.WorkingSet64 / 1GB, 2)}} |
    Format-Table -AutoSize
