#!/bin/bash

# WireGuard Client Generator Script
# Quick script to generate client configurations without Python dependencies

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
KEYS_DIR="/etc/wireguard"
CLIENT_NAME=""
SERVER_ENDPOINT=""
SERVER_PORT="51820"
VPN_NETWORK="10.0.0.0/24"
DNS_SERVERS="1.1.1.1, 8.8.8.8"
ALLOWED_IPS="0.0.0.0/0"

# Usage function
usage() {
    echo -e "${BLUE}WireGuard Client Configuration Generator${NC}"
    echo ""
    echo "Usage: $0 -n CLIENT_NAME -s SERVER_IP [OPTIONS]"
    echo ""
    echo "Required:"
    echo "  -n CLIENT_NAME    Name for the client (e.g., Dr-Smith-Laptop)"
    echo "  -s SERVER_IP      Server public IP address"
    echo ""
    echo "Optional:"
    echo "  -p SERVER_PORT    Server port (default: 51820)"
    echo "  -k KEYS_DIR       Keys directory (default: /etc/wireguard)"
    echo "  -d DNS_SERVERS    DNS servers (default: 1.1.1.1, 8.8.8.8)"
    echo "  -a ALLOWED_IPS    Allowed IPs (default: 0.0.0.0/0)"
    echo "  -h                Show this help"
    echo ""
    echo "Example:"
    echo "  $0 -n Dr-Kover-iPad -s 192.168.1.100"
    exit 1
}

# Parse command line arguments
while getopts "n:s:p:k:d:a:h" opt; do
    case $opt in
        n) CLIENT_NAME="$OPTARG" ;;
        s) SERVER_ENDPOINT="$OPTARG" ;;
        p) SERVER_PORT="$OPTARG" ;;
        k) KEYS_DIR="$OPTARG" ;;
        d) DNS_SERVERS="$OPTARG" ;;
        a) ALLOWED_IPS="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Validate required parameters
if [ -z "$CLIENT_NAME" ] || [ -z "$SERVER_ENDPOINT" ]; then
    echo -e "${RED}❌ Error: Client name and server IP are required${NC}"
    usage
fi

echo -e "${BLUE}🔐 Generating WireGuard Client Configuration${NC}"
echo -e "${BLUE}===========================================${NC}"

# Check if WireGuard tools are installed
if ! command -v wg &> /dev/null; then
    echo -e "${RED}❌ WireGuard tools not found. Installing...${NC}"
    
    if command -v apt &> /dev/null; then
        apt update && apt install -y wireguard-tools
    elif command -v yum &> /dev/null; then
        yum install -y wireguard-tools
    elif command -v brew &> /dev/null; then
        brew install wireguard-tools
    else
        echo -e "${RED}❌ Could not install WireGuard tools automatically${NC}"
        echo "Please install wireguard-tools manually"
        exit 1
    fi
fi

# Create directories
mkdir -p "$KEYS_DIR/clients/$CLIENT_NAME"
cd "$KEYS_DIR"

# Check for server public key
SERVER_PUBLIC_KEY=""
for key_file in "server_public.key" "public.key" "server.pub"; do
    if [ -f "$key_file" ]; then
        SERVER_PUBLIC_KEY=$(cat "$key_file")
        echo -e "${GREEN}📁 Found server public key in: $key_file${NC}"
        break
    fi
done

if [ -z "$SERVER_PUBLIC_KEY" ]; then
    echo -e "${RED}❌ Server public key not found in $KEYS_DIR${NC}"
    echo "Expected files: server_public.key, public.key, or server.pub"
    exit 1
fi

# Check for preshared key (optional)
PRESHARED_KEY=""
for psk_file in "server_preshared.key" "preshared.key"; do
    if [ -f "$psk_file" ]; then
        PRESHARED_KEY=$(cat "$psk_file")
        echo -e "${GREEN}🔐 Using preshared key from: $psk_file${NC}"
        break
    fi
done

# Generate client keys
echo -e "${YELLOW}🔐 Generating client keys for: $CLIENT_NAME${NC}"
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)

# Save client keys
echo "$CLIENT_PRIVATE_KEY" > "clients/$CLIENT_NAME/private.key"
echo "$CLIENT_PUBLIC_KEY" > "clients/$CLIENT_NAME/public.key"
chmod 600 "clients/$CLIENT_NAME/private.key"
chmod 644 "clients/$CLIENT_NAME/public.key"

# Allocate client IP (simple increment from base)
VPN_BASE=$(echo "$VPN_NETWORK" | cut -d'/' -f1 | cut -d'.' -f1-3)
CLIENT_IP="$VPN_BASE.$(( 2 + $(ls -1 clients/ | wc -l) ))"

echo -e "${GREEN}📍 Allocated IP: $CLIENT_IP${NC}"

# Generate client configuration
CLIENT_CONFIG="clients/$CLIENT_NAME/$CLIENT_NAME.conf"

cat > "$CLIENT_CONFIG" << EOF
[Interface]
# $CLIENT_NAME - Generated on $(date)
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP/32
DNS = $DNS_SERVERS

[Peer]
# Server
PublicKey = $SERVER_PUBLIC_KEY
$([ -n "$PRESHARED_KEY" ] && echo "PresharedKey = $PRESHARED_KEY")
Endpoint = $SERVER_ENDPOINT:$SERVER_PORT
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25
EOF

# Generate QR code if qrencode is available
QR_FILE="clients/$CLIENT_NAME/${CLIENT_NAME}_qr.png"
if command -v qrencode &> /dev/null; then
    echo -e "${YELLOW}📱 Generating QR code...${NC}"
    qrencode -t png -o "$QR_FILE" < "$CLIENT_CONFIG"
    echo -e "${GREEN}📱 QR code saved: $QR_FILE${NC}"
else
    echo -e "${YELLOW}⚠️  qrencode not found. Install it to generate QR codes.${NC}"
fi

# Generate server peer configuration
SERVER_PEER_CONFIG="clients/$CLIENT_NAME/server_peer.conf"
cat > "$SERVER_PEER_CONFIG" << EOF

# Add this to your server configuration: /etc/wireguard/wg0.conf
[Peer]
# Client: $CLIENT_NAME ($CLIENT_IP)
PublicKey = $CLIENT_PUBLIC_KEY
$([ -n "$PRESHARED_KEY" ] && echo "PresharedKey = $PRESHARED_KEY")
AllowedIPs = $CLIENT_IP/32
EOF

# Set permissions
chmod 600 "$CLIENT_CONFIG"
chmod 644 "$SERVER_PEER_CONFIG"

echo -e "${GREEN}✅ Client configuration generated successfully!${NC}"
echo -e "${GREEN}===============================================\n${NC}"

echo -e "${BLUE}📋 Client Information:${NC}"
echo -e "   Name: ${GREEN}$CLIENT_NAME${NC}"
echo -e "   VPN IP: ${GREEN}$CLIENT_IP${NC}"
echo -e "   Public Key: ${GREEN}$CLIENT_PUBLIC_KEY${NC}"

echo -e "\n${BLUE}📁 Generated Files:${NC}"
echo -e "   Config: ${GREEN}$PWD/$CLIENT_CONFIG${NC}"
echo -e "   Private Key: ${GREEN}$PWD/clients/$CLIENT_NAME/private.key${NC}"
echo -e "   Public Key: ${GREEN}$PWD/clients/$CLIENT_NAME/public.key${NC}"
if [ -f "$QR_FILE" ]; then
    echo -e "   QR Code: ${GREEN}$PWD/$QR_FILE${NC}"
fi
echo -e "   Server Peer Config: ${GREEN}$PWD/$SERVER_PEER_CONFIG${NC}"

echo -e "\n${BLUE}🔧 Server Configuration:${NC}"
echo -e "${YELLOW}Add this to /etc/wireguard/wg0.conf:${NC}"
cat "$SERVER_PEER_CONFIG"

echo -e "\n${BLUE}🚀 Next Steps:${NC}"
echo -e "   1. Add the peer configuration to your server"
echo -e "   2. Restart WireGuard: ${GREEN}systemctl restart wg-quick@wg0${NC}"
echo -e "   3. Send the client config to the user: ${GREEN}$CLIENT_CONFIG${NC}"
if [ -f "$QR_FILE" ]; then
    echo -e "   4. Or share the QR code: ${GREEN}$QR_FILE${NC}"
fi
echo -e "   5. Test connection: ${GREEN}ping $CLIENT_IP${NC} from server"

echo -e "\n${YELLOW}⚠️  Security Reminder:${NC}"
echo -e "   • Share client configs through secure channels only"
echo -e "   • Keep private keys confidential"
echo -e "   • Remove unused client configurations"

echo -e "\n${GREEN}✅ Client '$CLIENT_NAME' is ready to connect!${NC}"
