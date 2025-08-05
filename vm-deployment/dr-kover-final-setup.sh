#!/bin/bash

# Dr. Kover VPN - Final VM Setup Script
# This script deploys all the peer management tools

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║              Dr. Kover VPN - Final Setup Deployment                         ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Ensure we're in the right directory
cd /etc/wireguard

# The add-peer.sh script should already be here, but let's make sure it's executable
if [ ! -f "add-peer.sh" ]; then
    echo "❌ add-peer.sh not found. Please upload it first."
    exit 1
fi

# The vpn-manager.sh script should already be here
if [ ! -f "vpn-manager.sh" ]; then
    echo "❌ vpn-manager.sh not found. Please upload it first."
    exit 1
fi

# The vpn-status.sh script should already be here
if [ ! -f "vpn-status.sh" ]; then
    echo "❌ vpn-status.sh not found. Please upload it first."
    exit 1
fi

echo "🔧 Setting up Dr. Kover's VPN management system..."

# Make all scripts executable
chmod +x add-peer.sh
chmod +x vpn-manager.sh
chmod +x vpn-status.sh
chmod +x dr-kover-final-setup.sh

echo "✅ Scripts made executable"

# Test the VPN service
if systemctl is-active --quiet wg-quick@wg0; then
    echo "✅ VPN service is running"
else
    echo "🔄 Starting VPN service..."
    systemctl start wg-quick@wg0
    if systemctl is-active --quiet wg-quick@wg0; then
        echo "✅ VPN service started successfully"
    else
        echo "❌ Failed to start VPN service"
        exit 1
    fi
fi

# Create a quick reference file
cat > VPN_QUICK_REFERENCE.txt << EOF
Dr. Kover VPN - Quick Reference
==============================

Add a new device:
./add-peer.sh [DeviceName]
systemctl restart wg-quick@wg0

Interactive menu:
./vpn-manager.sh

Check status:
./vpn-status.sh

View connected devices:
wg show

Your server: 184.105.7.112:51820
Network range: 10.0.0.x

Support: thomas@eastbayav.com | (510) 666-5915
EOF

echo "✅ Quick reference guide created"

echo ""
echo "🎉 SETUP COMPLETE!"
echo ""
echo "Dr. Kover's VPN management system is ready:"
echo ""
echo "📱 To add devices: ./add-peer.sh [DeviceName]"
echo "🎛️  Interactive menu: ./vpn-manager.sh"
echo "📊 Check status: ./vpn-status.sh"
echo "📖 Reference: cat VPN_QUICK_REFERENCE.txt"
echo ""
echo "✅ All systems operational and ready for use!"
