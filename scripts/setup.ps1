# n8n Docker 一键安装脚本 (PowerShell 版本)
# 作者: n8n Docker 部署项目
# 用途: 快速部署 n8n (英文版)

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
    Write-Host "  n8n Docker 快速部署" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host ""
}

# 检查依赖
function Test-Dependencies {
    Write-Info "检查依赖..."
    
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "未找到 Docker"
        Write-Host ""
        Write-Host "请先安装 Docker Desktop for Windows:"
        Write-Host "https://www.docker.com/products/docker-desktop"
        exit 1
    }
    
    # 检查 Docker 是否运行
    try {
        docker ps | Out-Null
        Write-Success "Docker 运行正常"
    }
    catch {
        Write-Error "Docker 未运行，请启动 Docker Desktop"
        exit 1
    }
}

# 配置环境变量
function Set-Environment {
    Write-Info "配置环境变量..."
    
    if (Test-Path ".env") {
        Write-Warning "检测到已存在的 .env 文件"
        $response = Read-Host "是否覆盖? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            Write-Info "使用现有配置"
            return
        }
    }
    
    # 复制示例配置
    Copy-Item ".env.example" ".env"
    
    # 生成加密密钥
    $encryptionKey = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
    
    # 获取用户输入
    Write-Host ""
    $username = Read-Host "设置管理员用户名 [admin]"
    if ([string]::IsNullOrWhiteSpace($username)) {
        $username = "admin"
    }
    
    $password = Read-Host "设置管理员密码" -AsSecureString
    $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    )
    
    if ([string]::IsNullOrWhiteSpace($passwordPlain)) {
        $passwordPlain = "changeme123"
        Write-Warning "使用默认密码: changeme123"
    }
    
    # 更新 .env 文件
    $content = Get-Content ".env"
    $content = $content -replace "N8N_BASIC_AUTH_USER=.*", "N8N_BASIC_AUTH_USER=$username"
    $content = $content -replace "N8N_BASIC_AUTH_PASSWORD=.*", "N8N_BASIC_AUTH_PASSWORD=$passwordPlain"
    $content = $content -replace "N8N_ENCRYPTION_KEY=.*", "N8N_ENCRYPTION_KEY=$encryptionKey"
    $content | Set-Content ".env"
    
    Write-Success "环境变量配置完成"
}

# 启动服务
function Start-Services {
    Write-Info "启动 n8n 服务..."
    
    try {
        docker compose up -d
        Write-Success "服务启动成功"
    }
    catch {
        Write-Error "服务启动失败: $_"
        exit 1
    }
}

# 等待服务就绪
function Wait-ForService {
    Write-Info "等待服务启动..."
    
    $maxAttempts = 30
    $attempt = 0
    
    while ($attempt -lt $maxAttempts) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:5678" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Success "服务已就绪"
                return $true
            }
        }
        catch {
            # 继续等待
        }
        
        $attempt++
        Start-Sleep -Seconds 2
        Write-Host "." -NoNewline
    }
    
    Write-Host ""
    Write-Warning "服务启动超时，请手动检查"
    return $false
}

# 主函数
function Main {
    Write-Header
    
    # 检查依赖
    Test-Dependencies
    
    # 配置环境
    Set-Environment
    
    # 启动服务
    Start-Services
    
    # 等待服务就绪
    Wait-ForService
    
    Write-Host ""
    Write-Success "n8n 部署完成！"
    Write-Host ""
    Write-Info "访问地址: http://localhost:5678"
    Write-Info "首次访问需要创建管理员账户"
    Write-Host ""
    Write-Info "常用命令:"
    Write-Host "  查看日志: docker compose logs -f n8n"
    Write-Host "  停止服务: docker compose down"
    Write-Host "  重启服务: docker compose restart"
    Write-Host ""
}

# 运行主函数
Main

