# PowerShell 版本使用说明

## 跨平台支持

本项目的 PowerShell 脚本（`batch7z.ps1` 和 `batchun7z.ps1`）支持以下平台：
- **Windows**：使用 7-Zip
- **macOS/Linux**：使用 p7zip

## macOS/Linux 环境配置

### 1. 安装 p7zip

**macOS:**
```bash
brew install p7zip
```

**Linux (Debian/Ubuntu):**
```bash
sudo apt-get install p7zip-full
```

**Linux (Arch Linux):**
```bash
sudo pacman -S p7zip
```

### 2. 验证安装

```bash
# 检查 7z 命令是否可用
7z --version
```

### 3. 运行 PowerShell 脚本

在 macOS/Linux 上运行 PowerShell 脚本：

```bash
# 方法1：使用 pwsh 命令（推荐）
pwsh -File ./batch7z.ps1
pwsh -File ./batchun7z.ps1

# 方法2：先进入 PowerShell 环境
pwsh
./batch7z.ps1
./batchun7z.ps1
```

**注意：** 在 macOS/Linux 上需要使用 `pwsh` 命令来启动 PowerShell，而不是像 Windows 上那样直接运行 `.ps1` 文件。

## Windows 环境配置

### 1. 安装 7-Zip

下载并安装 7-Zip：https://www.7-zip.org/

安装时选择将 7-Zip 添加到系统 PATH。

### 2. 验证安装

打开 PowerShell 或命令提示符：

```powershell
# 检查 7z 命令是否可用
7z
```

### 3. 运行 PowerShell 脚本

```powershell
# 在当前目录运行
.\batch7z.ps1
.\batchun7z.ps1

# 压缩指定目录
.\batch7z.ps1 -d "C:\path\to\dir"

# 设置密码
.\batch7z.ps1 -p "mypassword"
```

## 脚本权限设置

### macOS/Linux

首次运行 PowerShell 脚本前，可能需要设置执行权限：

```bash
chmod +x batch7z.ps1
chmod +x batchun7z.ps1
```

如果遇到执行策略限制，可以临时修改执行策略：

```powershell
# 在 PowerShell 中运行
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Windows

如果遇到执行策略限制，可以临时修改：

```powershell
# 以管理员身份运行 PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
```

或者使用 `-ExecutionPolicy Bypass` 参数：

```powershell
powershell -ExecutionPolicy Bypass -File .\batch7z.ps1
```

## 参数说明

### batch7z.ps1（批量压缩）

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-d` | 指定目标压缩目录 | 当前目录 |
| `-p` | 指定压缩包密码 | 不设置密码 |
| `-h` | 显示帮助信息 | - |

**示例：**

```powershell
# macOS/Linux
pwsh -File ./batch7z.ps1
pwsh -File ./batch7z.ps1 -d "/Volumes/work/projects"
pwsh -File ./batch7z.ps1 -p "mypassword"

# Windows
.\batch7z.ps1
.\batch7z.ps1 -d "C:\Projects"
.\batch7z.ps1 -p "mypassword"
```

### batchun7z.ps1（批量解压）

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-d` | 指定目标解压目录 | 当前目录 |
| `-p` | 指定解压包密码 | 不设置密码 |
| `-s` | 指定目录剥离层级 strip | 0 |
| `-f` | 强制覆盖已存在文件 | False |
| `-h` | 显示帮助信息 | - |

**示例：**

```powershell
# macOS/Linux
pwsh -File ./batchun7z.ps1
pwsh -File ./batchun7z.ps1 -d "/Volumes/work/restore"
pwsh -File ./batchun7z.ps1 -p "mypassword" -s 2
pwsh -File ./batchun7z.ps1 -f

# Windows
.\batchun7z.ps1
.\batchun7z.ps1 -d "C:\Restore"
.\batchun7z.ps1 -p "mypassword" -s 2
.\batchun7z.ps1 -f
```

## 常见问题

### Q1: 在 macOS 上运行脚本提示"未找到 7z 命令"

**A:** 确保已安装 p7zip 并且 7z 命令在 PATH 中：

```bash
# 检查 p7zip 是否安装
brew list p7zip

# 检查 7z 命令是否可用
which 7z

# 如果不在 PATH 中，创建软链接
sudo ln -s /usr/local/bin/7z /usr/local/bin/7zz
```

### Q2: PowerShell 脚本无法执行

**A:** 需要修改 PowerShell 执行策略：

```powershell
# 查看当前执行策略
Get-ExecutionPolicy

# 临时设置为允许脚本执行
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Q3: 路径分隔符问题

**A:** 脚本会自动检测操作系统并使用正确的路径分隔符：
- Windows: `\`
- macOS/Linux: `/`

### Q4: 如何自定义 7z 路径

**A:** 编辑脚本文件，找到 `$7zPath` 变量并修改：

```powershell
# Windows
$7zPath = "C:\Program Files\7-Zip\7z.exe"

# macOS/Linux
$7zPath = "/usr/local/bin/7z"
```

## 功能特性

### batch7z.ps1
- ✅ 批量压缩一级子目录为 .7z 文件
- ✅ 打包当前目录下的非压缩文件
- ✅ 自动排除已压缩格式：.7z, .rar, .gz, .xz, .zip, .tar, .tgz, .bz2, .iso, .dmg
- ✅ 自动过滤：*.log, *.tmp, .DS_Store, node_modules/, .next/
- ✅ 支持自定义密码
- ✅ 默认不设置密码（不会提示输入密码）

### batchun7z.ps1
- ✅ 批量解压 .7z 压缩包
- ✅ 支持 strip 功能（剥离前 N 层目录）
- ✅ 支持强制覆盖或跳过已存在文件
- ✅ 支持自定义密码
- ✅ 默认不设置密码

## 文件命名格式

### 压缩文件
- 子目录：`子目录名_YYYY-MM-DD_HH-MM.7z`
- 文件：`当前目录名_files_YYYY-MM-DD_HH-MM.7z`

### 示例
```
myproject/
├── app/                        → app_2026-01-16_14-30.7z
├── lib/                        → lib_2026-01-16_14-30.7z
├── README.md                   →
├── package.json                → myproject_files_2026-01-16_14-30.7z
├── installer.dmg               → （已排除，不打包）
└── backup.tar.gz              → （已排除，不打包）
```

## 与 Bash 版本的对比

| 特性 | Bash 版本 | PowerShell 版本 |
|------|-----------|----------------|
| 运行环境 | macOS/Linux | Windows / macOS / Linux |
| 命令格式 | `./batch7z` | `.\batch7z.ps1` 或 `pwsh -File ./batch7z.ps1` |
| 功能特性 | 完全相同 | 完全相同 |
| 配置参数 | 完全相同 | 完全相同 |
| 跨平台 | 仅 Unix 系统 | 全平台支持 |

## 技术支持

如有问题，请检查：
1. 7-Zip/p7zip 是否正确安装
2. 7z 命令是否在 PATH 中
3. PowerShell 执行策略是否允许脚本运行
4. 脚本文件权限是否正确
