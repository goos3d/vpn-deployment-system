#!/bin/bash
# Batch Peer Addition Script for VPN Server
# Usage: ./add-multiple-peers.sh

echo "🚀 Adding multiple peers for VPN setup..."

# Default peer names - can be customized
PEERS=("iPad" "iPhone" "OfficePC" "HomePC" "Laptop")

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

echo "📋 Will add the following peers:"
for PEER in "${PEERS[@]}"; do
    echo "   - $PEER"
done

echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled"
    exit 1
fi

# Add each peer
for PEER in "${PEERS[@]}"; do
    echo "🔧 Adding $PEER..."
    /root/add-peer.sh $PEER
    if [ $? -eq 0 ]; then
        echo "✅ $PEER added successfully"
    else
        echo "❌ Failed to add $PEER"
    fi
    echo "---"
done

echo "🔄 Restarting WireGuard..."
systemctl restart wg-quick@wg0

if [ $? -eq 0 ]; then
    echo "✅ WireGuard restarted successfully"
else
    echo "❌ Failed to restart WireGuard"
    exit 1
fi

echo ""
echo "📁 Client configs created:"
ls -la /etc/wireguard/DrKover-*.conf

echo ""
echo "🔍 Current VPN status:"
wg show

echo ""
echo "✅ All peers added successfully!"
echo "📧 Ready to deliver client configuration files."
