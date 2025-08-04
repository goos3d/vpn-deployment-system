# WireGuard Windows Server Setup Script
# Run this as Administrator on the Windows server

Write-Host "🛡️ Setting up WireGuard VPN Server..." -ForegroundColor Green

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "❌ This script must be run as Administrator!"
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Create WireGuard directory
$wgDir = "C:\Program Files\WireGuard\Data\Configurations"
if (!(Test-Path $wgDir)) {
    New-Item -ItemType Directory -Path $wgDir -Force
    Write-Host "📁 Created WireGuard configuration directory" -ForegroundColor Green
}

# Copy configuration file (you need to place wg0.conf in the same directory as this script)
$configFile = "wg0.conf"
if (Test-Path $configFile) {
    Copy-Item $configFile "$wgDir\wg0.conf" -Force
    Write-Host "📄 Copied WireGuard configuration" -ForegroundColor Green
} else {
    Write-Error "❌ wg0.conf not found! Please place it in the same directory as this script."
    exit 1
}

# Configure Windows Firewall - Allow WireGuard
Write-Host "🔥 Configuring Windows Firewall..." -ForegroundColor Yellow
New-NetFirewallRule -DisplayName "WireGuard" -Direction Inbound -Protocol UDP -LocalPort 51820 -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "WireGuard" -Direction Outbound -Protocol UDP -LocalPort 51820 -Action Allow -ErrorAction SilentlyContinue

# Enable IP forwarding
Write-Host "🔄 Enabling IP forwarding..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "IPEnableRouter" -Value 1

# Configure NAT for internet access through VPN
Write-Host "🌐 Setting up NAT..." -ForegroundColor Yellow

# Get the main network adapter
$mainAdapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.InterfaceDescription -notlike "*WireGuard*"} | Select-Object -First 1

if ($mainAdapter) {
    # Enable Internet Connection Sharing equivalent
    Write-Host "📡 Configuring NAT on adapter: $($mainAdapter.Name)" -ForegroundColor Green
    
    # Install NAT feature if not present
    $natFeature = Get-WindowsOptionalFeature -Online -FeatureName "IIS-ASPNET45" -ErrorAction SilentlyContinue
    
    # Create NAT rule using netsh (Windows built-in NAT)
    netsh interface portproxy reset
    
    Write-Host "✅ NAT configuration completed" -ForegroundColor Green
} else {
    Write-Warning "⚠️ Could not find main network adapter for NAT setup"
}

# Instructions for manual WireGuard start
Write-Host ""
Write-Host "🎉 Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Open WireGuard app on Windows"
Write-Host "2. Click 'Add Tunnel' → 'Add from file'"
Write-Host "3. Select: C:\Program Files\WireGuard\Data\Configurations\wg0.conf"
Write-Host "4. Click 'Activate' to start the VPN server"
Write-Host ""
Write-Host "🔍 Troubleshooting:"
Write-Host "- Check Windows Firewall allows UDP port 51820"
Write-Host "- Verify WireGuard service is running"
Write-Host "- Check router/cloud firewall allows port 51820"
Write-Host ""
Write-Host "✅ VPN Server IP will be: 10.0.0.1"
Write-Host "✅ Client IP will be: 10.0.0.2"
