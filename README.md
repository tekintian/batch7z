# 📦 Batch7z - Efficient Batch Compression/Extraction Tool

> One-click backup, effortless restoration! Batch7z is a command-line tool designed for developers, making batch compression and extraction simpler and more efficient than ever.

**[中文版 README](README_CN.md)**

**✨ Key Features:**
- 🚀 **Blazing Fast Compression**: Based on LZMA2 algorithm with up to 70% compression ratio, significantly saving storage space
- 📁 **Smart Packaging**: Automatically identifies subdirectories and files, intelligently excludes already-compressed formats and temporary files
- 🔒 **Flexible Encryption**: Supports no password or custom passwords to meet different security requirements
- 🌍 **Cross-Platform Support**: Provides both Bash and PowerShell versions, perfectly compatible with Windows/macOS/Linux
- 🎯 **Precise Control**: Supports directory level stripping (strip) and force overwrite, flexible for various scenarios

**💡 Use Cases:**
- Quick project backup and migration
- Batch packaging of server deployment packages
- Multi-version project archive management
- One-click backup and restore of development environments

## Features

- **batch7z**: Batch compress first-level subdirectories under the target directory into .7z archives
- **batchun7z**: Batch extract .7z format archives, supports directory level stripping (strip) and force overwrite
- High compression ratio (LZMA2 algorithm)
- Automatically filters unnecessary files (*.log, .DS_Store, node_modules, etc.)
- Supports optional password setting for compression/extraction

## 📋 System Requirements

### macOS/Linux (Bash Version)

**macOS:**
```bash
brew install p7zip
```

**Linux:**
```bash
# Debian/Ubuntu
sudo apt-get install p7zip-full

# Arch Linux
sudo pacman -S p7zip
```

### Windows/macOS/Linux (PowerShell Version)

**Windows:**
- Download and install 7-Zip: https://www.7-zip.org/

**macOS:**
```bash
brew install p7zip
pwsh  # Install PowerShell
```

**Linux:**
```bash
# Install p7zip
sudo apt-get install p7zip-full  # Debian/Ubuntu
sudo pacman -S p7zip            # Arch Linux

# Install PowerShell
# Refer to official documentation: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell
```

📖 **Detailed Guide**: See [PowerShell Version Usage Guide](POWERSELL_USAGE.md)

## ⚡ Quick Start

### Bash Version (macOS/Linux)

```bash
# Clone or download scripts
git clone <repository-url>
cd batch7z

# Install dependencies
brew install p7zip  # macOS
# or
sudo apt-get install p7zip-full  # Linux

# Add execute permissions
chmod +x batch7z batchun7z

# Start using
./batch7z -d /path/to/project
./batchun7z -d /path/to/restore
```

### PowerShell Version (Windows/macOS/Linux)

```powershell
# Windows
# Download and install 7-Zip: https://www.7-zip.org/
.\batch7z.ps1 -d "C:\path\to\project"
.\batchun7z.ps1 -d "C:\path\to\restore"

# macOS/Linux
# Install p7zip and PowerShell
brew install p7zip pwsh

# Run scripts
pwsh -File ./batch7z.ps1 -d "/path/to/project"
pwsh -File ./batchun7z.ps1 -d "/path/to/restore"
```

---

## 📖 Usage

### batch7z - Batch Compression

Batch compress first-level subdirectories under the target directory into .7z archives.

**Basic Usage:**
```bash
batch7z                          # Compress all subdirectories in current directory
batch7z -d /path/to/dir          # Compress specified directory
batch7z -p 123456                # Use custom password
batch7z -h                       # Show help information
```

**Usage Examples:**

1. Backup all subdirectories of current project:
```bash
cd /Volumes/work/wwwroot
batch7z
```

2. Compress specified directory and set password:
```bash
batch7z -d ~/Desktop/projects -p mypassword
```

3. Compress multiple deployment packages for easy transfer:
```bash
cd /var/www/vhosts
batch7z -p deploy2026
```

**Configuration Notes:**
- Compression format: .7z (compatible with WinRAR, BetterZip, 7-Zip, etc.)
- Compression algorithm: LZMA2 (xz)
- Auto-filter: `*.log`, `*.tmp`, `.DS_Store`, `node_modules/`, `.next/`
- Already compressed formats (not packaged): .7z, .rar, .gz, .zip, .tar, .iso, .dmg, etc.
- File naming:
  - Subdirectories: `subdirectory_name_YYYY-MM-DD_HH-MM.7z`
  - Files: `current_directory_name_files_YYYY-MM-DD_HH-MM.7z`
- Default password: No password (optional to set)

---

### batchun7z - Batch Extraction

Batch extract all .7z format archives in current directory, supports directory stripping and force overwrite.

**Basic Usage:**
```bash
batchun7z                        # Extract all archives in current directory
batchun7z -d /path/to/dir        # Extract to specified directory
batchun7z -p 123456              # Use custom password
batchun7z -s 2                   # Strip first 2 directory levels
batchun7z -f                     # Force overwrite existing files
batchun7z -h                     # Show help information
```

**Usage Examples:**

1. Restore all backup packages in current directory:
```bash
cd /Volumes/work/wwwroot
batchun7z
```

2. Extract to specified directory and set password:
```bash
batchun7z -d ~/Desktop/restore -p mypassword
```

3. Strip nested directory structure:
```bash
# Archive contents: a/b/c/app/index.js
# After using -s 2: app/index.js
batchun7z -s 2
```

4. Force overwrite updates (skip existing files):
```bash
batchun7z -f
```

**Configuration Notes:**
- Supported formats: .7z (only archives generated by batch7z)
- Strip feature: Strip first N directory levels of files in the archive
- Default behavior: Skip existing files, no directory stripping
- Default password: No password (optional to set)

---

## 🔄 Workflow

### Compression Process (batch7z)
1. Scan first-level subdirectories under target directory
2. Create independent .7z archive for each subdirectory
3. Apply file filtering rules (exclude logs, temporary files, etc.)
4. Use LZMA2 algorithm for high-ratio compression
5. Optionally set password protection for archives
6. Generate filenames with timestamps
7. Package non-compressed files in current directory (exclude already compressed formats)

### Extraction Process (batchun7z)
1. Scan all .7z files in current directory
2. Verify password and extract to temporary directory
3. Strip specified directory levels based on strip setting
4. Handle existing files based on overwrite setting
5. Clean up temporary directory, complete extraction

## ⚠️ Important Notes

- Ensure 7z command is properly installed and added to PATH
- Recommend testing with small batch of data before large-scale operations
- Use quotes when password contains special characters
- Strip feature modifies directory structure, use with caution
- Default no password, use -p parameter if encryption is needed
- Current directory file packaging automatically excludes already compressed formats

## 📁 File List

| File | Platform | Description |
|------|----------|-------------|
| `batch7z` | macOS/Linux | Bash version batch compression tool |
| `batchun7z` | macOS/Linux | Bash version batch extraction tool |
| `batch7z.ps1` | Windows/macOS/Linux | PowerShell version batch compression tool |
| `batchun7z.ps1` | Windows/macOS/Linux | PowerShell version batch extraction tool |
| `README.md` | - | Project documentation |
| `README_CN.md` | - | Chinese version project documentation |
| `POWERSELL_USAGE.md` | - | PowerShell version detailed usage guide |

## 🆚 Version Comparison

| Feature | Bash Version | PowerShell Version |
|---------|--------------|---------------------|
| Runtime Environment | macOS/Linux | Windows / macOS / Linux |
| Command Format | `./batch7z` | `.\batch7z.ps1` or `pwsh -File ./batch7z.ps1` |
| Feature Set | Identical | Identical |
| Configuration Parameters | Identical | Identical |
| Cross-Platform | Unix systems only | All platforms |
| Recommended Use Cases | macOS/Linux development environments | Windows development environments or cross-platform needs |

## 📊 Typical Use Cases

### Scenario 1: Quick Project Backup
```bash
# Backup entire project directory (including all subdirectories and files)
cd ~/projects/myproject
./batch7z -p "backup2026"

# Generates:
# - app_2026-01-16_14-30.7z
# - lib_2026-01-16_14-30.7z
# - myproject_files_2026-01-16_14-30.7z (contains README.md, package.json, etc.)
```

### Scenario 2: Batch Packaging for Server Deployment
```bash
cd /var/www/vhosts
./batch7z -p "deploy2026"

# Each site is independently packaged for easy distribution to different servers
```

### Scenario 3: Cross-Platform Data Migration
```bash
# Package on macOS
./batch7z -d ~/Documents/projects -p "migrate"

# Extract on Windows
.\batchun7z.ps1 -d "C:\Projects\Restore" -p "migrate"
```

### Scenario 4: Strip Nested Directory Structure
```bash
# Archive contents: project/src/2025/backup/app/index.js
# After using -s 3: app/index.js
./batchun7z -s 3
```

## 🤝 Contributing

Issues and improvement suggestions are welcome!

## 📄 License

This project's tools are for personal use only.

---

**[中文版 README](README_CN.md)**
