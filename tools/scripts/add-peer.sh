#!/bin/bash
# Peer Addition Script for VPN Server
# Usage: ./add-peer.sh <peer-name> [server-ip]

PEER_NAME=$1
SERVER_IP=${2:-$(curl -s ifconfig.me)}

if [ -z "$PEER_NAME" ]; then
    echo "❌ Usage: ./add-peer.sh <peer-name> [server-ip]"
    echo "   Example: ./add-peer.sh iPad"
    echo "   Example: ./add-peer.sh iPhone 184.105.7.112"
    exit 1
fi

echo "🔑 Generating keys for $PEER_NAME..."

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root or with sudo"
    exit 1
fi

# Navigate to WireGuard directory
cd /etc/wireguard || {
    echo "❌ WireGuard directory not found. Is WireGuard installed?"
    exit 1
}

# Generate keys
PRIVATE_KEY=$(wg genkey)
PUBLIC_KEY=$(echo $PRIVATE_KEY | wg pubkey)

echo "✅ Keys generated successfully"
echo "🔍 Private Key: $PRIVATE_KEY"
echo "🔍 Public Key: $PUBLIC_KEY"

# Get server public key
SERVER_PUBLIC_KEY=$(grep "PrivateKey" wg0.conf | head -1 | cut -d' ' -f3 | wg pubkey)

# Get next available IP (assuming 10.0.0.x network)
if [ -f wg0.conf ]; then
    LAST_IP=$(grep -o "10\.0\.0\.[0-9]*" wg0.conf | sort -V | tail -1 | cut -d. -f4)
    NEXT_IP=$((LAST_IP + 1))
else
    echo "❌ Server config wg0.conf not found"
    exit 1
fi

CLIENT_IP="10.0.0.$NEXT_IP"
echo "📍 Assigned IP: $CLIENT_IP"

# Backup original config
cp wg0.conf wg0.conf.backup.$(date +%Y%m%d_%H%M%S)

# Add peer to server config
echo "" >> wg0.conf
echo "# Peer: $PEER_NAME (added $(date))" >> wg0.conf
echo "[Peer]" >> wg0.conf
echo "PublicKey = $PUBLIC_KEY" >> wg0.conf
echo "AllowedIPs = $CLIENT_IP/32" >> wg0.conf

# Create client config
CLIENT_CONFIG="DrKover-$PEER_NAME.conf"

cat > "$CLIENT_CONFIG" << EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $CLIENT_IP/32
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

echo "✅ Peer $PEER_NAME added successfully!"
echo "📁 Client config created: $CLIENT_CONFIG"
echo "📍 Client IP: $CLIENT_IP"
echo ""
echo "🔄 To activate changes, run:"
echo "   systemctl restart wg-quick@wg0"
echo ""
echo "📋 Summary:"
echo "   - Peer Name: $PEER_NAME"
echo "   - IP Address: $CLIENT_IP"
echo "   - Config File: $CLIENT_CONFIG"
echo "   - Server Endpoint: $SERVER_IP:51820"
