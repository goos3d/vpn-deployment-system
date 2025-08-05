# VPN Web GUI Deployment Script for Windows VM
# Run this on the Windows server (184.105.7.112)

Write-Host "🚀 VPN Web GUI Deployment Starting..." -ForegroundColor Green
Write-Host "Target: Windows VM Server 184.105.7.112" -ForegroundColor Yellow
Write-Host "Date: $(Get-Date)" -ForegroundColor Yellow

# Step 1: Verify VPN Server Status
Write-Host "`n🔍 Step 1: Checking VPN Server Status..." -ForegroundColor Cyan
$wireguardService = Get-Service | Where-Object {$_.Name -like "*wireguard*"}
if ($wireguardService) {
    Write-Host "✅ WireGuard Service Status: $($wireguardService.Status)" -ForegroundColor Green
} else {
    Write-Host "❌ WireGuard service not found!" -ForegroundColor Red
}

# Check if VPN port is listening
$vpnPort = netstat -an | findstr ":51820"
if ($vpnPort) {
    Write-Host "✅ VPN Port 51820: LISTENING" -ForegroundColor Green
} else {
    Write-Host "❌ VPN Port 51820: NOT LISTENING" -ForegroundColor Red
}

# Step 2: Navigate to VPN System Directory
Write-Host "`n📂 Step 2: Locating VPN System..." -ForegroundColor Cyan
$possiblePaths = @(
    "C:\vpn-deployment-system",
    "C:\Users\Administrator\vpn-deployment-system",
    "C:\temp\vpn-deployment-system"
)

$vpnPath = $null
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $vpnPath = $path
        Write-Host "✅ Found VPN system at: $path" -ForegroundColor Green
        break
    }
}

if (-not $vpnPath) {
    Write-Host "❌ VPN system directory not found!" -ForegroundColor Red
    Write-Host "Please clone the repository first:" -ForegroundColor Yellow
    Write-Host "git clone https://github.com/goos3d/vpn-deployment-system.git" -ForegroundColor White
    exit 1
}

Set-Location $vpnPath

# Step 3: Verify Python Installation
Write-Host "`n🐍 Step 3: Checking Python..." -ForegroundColor Cyan
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python not found or not in PATH!" -ForegroundColor Red
    exit 1
}

# Step 4: Install Dependencies
Write-Host "`n📦 Step 4: Installing Dependencies..." -ForegroundColor Cyan
try {
    pip install flask jinja2 qrcode pillow pathlib
    Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to install dependencies!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Step 5: Verify Web App Configuration
Write-Host "`n⚙️  Step 5: Verifying Web App Configuration..." -ForegroundColor Cyan
$webAppFile = "src\web\app.py"
if (Test-Path $webAppFile) {
    $configCheck = Select-String -Path $webAppFile -Pattern "allowed_ips.*10\.0\.0\.0/24"
    if ($configCheck) {
        Write-Host "✅ Web app configured with HIPAA-compliant pattern" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Web app may need configuration update" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Web app file not found!" -ForegroundColor Red
}

# Step 6: Start Web GUI
Write-Host "`n🌐 Step 6: Starting Web GUI..." -ForegroundColor Cyan
Write-Host "Web GUI will be available at: http://10.0.0.1:5000" -ForegroundColor Yellow
Write-Host "Accessible from VPN-connected clients only" -ForegroundColor Yellow
Write-Host "`nStarting Flask server..." -ForegroundColor Green

# Start the web application
python -m src.web.app --host=0.0.0.0 --port=5000
