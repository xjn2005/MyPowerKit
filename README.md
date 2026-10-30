# PowerShell Scripts

一些常用的 PowerShell 脚本。

## 安装

在仓库目录中运行：

```powershell
.\install.ps1
. $PROFILE
```

如果执行策略不允许运行脚本：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
. $PROFILE
```

## 命令

| 命令 | 说明 |
| --- | --- |
| `pcdoctor` | 检查电脑状态 |
| `memtop` | 查看内存占用 |
| `netcheck` | 检查网络状态 |
| `wslstop` | 停止 WSL |

例如：

```powershell
memtop -Detail
```

`install.ps1` 会把这些命令写入 PowerShell 的 `$PROFILE`。仓库移动后，需要在新位置重新运行一次安装脚本。
