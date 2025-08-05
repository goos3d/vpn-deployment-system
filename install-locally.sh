#!/bin/bash

# Dr. Kover VPN - Local Installation Script
# Run this to install the complete VPN management system on the VM

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║              Dr. Kover VPN - Complete Local Installation                    ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

echo "🎯 Installing complete VPN management system locally on VM..."
echo ""

# Upload all scripts to the VM
echo "📤 Uploading management scripts to VM..."

scp vm-deployment/add-peer.sh root@184.105.7.112:/etc/wireguard/
scp vm-deployment/vpn-manager.sh root@184.105.7.112:/etc/wireguard/
scp vm-deployment/vpn-status.sh root@184.105.7.112:/etc/wireguard/
scp vm-deployment/dr-kover-final-setup.sh root@184.105.7.112:/etc/wireguard/

echo "✅ Scripts uploaded"
echo ""

# Execute the final setup on the VM
echo "🔧 Running final setup on VM..."
ssh root@184.105.7.112 "cd /etc/wireguard && chmod +x dr-kover-final-setup.sh && ./dr-kover-final-setup.sh"

echo ""
echo "🧪 Testing the system..."
ssh root@184.105.7.112 "cd /etc/wireguard && ./vpn-status.sh"

echo ""
echo "🎉 INSTALLATION COMPLETE!"
echo ""
echo "Dr. Kover's VPN system is now installed locally and ready to run independently:"
echo ""
echo "✅ Add devices: ssh root@184.105.7.112 'cd /etc/wireguard && ./add-peer.sh [DeviceName]'"
echo "✅ Management menu: ssh root@184.105.7.112 'cd /etc/wireguard && ./vpn-manager.sh'"
echo "✅ Check status: ssh root@184.105.7.112 'cd /etc/wireguard && ./vpn-status.sh'"
echo ""
echo "🏆 The VPN system will continue running after we're gone!"
echo "Dr. Kover can manage all devices independently using these tools."
