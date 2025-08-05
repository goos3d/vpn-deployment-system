# Dr. Kover VPN - Local Installation Script (PowerShell)
# Run this to install the complete VPN management system on the VM

Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              Dr. Kover VPN - Complete Local Installation                    ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "🎯 Installing complete VPN management system locally on VM..." -ForegroundColor Yellow
Write-Host ""

# Check if we have the VM deployment files
if (!(Test-Path "vm-deployment")) {
    Write-Host "❌ vm-deployment folder not found!" -ForegroundColor Red
    exit 1
}

# Upload all scripts to the VM using scp (assuming OpenSSH is available)
Write-Host "📤 Uploading management scripts to VM..." -ForegroundColor Cyan

try {
    scp vm-deployment/add-peer.sh root@184.105.7.112:/etc/wireguard/
    scp vm-deployment/vpn-manager.sh root@184.105.7.112:/etc/wireguard/
    scp vm-deployment/vpn-status.sh root@184.105.7.112:/etc/wireguard/
    scp vm-deployment/dr-kover-final-setup.sh root@184.105.7.112:/etc/wireguard/
    
    Write-Host "✅ Scripts uploaded" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to upload scripts. Make sure SSH/SCP is available." -ForegroundColor Red
    Write-Host "You may need to manually copy the files from vm-deployment/ folder" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Execute the final setup on the VM
Write-Host "🔧 Running final setup on VM..." -ForegroundColor Cyan
try {
    ssh root@184.105.7.112 "cd /etc/wireguard && chmod +x dr-kover-final-setup.sh && ./dr-kover-final-setup.sh"
    
    Write-Host ""
    Write-Host "🧪 Testing the system..." -ForegroundColor Cyan
    ssh root@184.105.7.112 "cd /etc/wireguard && ./vpn-status.sh"
} catch {
    Write-Host "❌ Failed to execute setup on VM. You may need to run the setup manually." -ForegroundColor Red
    Write-Host "Manual steps:" -ForegroundColor Yellow
    Write-Host "1. SSH to root@184.105.7.112" -ForegroundColor Yellow
    Write-Host "2. cd /etc/wireguard" -ForegroundColor Yellow
    Write-Host "3. chmod +x *.sh" -ForegroundColor Yellow
    Write-Host "4. ./dr-kover-final-setup.sh" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host ""
Write-Host "Dr. Kover's VPN system is now installed locally and ready to run independently:" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Add devices: ssh root@184.105.7.112 'cd /etc/wireguard && ./add-peer.sh [DeviceName]'" -ForegroundColor White
Write-Host "✅ Management menu: ssh root@184.105.7.112 'cd /etc/wireguard && ./vpn-manager.sh'" -ForegroundColor White
Write-Host "✅ Check status: ssh root@184.105.7.112 'cd /etc/wireguard && ./vpn-status.sh'" -ForegroundColor White
Write-Host ""
Write-Host "🏆 The VPN system will continue running after we're gone!" -ForegroundColor Green
Write-Host "Dr. Kover can manage all devices independently using these tools." -ForegroundColor Green
