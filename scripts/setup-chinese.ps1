# n8n 中文界面一键配置脚本 (PowerShell 版本)
# 作者: n8n Docker 部署项目
# 用途: 自动下载并配置 n8n 中文界面
#
# 使用方法:
#   1. 自动检测版本: .\scripts\setup-chinese.ps1
#   2. 指定版本: $env:N8N_VERSION="1.122.5"; .\scripts\setup-chinese.ps1
#   3. 使用最新版本: $env:N8N_VERSION="latest"; .\scripts\setup-chinese.ps1

# 设置错误时停止
$ErrorActionPreference = "Stop"

# 颜色函数
function Write-Info {
    param([string]$Message)
    Write-Host "ℹ " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Write-Header {
    Write-Host ""
    Write-Host "================================" -ForegroundColor Green
    Write-Host "  n8n 中文界面配置工具" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host ""
}

# 检查依赖
function Test-Dependencies {
    Write-Info "检查依赖..."
    
    $missingDeps = @()
    
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        $missingDeps += "Docker"
    }
    
    if ($missingDeps.Count -gt 0) {
        Write-Error "缺少以下依赖: $($missingDeps -join ', ')"
        Write-Host ""
        Write-Host "请先安装 Docker Desktop for Windows:"
        Write-Host "https://www.docker.com/products/docker-desktop"
        exit 1
    }
    
    Write-Success "依赖检查通过"
}

# 获取 n8n 版本
function Get-N8nVersion {
    # 如果环境变量已设置,直接使用
    if ($env:N8N_VERSION) {
        Write-Success "使用环境变量指定的版本: $env:N8N_VERSION"
        return $env:N8N_VERSION
    }

    Write-Info "检测 n8n 版本..."

    # 尝试从运行中的容器获取版本
    $containers = docker ps --format "{{.Names}}" | Select-String "n8n"
    if ($containers) {
        $containerName = $containers[0]
        $version = docker exec $containerName n8n --version 2>$null | Select-String -Pattern '\d+\.\d+\.\d+' | ForEach-Object { $_.Matches.Value }
        
        if ($version) {
            Write-Success "检测到 n8n 版本: $version"
            return $version
        }
    }
    
    # 使用默认版本
    Write-Warning "无法自动检测 n8n 版本，使用默认版本: latest"
    return "latest"
}

# 下载中文 UI
function Get-ChineseUI {
    param([string]$Version)
    
    Write-Info "下载中文 UI (版本: $Version)..."
    
    $downloadUrl = "https://github.com/other-blowsnow/n8n-i18n-chinese/releases/download/n8n%40$Version/editor-ui.tar.gz"
    $tempDir = "n8n-chinese-temp"
    $targetDir = "n8n-chinese-ui"
    
    # 创建临时目录
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    try {
        # 下载文件
        Write-Info "正在下载..."
        $tarFile = Join-Path $tempDir "editor-ui.tar.gz"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tarFile -UseBasicParsing
        
        # 解压文件
        Write-Info "正在解压..."
        tar -xzf $tarFile -C $tempDir
        
        # 移动到目标目录
        if (Test-Path $targetDir) {
            Remove-Item -Path $targetDir -Recurse -Force
        }
        Move-Item -Path (Join-Path $tempDir "dist") -Destination $targetDir
        
        # 保存版本信息
        $Version | Out-File -FilePath (Join-Path $targetDir ".version") -Encoding utf8
        
        Write-Success "中文 UI 下载完成"
    }
    catch {
        Write-Error "下载失败: $_"
        Write-Warning "请检查网络连接或手动下载"
        exit 1
    }
    finally {
        # 清理临时文件
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force
        }
    }
}

# 主函数
function Main {
    Write-Header
    
    # 检查依赖
    Test-Dependencies
    
    # 获取版本
    $version = Get-N8nVersion
    
    # 下载中文 UI
    Get-ChineseUI -Version $version
    
    Write-Host ""
    Write-Success "配置完成！"
    Write-Host ""
    Write-Info "下一步操作:"
    Write-Host "  1. 复制配置文件: copy .env.example .env"
    Write-Host "  2. 编辑配置文件: notepad .env"
    Write-Host "  3. 启动服务: docker compose up -d"
    Write-Host "  4. 访问 n8n: http://localhost:5678"
    Write-Host ""
}

# 运行主函数
Main

