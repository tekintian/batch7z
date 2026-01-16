# Batch7z 批量压缩工具（PowerShell 版本）
# ===================== 使用说明 =====================
# 用途：
#   1. 将目标目录下的一级子目录批量压缩为 .7z 包
#   2. 将当前目录下的非压缩包文件打包为 _files_ 日期格式的 .7z 包
#
# 基本用法：
#   .\batch7z.ps1                          # 压缩当前目录所有子目录和文件
#   .\batch7z.ps1 -d "C:\path\to\dir"     # 压缩指定目录
#   .\batch7z.ps1 -p "123456"             # 设置压缩包密码
#   .\batch7z.ps1 -h                      # 显示帮助信息
#
# 使用实例：
#   # 场景1：备份当前项目的所有子目录
#   cd C:\wwwroot
#   .\batch7z.ps1
#
#   # 场景2：压缩指定目录并设置密码
#   .\batch7z.ps1 -d "C:\Users\Username\Desktop\projects" -p "mypassword"
#
#   # 场景3：压缩多个部署包，方便传输
#   cd C:\wwwroot\vhosts
#   .\batch7z.ps1 -p "deploy2026"
#
# ===================== 配置说明 =====================
# - 压缩格式：.7z（高压缩比，兼容 WinRAR、7-Zip 等）
# - 压缩算法：LZMA2
# - 自动过滤：*.log, *.tmp, .DS_Store, node_modules/, .next/
# - 当前目录已压缩格式（不再打包）：*.7z, *.rar, *.gz, *.xz, *.zip, *.tar, *.tgz, *.bz2, *.iso, *.dmg
# - 文件命名：
#   * 子目录：子目录名_YYYY-MM-DD_HH-MM.7z
#   * 文件：当前目录名_files_YYYY-MM-DD_HH-MM.7z
# - 默认密码：不设置密码
#
# ===================== 系统要求 =====================
# Windows:
#   1. 需先安装 7-Zip：https://www.7-zip.org/
#   2. 确保 7z.exe 已添加到系统 PATH，或修改脚本中的 $7zPath 变量指向 7z.exe 的完整路径
#
# macOS/Linux:
#   1. 需先安装 p7zip：brew install p7zip (macOS)
#   2. 确保 7z 命令已添加到系统 PATH
# ===================================================

param(
    [string]$d = "",           # 目标目录
    [string]$p = "",           # 密码
    [switch]$h                 # 显示帮助
)

# ===================== 配置变量 =====================
# 7z.exe 的路径（如果已添加到 PATH，可以直接使用 "7z"）
$7zPath = "7z"

# 默认配置
$DEFAULT_PASSWORD = ""
$DEFAULT_DIR = Get-Location
$FILTER_FILES = @("*.log", "*.tmp", ".DS_Store", "node_modules\*", ".next\*")
# 定义已压缩的文件格式（不需要再次打包的压缩文件）
$CUR_PACKED_FORMATS = @("*.7z", "*.rar", "*.gz", "*.xz", "*.zip", "*.tar", "*.tgz", "*.bz2", "*.iso", "*.dmg")

# ===================== 帮助函数 =====================
function Show-Help {
    Write-Host "===== batch7z 批量压缩工具 使用帮助 =====" -ForegroundColor Cyan
    Write-Host "用途："
    Write-Host "  1. 批量压缩目标目录下的一级子目录为 .7z 包"
    Write-Host "  2. 打包当前目录下的非压缩包文件为 _files_ 日期格式的 .7z 包"
    Write-Host "格式：.\batch7z.ps1 [选项]..."
    Write-Host ""
    Write-Host "可选参数："
    Write-Host "  -d [目录路径]   指定目标压缩目录（默认：当前工作目录）"
    Write-Host "  -p [密码]       指定压缩包密码（默认：不设置密码）"
    Write-Host "  -h              显示此帮助信息并退出"
    Write-Host ""
    Write-Host "配置说明："
    Write-Host "  1. 压缩格式：.7z（兼容 7-Zip、WinRAR 等常规压缩软件）"
    Write-Host "  2. 压缩算法：LZMA2，高压缩比"
    Write-Host "  3. 自动过滤：$($FILTER_FILES -join ', ')"
    Write-Host "  4. 当前目录已压缩格式（不再打包）：$($CUR_PACKED_FORMATS -join ', ')"
    Write-Host "  5. 文件名格式："
    Write-Host "     - 子目录：子目录名_YYYY-MM-DDTHH-MM.7z"
    Write-Host "     - 文件：当前目录名_files_YYYY-MM-DDTHH-MM.7z"
    Write-Host "  6. 系统要求："
    Write-Host "     - Windows: 安装 7-Zip (https://www.7-zip.org/)"
    Write-Host "     - macOS/Linux: 安装 p7zip (brew install p7zip)"
    Write-Host "==========================================" -ForegroundColor Cyan
}

# ===================== 参数解析 =====================
# 显示帮助
if ($h) {
    Show-Help
    exit 0
}

# 设置目标目录
$TARGET_DIR = if ($d) { $d } else { $DEFAULT_DIR.Path }

# 检查目标目录是否存在
if (-not (Test-Path -Path $TARGET_DIR -PathType Container)) {
    Write-Host "❌ 错误：-d 选项指定的目录 '$TARGET_DIR' 不存在或无效！" -ForegroundColor Red
    exit 1
}

# 设置压缩密码
$COMPRESS_PASSWORD = if ($p) { $p } else { $DEFAULT_PASSWORD }

# ===================== 前置校验 =====================
# 检查 7z 命令是否可用
try {
    $null = Get-Command $7zPath -ErrorAction Stop
} catch {
    Write-Host "❌ 错误：未找到 7z 命令，请先安装相关工具！" -ForegroundColor Red
    if ($IsWindows) {
        Write-Host "  Windows: 下载 7-Zip: https://www.7-zip.org/" -ForegroundColor Yellow
    } else {
        Write-Host "  macOS/Linux: 安装 p7zip: brew install p7zip" -ForegroundColor Yellow
    }
    Write-Host "  或在脚本中修改 `$7zPath` 变量指向 7z/7z.exe 的完整路径" -ForegroundColor Yellow
    exit 1
}

# ===================== 主程序 =====================
# 切换到目标目录
Set-Location -Path $TARGET_DIR

# 生成日期标识
$CURRENT_DATE = Get-Date -Format "yyyy-MM-dd_HH-mm"

# 输出任务配置信息
Write-Host "===== 开始批量压缩子目录任务 =====" -ForegroundColor Cyan
Write-Host "目标工作目录：$((Get-Location).Path)"
if ([string]::IsNullOrEmpty($COMPRESS_PASSWORD)) {
    Write-Host "压缩配置：每个子目录单独打包，无密码"
} else {
    Write-Host "压缩配置：每个子目录单独打包，密码=已设置（隐藏显示）"
}
Write-Host "压缩格式：.7z（采用 LZMA2 压缩算法，兼容常规压缩软件）"
Write-Host "子目录过滤：$($FILTER_FILES -join ', ')"
Write-Host "日期标识：$CURRENT_DATE（格式：年-月-日_时-分钟）"
Write-Host "-----------------------------" -ForegroundColor Gray

# ===================== 批量压缩子目录 =====================
# 获取所有一级子目录
$subDirs = Get-ChildItem -Directory -Depth 0 | Where-Object { $_.Name -ne "." }

foreach ($dir in $subDirs) {
    $dirName = $dir.Name
    $compressFile = "${dirName}_${CURRENT_DATE}.7z"

    # 跳过已存在的同名压缩包
    if (Test-Path -Path $compressFile -PathType Leaf) {
        Write-Host "⚠️  已存在压缩包 $compressFile，跳过压缩" -ForegroundColor Yellow
        continue
    }

    Write-Host "正在压缩：$dirName -> $compressFile（过滤 $($FILTER_FILES -join ', ')）"

    # 构建 7z 命令参数
    $7zArgs = @(
        "a",
        "-t7z",
        "-mx=9",
        "-m0=LZMA2"
    )

    # 如果设置了密码，添加密码参数
    if (-not [string]::IsNullOrEmpty($COMPRESS_PASSWORD)) {
        $7zArgs += "-p${COMPRESS_PASSWORD}"
    }

    # 添加输出文件名和输入目录
    $7zArgs += $compressFile
    $7zArgs += $dirName

    # 添加排除文件参数
    foreach ($filter in $FILTER_FILES) {
        $7zArgs += "-xr!${filter}"
    }

    # 执行压缩命令
    $process = Start-Process -FilePath $7zPath -ArgumentList $7zArgs -NoNewWindow -Wait -PassThru

    # 检查压缩结果
    if ($process.ExitCode -eq 0) {
        if ([string]::IsNullOrEmpty($COMPRESS_PASSWORD)) {
            Write-Host "✅ $compressFile 压缩成功（无密码）" -ForegroundColor Green
        } else {
            Write-Host "✅ $compressFile 压缩成功（密码：已设置，隐藏显示）" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ $compressFile 压缩失败，请检查目录权限或工具完整性" -ForegroundColor Red
        if (Test-Path -Path $compressFile -PathType Leaf) {
            Remove-Item -Path $compressFile -Force
        }
    }
}

# ===================== 打包当前目录文件 =====================
Write-Host "-----------------------------" -ForegroundColor Gray
Write-Host "开始检查并打包当前目录文件（排除已压缩格式）..." -ForegroundColor Cyan

# 获取当前目录名
$currentDirName = Split-Path -Leaf (Get-Location)

# 定义文件包文件名
$filesPackage = "${currentDirName}_files_${CURRENT_DATE}.7z"

# 跳过已存在的文件包
if (Test-Path -Path $filesPackage -PathType Leaf) {
    Write-Host "⚠️  已存在文件包 $filesPackage，跳过压缩" -ForegroundColor Yellow
} else {
    # 获取当前目录下的一级文件（排除已压缩的文件格式）
    $filesToCompress = Get-ChildItem -File -Depth 0 | Where-Object {
        $file = $_
        # 检查文件扩展名是否在排除列表中
        $shouldExclude = $false
        foreach ($format in $CUR_PACKED_FORMATS) {
            # 移除 * 号进行匹配
            $pattern = $format -replace '\*', ''
            if ($file.Name -like "*$pattern") {
                $shouldExclude = $true
                break
            }
        }
        -not $shouldExclude
    }

    if ($filesToCompress.Count -gt 0) {
        Write-Host "发现 $($filesToCompress.Count) 个文件待打包（排除已压缩格式：$($CUR_PACKED_FORMATS -join ', ')）..."
        Write-Host "正在打包文件：$filesPackage"

        # 构建 7z 命令参数
        $7zArgs = @(
            "a",
            "-t7z",
            "-mx=9",
            "-m0=LZMA2"
        )

        # 如果设置了密码，添加密码参数
        if (-not [string]::IsNullOrEmpty($COMPRESS_PASSWORD)) {
            $7zArgs += "-p${COMPRESS_PASSWORD}"
        }

        # 添加输出文件名
        $7zArgs += $filesPackage

        # 添加排除文件参数（仅对文件打包生效）
        foreach ($filter in $FILTER_FILES) {
            $7zArgs += "-xr!${filter}"
        }

        # 逐个添加文件
        foreach ($file in $filesToCompress) {
            $7zArgs += $file.Name
        }

        # 执行压缩命令
        $process = Start-Process -FilePath $7zPath -ArgumentList $7zArgs -NoNewWindow -Wait -PassThru

        # 检查压缩结果：检查压缩包是否有效（非空）
        if (Test-Path -Path $filesPackage -PathType Leaf) {
            # 检查压缩包大小，如果为 0 字节则删除
            $fileSize = (Get-Item $filesPackage).Length
            if ($fileSize -eq 0) {
                Write-Host "⚠️  $filesPackage 压缩包为空，已删除" -ForegroundColor Yellow
                Remove-Item -Path $filesPackage -Force
            } else {
                # 格式化文件大小显示
                $fileSizeFormatted = if ($fileSize -lt 1MB) {
                    [math]::Round($fileSize / 1KB, 2).ToString() + " KB"
                } else {
                    [math]::Round($fileSize / 1MB, 2).ToString() + " MB"
                }
                if ([string]::IsNullOrEmpty($COMPRESS_PASSWORD)) {
                    Write-Host "✅ $filesPackage 压缩成功（无密码，大小：$fileSizeFormatted）" -ForegroundColor Green
                } else {
                    Write-Host "✅ $filesPackage 压缩成功（密码：已设置，隐藏显示，大小：$fileSizeFormatted）" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "❌ $filesPackage 压缩失败，请检查文件权限或工具完整性" -ForegroundColor Red
        }
    } else {
        Write-Host "当前目录下没有需要打包的文件（已排除压缩格式：$($CUR_PACKED_FORMATS -join ', ')）"
    }
}

# ===================== 任务结束统计 =====================
Write-Host "-----------------------------" -ForegroundColor Gray
Write-Host "📊 本次任务生成压缩包统计：" -ForegroundColor Cyan

$allArchives = Get-ChildItem -Filter "*_${CURRENT_DATE}.7z" -File
$totalCount = $allArchives.Count
$totalSize = ($allArchives | Measure-Object -Property Length -Sum).Sum

if ($totalSize) {
    $totalSizeFormatted = [math]::Round($totalSize / 1MB, 2).ToString() + " MB"
} else {
    $totalSizeFormatted = "0 MB"
}

Write-Host "  总数量：$totalCount 个"
Write-Host "  总大小：$totalSizeFormatted"
Write-Host "-----------------------------" -ForegroundColor Gray
Write-Host "===== 批量压缩子目录任务执行完毕 =====" -ForegroundColor Cyan
