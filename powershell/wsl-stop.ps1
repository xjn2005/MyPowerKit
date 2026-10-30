$answer = Read-Host "停止全部 WSL 和相关 Linux 进程？(y/N)"

if ($answer -match '^[Yy]$') {
    wsl.exe --shutdown
    Write-Host "WSL 已停止，内存已释放。" -ForegroundColor Green
}
else {
    Write-Host "已取消。"
}
