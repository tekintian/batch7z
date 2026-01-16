# BatchUn7z 批量解压工具（PowerShell 版本）
# ===================== 使用说明 =====================
# 用途：批量解压当前目录下所有支持的压缩包
#
# 基本用法：
#   .\batchun7z.ps1                          # 解压当前目录所有压缩包（默认格式：.7z .zip .xz .tgz .gz）
#   .\batchun7z.ps1 -d "C:\path\to\dir"     # 解压到指定目录
#   .\batchun7z.ps1 -p "123456"             # 使用自定义密码
#   .\batchun7z.ps1 -s 2                    # 剥解前 2 层目录
#   .\batchun7z.ps1 -f                      # 强制覆盖已存在文件
#   .\batchun7z.ps1 -e "*.7z *.rar"        # 自定义解压格式
#   .\batchun7z.ps1 -h                      # 显示帮助信息
#
# 使用实例：
#   # 场景1：还原当前目录的所有备份包
#   cd C:\wwwroot
#   .\batchun7z.ps1
#
#   # 场景2：解压到指定目录并设置密码
#   .\batchun7z.ps1 -d "C:\Users\Username\Desktop\restore" -p "mypassword"
#
#   # 场景3：剥离嵌套目录结构
#   # 压缩包内：a/b/c/app/index.js
#   # 使用 -s 2 后：app/index.js
#   .\batchun7z.ps1 -s 2
#
#   # 场景4：强制覆盖更新（跳过已存在文件）
#   .\batchun7z.ps1 -f
#
#   # 场景5：自定义解压格式（仅解压 .7z 和 .rar）
#   .\batchun7z.ps1 -e "*.7z *.rar" -d "C:\path\to\dir"
#
# ===================== 配置说明 =====================
# - 默认格式：.7z .zip .xz .tgz .gz（可通过 -e 参数自定义）
# - strip 功能：剥离压缩包内文件的前 N 层目录
# - 默认行为：跳过已存在文件，不剥离目录
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
    [string]$d = "",           # 解压目录
    [string]$p = "",           # 密码
    [int]$s = 0,               # strip 层级
    [string]$e = "",           # 解压格式
    [switch]$f,                # 强制覆盖
    [switch]$h                 # 显示帮助
)

# ===================== 配置变量 =====================
# 7z.exe 的路径（如果已添加到 PATH，可以直接使用 "7z"）
$7zPath = "7z"

# 默认配置
$DEFAULT_PASSWORD = ""
$DEFAULT_EXTRACT_DIR = Get-Location
$DEFAULT_STRIP_LEVEL = 0
$DEFAULT_FORCE = $false
$DEFAULT_FORMATS = @("*.7z", "*.zip", "*.xz", "*.tgz", "*.gz")

# ===================== 帮助函数 =====================
function Show-Help {
    Write-Host "===== batchun7z 批量解压工具 使用帮助 =====" -ForegroundColor Cyan
    Write-Host "用途：批量解压压缩包（支持 strip 目录剥离，可自定义格式）"
    Write-Host "格式：.\batchun7z.ps1 [选项]..."
    Write-Host ""
    Write-Host "可选参数："
    Write-Host "  -d [目录路径]   指定目标解压目录（默认：当前工作目录）"
    Write-Host "  -p [密码]       指定解压包密码（默认：不设置密码）"
    Write-Host "  -s [数字]       指定目录剥离层级 strip（默认：0，非负整数）"
    Write-Host "  -e [格式列表]   指定解压格式，空格分隔（默认：*.7z *.zip *.xz *.tgz *.gz）"
    Write-Host "  -f              强制覆盖已存在的文件（默认：跳过已存在）"
    Write-Host "  -h              显示此帮助信息并退出"
    Write-Host ""
    Write-Host "配置说明："
    Write-Host "  1. 支持格式：$($SUPPORTED_FORMATS -join ' ')"
    Write-Host "     自定义格式：使用 -e 参数，如 -e '*.7z *.zip *.rar'"
    Write-Host "  2. strip 功能：剥离压缩包内文件的前 N 层目录（N 为 -s 指定的数字）"
    Write-Host "     示例：strip 3 → 压缩包内 a/b/c/d/file.txt → 解压后 d/file.txt"
    Write-Host "  3. 默认行为：解压当前目录下所有支持的压缩包，不剥离目录，无密码"
    Write-Host "  4. 系统要求："
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

# 设置解压目录
$EXTRACT_DIR = if ($d) { $d } else { $DEFAULT_EXTRACT_DIR.Path }

# 检查目录是否存在，不存在则创建
if (-not (Test-Path -Path $EXTRACT_DIR -PathType Container)) {
    Write-Host "⚠️  提示：-d 选项指定的目录 '$EXTRACT_DIR' 不存在，将自动创建" -ForegroundColor Yellow
    try {
        New-Item -ItemType Directory -Path $EXTRACT_DIR -Force | Out-Null
    } catch {
        Write-Host "❌ 错误：无法创建解压目录 '$EXTRACT_DIR'，请检查权限！" -ForegroundColor Red
        exit 1
    }
}

# 设置解压密码
$EXTRACT_PASSWORD = if ($p) { $p } else { $DEFAULT_PASSWORD }

# 设置 strip 层级
$STRIP_LEVEL = if ($s -gt 0) { $s } else { $DEFAULT_STRIP_LEVEL }

# 校验 strip 层级是否为非负整数
if ($STRIP_LEVEL -lt 0) {
    Write-Host "❌ 错误：-s 选项指定的 strip 层级 '$STRIP_LEVEL' 无效，必须为非负整数！" -ForegroundColor Red
    exit 1
}

# 设置解压格式
$SUPPORTED_FORMATS = if ($e) { $e -split ' ' } else { $DEFAULT_FORMATS }

# 设置强制覆盖模式
$FORCE_OVERWRITE = $f

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
# 切换到解压目录
Set-Location -Path $EXTRACT_DIR

# 检查是否有支持的压缩包
$archiveFiles = @()
foreach ($format in $SUPPORTED_FORMATS) {
    $files = Get-ChildItem -Filter $format -File
    if ($files) {
        $archiveFiles += $files
    }
}

if ($archiveFiles.Count -eq 0) {
    Write-Host "❌ 错误：在解压目录 '$EXTRACT_DIR' 中未找到任何支持的压缩包！" -ForegroundColor Red
    Write-Host "支持的格式：$($SUPPORTED_FORMATS -join ' ')" -ForegroundColor Yellow
    exit 1
}

$totalFiles = $archiveFiles.Count

# 输出解压任务配置信息
Write-Host "===== 开始批量解压压缩包任务 =====" -ForegroundColor Cyan
Write-Host "目标解压目录：$((Get-Location).Path)"
if ([string]::IsNullOrEmpty($EXTRACT_PASSWORD)) {
    Write-Host "解压配置：无密码，strip 层级=$STRIP_LEVEL，强制覆盖=$FORCE_OVERWRITE"
} else {
    Write-Host "解压配置：密码=已设置（隐藏显示），strip 层级=$STRIP_LEVEL，强制覆盖=$FORCE_OVERWRITE"
}
Write-Host "支持格式：$($SUPPORTED_FORMATS -join ' ')"
Write-Host "待解压文件：$totalFiles 个压缩包"
Write-Host "-----------------------------" -ForegroundColor Gray

# ===================== 批量解压压缩包 =====================
foreach ($xzFile in $archiveFiles) {
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($xzFile.Name)
    Write-Host "正在解压：$($xzFile.Name)"

    # 创建临时目录
    $tempDir = ".\.temp_extract_${fileName}"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    # 步骤1：7z 解压到临时目录
    # 对于 .tar.gz 等复合格式，需要特殊处理
    $archiveName = $xzFile.Name

    # 构建 7z 基础参数（包含密码）
    $tarArgs = @("x", "-si", "-ttar", "-o${tempDir}", "-y")
    if (-not [string]::IsNullOrEmpty($EXTRACT_PASSWORD)) {
        $tarArgs += "-p${EXTRACT_PASSWORD}"
    }

    if ($archiveName -match '\.tar\.gz$|\.tgz$') {
        # .tar.gz / .tgz：使用 gzip 解压外层，再用 7z 解压 tar
        $gzipOutput = gzip -d -c $xzFile.FullName 2>&1
        $gzipOutput | & $7zPath @tarArgs 2>&1 | Out-Null
    } elseif ($archiveName -match '\.tar\.bz2$|\.tbz2$') {
        # .tar.bz2 / .tbz2：使用 bzip2 解压外层，再用 7z 解压 tar
        $bzip2Output = bunzip2 -c $xzFile.FullName 2>&1
        $bzip2Output | & $7zPath @tarArgs 2>&1 | Out-Null
    } elseif ($archiveName -match '\.tar\.xz$|\.txz$') {
        # .tar.xz / .txz：使用 xz 解压外层，再用 7z 解压 tar
        $xzOutput = xz -d -c $xzFile.FullName 2>&1
        $xzOutput | & $7zPath @tarArgs 2>&1 | Out-Null
    } else {
        # 其他格式：直接使用 7z 解压
        $7zArgs = @("x", $xzFile.FullName, "-o${tempDir}", "-y")

        # 如果设置了密码，添加密码参数
        if (-not [string]::IsNullOrEmpty($EXTRACT_PASSWORD)) {
            $7zArgs += "-p${EXTRACT_PASSWORD}"
        }

        # 执行解压命令（静默模式）
        $process = Start-Process -FilePath $7zPath -ArgumentList $7zArgs -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$null" -RedirectStandardError "$null"
        $exitCode = $process.ExitCode
    }

    # 对于复合格式，检查解压结果
    if ($archiveName -match '\.tar\.gz$|\.tgz$|\.tar\.bz2$|\.tbz2$|\.tar\.xz$|\.txz$') {
        # 检查临时目录是否有内容
        $extractedItems = Get-ChildItem -Path $tempDir -Recurse
        $exitCode = if ($extractedItems.Count -eq 0) { 1 } else { 0 }
    }

    # 校验解压结果
    if ($process.ExitCode -ne 0) {
        Write-Host "❌ $($xzFile.Name) 解压失败（可能是密码错误、压缩包损坏或权限不足）" -ForegroundColor Red
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        continue
    }

    # 步骤2：实现 strip 目录剥离
    if ($STRIP_LEVEL -eq 0) {
        # strip 0：直接将临时目录内的内容移动到目标目录
        $tempItems = Get-ChildItem -Path $tempDir -Recurse
        foreach ($item in $tempItems) {
            $itemPath = $item.FullName
            # 计算相对路径
            $relativePath = $itemPath.Substring($tempDir.Length + 1)

            # 目标路径
            $targetPath = Join-Path -Path $EXTRACT_DIR -ChildPath $relativePath

            # 确保目标目录存在
            $targetDir = Split-Path -Parent $targetPath
            if (-not (Test-Path -Path $targetDir -PathType Container)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }

            # 检查文件是否已存在
            if (Test-Path -Path $targetPath -PathType Leaf) {
                if ($FORCE_OVERWRITE) {
                    Copy-Item -Path $itemPath -Destination $targetPath -Force
                } else {
                    Write-Host "⚠️  跳过已存在：$($item.Name)" -ForegroundColor Yellow
                }
            } else {
                Copy-Item -Path $itemPath -Destination $targetPath
            }
        }
    } else {
        # strip >0：剥离前 N 层目录
        $tempItems = Get-ChildItem -Path $tempDir -Recurse

        foreach ($item in $tempItems) {
            $itemPath = $item.FullName
            # 计算相对路径
            $relativePath = $itemPath.Substring($tempDir.Length + 1)

            # 分割路径
            $pathParts = $relativePath -split [regex]::Escape([System.IO.Path]::DirectorySeparatorChar)

            # 如果路径层级大于 strip 层级
            if ($pathParts.Count -gt $STRIP_LEVEL) {
                # 剥离前 N 层
                $newRelativePath = $pathParts[$STRIP_LEVEL..($pathParts.Count - 1)] -join [System.IO.Path]::DirectorySeparatorChar
                $targetPath = Join-Path -Path $EXTRACT_DIR -ChildPath $newRelativePath

                # 确保目标目录存在
                $targetDir = Split-Path -Parent $targetPath
                if (-not (Test-Path -Path $targetDir -PathType Container)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }

                # 检查文件是否已存在
                if (Test-Path -Path $targetPath -PathType Leaf) {
                    if ($FORCE_OVERWRITE) {
                        Copy-Item -Path $itemPath -Destination $targetPath -Force
                    } else {
                        Write-Host "⚠️  跳过已存在：$($item.Name)" -ForegroundColor Yellow
                    }
                } else {
                    Copy-Item -Path $itemPath -Destination $targetPath
                }
            }
        }
    }

    # 步骤3：清理临时目录
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "✅ $($xzFile.Name) 解压成功（strip 层级：$STRIP_LEVEL）" -ForegroundColor Green
}

Write-Host "-----------------------------" -ForegroundColor Gray
Write-Host "===== 批量解压压缩包任务执行完毕 =====" -ForegroundColor Cyan
Write-Host "提示：解压结果已保存到 '$EXTRACT_DIR'，请查看验证" -ForegroundColor Gray
