#!/bin/bash

# Dr. Kover VPN - Easy Peer Addition Script
# Usage: ./add-peer.sh [device-name]

if [ $# -eq 0 ]; then
    echo "Usage: ./add-peer.sh [device-name]"
    echo "Example: ./add-peer.sh iPad"
    exit 1
fi

DEVICE_NAME="$1"
CONFIG_FILE="DrKover-${DEVICE_NAME}.conf"
SERVER_CONFIG="/etc/wireguard/wg0.conf"
KEYS_DIR="/etc/wireguard"

echo "Adding new peer: $DEVICE_NAME"

# Generate private key for client
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)

# Get server public key
SERVER_PUBLIC_KEY=$(grep PrivateKey "$SERVER_CONFIG" | cut -d' ' -f3 | wg pubkey)

# Find next available IP
LAST_IP=$(grep -E "AllowedIPs.*10.0.0" "$SERVER_CONFIG" | sed 's/.*10.0.0.\([0-9]*\).*/\1/' | sort -n | tail -1)
if [ -z "$LAST_IP" ]; then
    NEXT_IP=2
else
    NEXT_IP=$((LAST_IP + 1))
fi

# Create client configuration
cat > "$CONFIG_FILE" << EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = 10.0.0.$NEXT_IP/32
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0
Endpoint = 184.105.7.112:51820
PersistentKeepalive = 25
EOF

# Add peer to server configuration
cat >> "$SERVER_CONFIG" << EOF

# DrKover - $DEVICE_NAME
[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = 10.0.0.$NEXT_IP/32
EOF

echo "✅ Peer '$DEVICE_NAME' added successfully!"
echo "📁 Configuration saved as: $CONFIG_FILE"
echo "🌐 Assigned IP: 10.0.0.$NEXT_IP"
echo ""
echo "Next steps:"
echo "1. systemctl restart wg-quick@wg0"
echo "2. Transfer $CONFIG_FILE to your device"
echo "3. Import into WireGuard app"
