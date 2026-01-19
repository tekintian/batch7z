<#
.SYNOPSIS
批量7z压缩工具（batch7z.ps1），与Shell版本batch7z功能对等
.DESCRIPTION
1. 批量压缩目标目录下的一级子目录为独立.7z包（带日期后缀，使用目录最后修改时间）
2. 打包目录下非压缩格式零散文件为统一_files_日期后缀.7z包（使用目录最后修改时间）
3. 支持密码保护、实时进度显示、智能过滤无用文件/目录
4. 支持强制重新压缩（覆盖已存在的压缩包）
5. 自动校验7z环境、清理空压缩包、生成任务统计报告
.PARAMETER TargetDir
指定目标压缩目录（可选，默认：当前工作目录）
.PARAMETER Password
指定压缩包密码（可选，默认：空）
.PARAMETER Force
强制重新压缩（可选，覆盖已存在的压缩包）
.PARAMETER Help
显示帮助信息（可选）
.EXAMPLE
.atch7z.ps1
# 压缩当前目录所有子目录和零散文件，使用默认密码
.EXAMPLE
.atch7z.ps1 -TargetDir "D:\Desktop\Projects" -Password "mySecurePass123"
# 压缩指定目录，使用自定义密码
.EXAMPLE
.atch7z.ps1 -Help
# 显示详细帮助信息
.NOTES
系统要求：
1. 已安装7z工具（推荐：7-Zip，下载地址：https://www.7-zip.org/）
2. 7z可执行文件路径已添加到系统环境变量PATH，或手动修改脚本中的$7zPath变量
3. 兼容Windows PowerShell 5.1（Win10/Win11自带）和PowerShell 7+
配置说明：
1. 压缩格式：.7z（高压缩比，兼容WinRAR、7-Zip等）
2. 压缩算法：LZMA2（高压缩比，对应7z的-m0=LZMA2参数）
3. 自动过滤：*.log、*.tmp、.DS_Store、node_modules、.next等
4. 已压缩格式排除：*.7z、*.rar、*.gz、*.xz、*.zip等
5. 文件命名格式：
   - 子目录：子目录名_YYYY-MM-DD_HH-mm.7z（使用目录最后修改时间）
   - 零散文件：当前目录名_files_YYYY-MM-DD_HH-mm.7z（使用目录最后修改时间）
#>

# --------------- 脚本配置区 ---------------
$DEFAULT_PASSWORD = ""
$DEFAULT_DIR = (Get-Location).Path
# 需过滤的无用文件/目录（递归排除）
$FILTER_FILES = @("*.log", "*.tmp", ".DS_Store", "node_modules\*", ".next\*", "__MACOSX\*", "Thumbs.db")
# 已压缩格式（零散文件打包时排除）
$CUR_PACKED_FORMATS = @("*.7z", "*.rar", "*.gz", "*.xz", "*.zip", "*.tar", "*.tgz", "*.bz2", "*.iso", "*.dmg")
# 7z工具路径（若已添加环境变量，直接填"7z"即可；否则填完整路径如"C:\Program Files\7-Zip\7z.exe"）
$7zPath = "7z"
# --------------- 配置结束 ---------------

# 显示帮助信息函数
function Show-Help {
    Write-Host "===== batch7z.ps1 批量压缩工具 使用帮助 =====" -ForegroundColor Cyan
    Write-Host "用途："
    Write-Host "  1. 批量压缩目标目录下的一级子目录为 .7z 包（采用 LZMA2 压缩算法）"
    Write-Host "  2. 打包当前目录下的非压缩包文件为 _files_ 日期格式的 .7z 包"
    Write-Host ""
    Write-Host "参数说明："
    Write-Host "  -TargetDir [目录路径] ：指定目标压缩目录（默认：当前工作目录）"
    Write-Host "  -Password [密码]       ：指定压缩包密码（默认：$DEFAULT_PASSWORD）"
    Write-Host "  -Force                 ：强制重新压缩（覆盖已存在的压缩包）"
    Write-Host "  -Help                  ：显示此帮助信息并退出"
    Write-Host ""
    Write-Host "配置说明："
    Write-Host "  1. 压缩格式：.7z（兼容 7-Zip、WinRAR 等常规压缩软件）"
    Write-Host "  2. 压缩算法：LZMA2（高压缩比，对应 -mx=9 最高压缩级别）"
    Write-Host "  3. 自动过滤：$($FILTER_FILES -join ' ')
    Write-Host "  4. 已压缩格式排除：$($CUR_PACKED_FORMATS -join ' ')
    Write-Host "  5. 文件名格式："
    Write-Host "     - 子目录：子目录名_YYYY-MM-DD_HH-mm.7z（使用目录最后修改时间）"
    Write-Host "     - 零散文件：当前目录名_files_YYYY-MM-DD_HH-mm.7z（使用目录最后修改时间）"
    Write-Host "  6. 系统要求：已安装 7-Zip 并将 7z 加入环境变量"
    Write-Host "==========================================" -ForegroundColor Cyan
}

# 前置校验：检查7z工具是否可用
function Test-7zAvailability {
    try {
        # 执行7z版本查询，隐藏输出（仅校验是否存在）
        & $7zPath --version 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) { # 7z --version 返回1为正常输出版本信息
            throw "7z命令执行失败"
        }
    }
    catch {
        Write-Host "❌ 错误：未找到7z工具，请先安装7-Zip并配置环境变量！" -ForegroundColor Red
        Write-Host "  下载地址：https://www.7-zip.org/" -ForegroundColor Gray
        Write-Host "  配置说明：将7-Zip安装目录下的7z.exe添加到系统PATH环境变量" -ForegroundColor Gray
        exit 1
    }
}

# --------------- 脚本入口 ---------------
# 解析命令行参数
param (
    [Parameter(Mandatory = $false)]
    [string]$TargetDir = $DEFAULT_DIR,

    [Parameter(Mandatory = $false)]
    [string]$Password = $DEFAULT_PASSWORD,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$Help
)

# 显示帮助信息并退出
if ($Help) {
    Show-Help
    exit 0
}

# 前置校验：检查7z是否安装
Test-7zAvailability

# 校验目标目录是否存在
if (-not (Test-Path -Path $TargetDir -PathType Container)) {
    Write-Host "❌ 错误：指定的目录 '$TargetDir' 不存在或无效！" -ForegroundColor Red
    exit 1
}

# 切换到目标目录
try {
    Set-Location -Path $TargetDir -ErrorAction Stop
} catch {
    Write-Host "❌ 错误：无法切换到目标目录 '$TargetDir'，请检查目录权限！" -ForegroundColor Red
    exit 1
}

# 构建7z过滤参数数组（递归排除指定文件/目录）
$xzFilterArgs = @()
foreach ($filter in $FILTER_FILES) {
    $xzFilterArgs += "-xr!$filter"
}

# 输出任务配置信息
Write-Host "===== 开始批量压缩子目录任务 =====" -ForegroundColor Cyan
Write-Host "目标工作目录：$(Get-Location).Path" -ForegroundColor Gray
if ([string]::IsNullOrEmpty($Password)) {
    Write-Host "压缩配置：每个子目录单独打包，无密码" -ForegroundColor Gray
} else {
    Write-Host "压缩配置：每个子目录单独打包，密码=已设置（隐藏显示）" -ForegroundColor Gray
}
if ($Force) {
    Write-Host "强制模式：已启用（覆盖已存在的压缩包）" -ForegroundColor Yellow
} else {
    Write-Host "强制模式：未启用（跳过已存在的压缩包）" -ForegroundColor Gray
}
Write-Host "压缩格式：.7z（采用 LZMA2 压缩算法，兼容常规压缩软件）" -ForegroundColor Gray
Write-Host "子目录过滤：$($FILTER_FILES -join ' ')
Write-Host "日期标识：使用各目录最后修改时间（格式：年-月-日_时-分钟）" -ForegroundColor Gray
Write-Host "进度显示：启用实时百分比进度，压缩过程中可查看详细状态" -ForegroundColor Gray
Write-Host "-----------------------------" -ForegroundColor Gray

# 批量压缩子目录（兼容特殊文件名，带进度显示）
$subDirs = Get-ChildItem -Path . -Directory -Depth 0 | Where-Object { $_.Name -ne "." }
foreach ($dir in $subDirs) {
    $dirName = $dir.Name
    
    # 获取目录的最后修改时间并格式化
    $dirModifyTime = $dir.LastWriteTime
    $formattedTime = $dirModifyTime.ToString("yyyy-MM-dd_HH-mm")
    
    $compressFile = "$dirName`_$formattedTime.7z"

    # 跳过已存在的同名压缩包（除非启用强制模式）
    if (Test-Path -Path $compressFile -PathType Leaf) {
        if ($Force) {
            Write-Host "🔄 强制模式：删除已存在的压缩包 $compressFile" -ForegroundColor Yellow
            Remove-Item -Path $compressFile -Force -ErrorAction SilentlyContinue
        } else {
            Write-Host "⚠️  已存在压缩包 $compressFile，跳过压缩" -ForegroundColor Yellow
            continue
        }
    }

    Write-Host "正在压缩：$dirName → $compressFile（过滤 $($FILTER_FILES -join ' ')
    Write-Host "-----------------------------" -ForegroundColor Gray

    # 构建7z核心参数
    $xzCoreArgs = @(
        "a",
        "-bsp1", # 启用百分比实时进度显示
        "-t7z",
        "-mx=9",
        "-m0=LZMA2",
        $xzFilterArgs,
        $compressFile,
        $dirName
    )

    # 添加密码参数（若不为空）
    if (-not [string]::IsNullOrEmpty($Password)) {
        $xzCoreArgs += "-p$Password"
    }

    # 执行7z压缩命令（保留原生输出，显示实时进度）
    & $7zPath $xzCoreArgs

    # 校验压缩结果并清理无效文件
    if ($LASTEXITCODE -eq 0) {
        # 二次校验：判断压缩包是否为空
        $isArchiveEmpty = $true
        try {
            # 查看压缩包内文件列表，简化输出
            $archiveList = & $7zPath "l" "-bb0" $compressFile $(if (-not [string]::IsNullOrEmpty($Password)) { "-p$Password" }) 2>&1
            $lastLine = $archiveList | Select-Object -Last 1
            if ($lastLine -match "\d+\s+\d+") {
                $isArchiveEmpty = $false
            }
        } catch {
            $isArchiveEmpty = $true
        }

        if ($isArchiveEmpty) {
            Write-Host "⚠️  $compressFile 压缩包为空，已删除" -ForegroundColor Yellow
            Remove-Item -Path $compressFile -Force -ErrorAction SilentlyContinue
            continue
        }

        Write-Host "✅ $compressFile 压缩成功（$(if ([string]::IsNullOrEmpty($Password)) { "无密码" } else { "密码：已设置，隐藏显示" })）" -ForegroundColor Green
    } else {
        Write-Host "❌ $compressFile 压缩失败，请检查目录权限或工具完整性" -ForegroundColor Red
        if (Test-Path -Path $compressFile -PathType Leaf) {
            Remove-Item -Path $compressFile -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "-----------------------------" -ForegroundColor Gray
}

# 压缩当前目录下非压缩包文件（带进度显示）
Write-Host "-----------------------------" -ForegroundColor Gray
Write-Host "开始检查并打包当前目录文件（排除已压缩格式）..." -ForegroundColor Blue

# 获取当前目录名（作为压缩包前缀）
$currentDirName = (Get-Location).Path.Split("\")[-1]

# 获取当前目录的最后修改时间
$currentDirInfo = Get-Item -Path "."
$currentDirModifyTime = $currentDirInfo.LastWriteTime
$currentDirFormattedTime = $currentDirModifyTime.ToString("yyyy-MM-dd_HH-mm")

$filesPackage = "$currentDirName`_files_$currentDirFormattedTime.7z"

# 跳过已存在的文件包（除非启用强制模式）
$skipFilesPackage = $false
if (Test-Path -Path $filesPackage -PathType Leaf) {
    if ($Force) {
        Write-Host "🔄 强制模式：删除已存在的文件包 $filesPackage" -ForegroundColor Yellow
        Remove-Item -Path $filesPackage -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "⚠️  已存在文件包 $filesPackage，跳过压缩" -ForegroundColor Yellow
        $skipFilesPackage = $true
    }
}

if (-not $skipFilesPackage) {
    # 查找目标文件（排除已压缩格式）
    $targetFiles = @()
    $allFiles = Get-ChildItem -Path . -File -Depth 0
    foreach ($file in $allFiles) {
        $isPackedFormat = $false
        foreach ($format in $CUR_PACKED_FORMATS) {
            if ($file.Name -like $format) {
                $isPackedFormat = $true
                break
            }
        }
        if (-not $isPackedFormat) {
            $targetFiles += $file.FullName
        }
    }

    $fileCount = $targetFiles.Count
    if ($fileCount -gt 0) {
        Write-Host "发现 $fileCount 个文件待打包（排除已压缩格式：$($CUR_PACKED_FORMATS -join ' ')
        Write-Host "正在打包文件：$filesPackage" -ForegroundColor Blue
        Write-Host "-----------------------------" -ForegroundColor Gray

        # 构建7z核心参数
        $xzCoreArgs = @(
            "a",
            "-bsp1", # 启用百分比实时进度显示
            "-t7z",
            "-mx=9",
            "-m0=LZMA2",
            $xzFilterArgs,
            $filesPackage
        )

        # 添加密码参数（若不为空）
        if (-not [string]::IsNullOrEmpty($Password)) {
            $xzCoreArgs += "-p$Password"
        }

        # 添加待打包文件列表
        $xzCoreArgs += $targetFiles

        # 执行7z压缩命令（保留原生输出，显示实时进度）
        & $7zPath $xzCoreArgs

        # 校验压缩结果并清理无效文件
        $isArchiveEmpty = $true
        $isCompressSuccess = $false
        if ($LASTEXITCODE -eq 0 -and (Test-Path -Path $filesPackage -PathType Leaf)) {
            try {
                $archiveList = & $7zPath "l" "-bb0" $filesPackage $(if (-not [string]::IsNullOrEmpty($Password)) { "-p$Password" }) 2>&1
                $lastLine = $archiveList | Select-Object -Last 1
                if ($lastLine -match "\d+\s+\d+") {
                    $isArchiveEmpty = $false
                    $isCompressSuccess = $true
                }
            } catch {
                $isArchiveEmpty = $true
            }
        }

        if ($isCompressSuccess -and -not $isArchiveEmpty) {
            $packageSize = (Get-Item -Path $filesPackage).Length
            $packageSizeHuman = switch ($packageSize) {
                { $_ -ge 1GB } { "{0:N2} GB" -f ($_ / 1GB); break }
                { $_ -ge 1MB } { "{0:N2} MB" -f ($_ / 1MB); break }
                { $_ -ge 1KB } { "{0:N2} KB" -f ($_ / 1KB); break }
                default { "$_ Bytes" }
            }
            Write-Host "✅ $filesPackage 压缩成功（$(if ([string]::IsNullOrEmpty($Password)) { "无密码" } else { "密码：已设置，隐藏显示" })，大小：$packageSizeHuman）" -ForegroundColor Green
        } else {
            Write-Host "❌ $filesPackage 压缩失败或生成空包，已清理无效文件" -ForegroundColor Red
            Remove-Item -Path $filesPackage -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "当前目录下没有需要打包的文件（已排除压缩格式：$($CUR_PACKED_FORMATS -join ' ')
    }
}

# 任务结束统计（统计本次生成的压缩包）
Write-Host "-----------------------------" -ForegroundColor Gray
Write-Host "📊 本次任务生成压缩包统计：" -ForegroundColor Cyan

# 统计所有7z文件（因为现在使用的是不同时间戳）
$totalArchives = Get-ChildItem -Path . -File -Filter "*.7z" -ErrorAction SilentlyContinue
$totalCount = $totalArchives.Count
$totalSize = ($totalArchives | Measure-Object -Property Length -Sum).Sum

# 转换总大小为人性化显示
$totalSizeHuman = switch ($totalSize) {
    { $_ -ge 1GB } { "{0:N2} GB" -f ($_ / 1GB); break }
    { $_ -ge 1MB } { "{0:N2} MB" -f ($_ / 1MB); break }
    { $_ -ge 1KB } { "{0:N2} KB" -f ($_ / 1KB); break }
    default { "$_ Bytes" }
}

Write-Host "  总数量：$totalCount 个" -ForegroundColor Gray
Write-Host "  总大小：$totalSizeHuman（人性化显示）" -ForegroundColor Gray
Write-Host "-----------------------------" -ForegroundColor Gray
Write-Host "===== 批量压缩子目录任务执行完毕 =====" -ForegroundColor Cyan