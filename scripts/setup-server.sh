#!/bin/bash

# VPS WireGuard Setup Script
# This script sets up a complete WireGuard VPN server on Ubuntu/Debian VPS

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VPN_PORT=${VPN_PORT:-51820}
VPN_NETWORK=${VPN_NETWORK:-"10.0.0.0/24"}
SERVER_IP=${SERVER_IP:-"10.0.0.1"}
INTERFACE=${INTERFACE:-"wg0"}

echo -e "${BLUE}🚀 WireGuard VPN Server Setup${NC}"
echo -e "${BLUE}================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root${NC}"
    echo "Please run: sudo $0"
    exit 1
fi

# Update system
echo -e "${YELLOW}📦 Updating system packages...${NC}"
apt update && apt upgrade -y

# Install WireGuard and required packages
echo -e "${YELLOW}📦 Installing WireGuard and dependencies...${NC}"
apt install -y wireguard wireguard-tools iptables resolvconf qrencode

# Enable IP forwarding
echo -e "${YELLOW}🔧 Configuring IP forwarding...${NC}"
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p

# Create WireGuard directory
mkdir -p /etc/wireguard
cd /etc/wireguard

# Generate server keys if they don't exist
if [ ! -f "server_private.key" ]; then
    echo -e "${YELLOW}🔐 Generating server keys...${NC}"
    wg genkey | tee server_private.key | wg pubkey > server_public.key
    wg genpsk > server_preshared.key
    chmod 600 server_private.key server_preshared.key
else
    echo -e "${GREEN}✅ Server keys already exist${NC}"
fi

# Get server private key
SERVER_PRIVATE_KEY=$(cat server_private.key)
SERVER_PUBLIC_KEY=$(cat server_public.key)

# Detect network interface for internet access
INTERNET_INTERFACE=$(ip route | grep default | head -n1 | awk '{print $5}')
if [ -z "$INTERNET_INTERFACE" ]; then
    echo -e "${RED}❌ Could not detect internet interface${NC}"
    echo "Please specify manually:"
    ip link show
    read -p "Enter interface name: " INTERNET_INTERFACE
fi

echo -e "${GREEN}🌐 Using internet interface: $INTERNET_INTERFACE${NC}"

# Create WireGuard configuration
echo -e "${YELLOW}📝 Creating WireGuard configuration...${NC}"
cat > /etc/wireguard/$INTERFACE.conf << EOF
# WireGuard Server Configuration
# Generated on $(date)

[Interface]
PrivateKey = $SERVER_PRIVATE_KEY
Address = $SERVER_IP/$(echo $VPN_NETWORK | cut -d'/' -f2)
ListenPort = $VPN_PORT
SaveConfig = false

# NAT rules for internet access
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $INTERNET_INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $INTERNET_INTERFACE -j MASQUERADE

# Clients will be added below this line
# Use the management tools to add clients
EOF

# Set permissions
chmod 600 /etc/wireguard/$INTERFACE.conf

# Configure firewall
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"

# Install and configure UFW if not present
if ! command -v ufw &> /dev/null; then
    apt install -y ufw
fi

# Reset UFW to defaults
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (be careful not to lock yourself out!)
SSH_PORT=$(ss -tlnp | grep sshd | awk '{print $4}' | cut -d':' -f2 | head -n1)
if [ -n "$SSH_PORT" ]; then
    ufw allow $SSH_PORT/tcp comment 'SSH'
    echo -e "${GREEN}✅ Allowed SSH on port $SSH_PORT${NC}"
else
    ufw allow 22/tcp comment 'SSH (default)'
    echo -e "${YELLOW}⚠️  Allowed SSH on default port 22${NC}"
fi

# Allow WireGuard
ufw allow $VPN_PORT/udp comment 'WireGuard VPN'

# Enable UFW
ufw --force enable

# Enable and start WireGuard
echo -e "${YELLOW}🔧 Enabling WireGuard service...${NC}"
systemctl enable wg-quick@$INTERFACE
systemctl start wg-quick@$INTERFACE

# Verify WireGuard is running
if systemctl is-active --quiet wg-quick@$INTERFACE; then
    echo -e "${GREEN}✅ WireGuard service is running${NC}"
else
    echo -e "${RED}❌ WireGuard service failed to start${NC}"
    systemctl status wg-quick@$INTERFACE
    exit 1
fi

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || curl -s icanhazip.com)
if [ -z "$PUBLIC_IP" ]; then
    echo -e "${YELLOW}⚠️  Could not detect public IP. Please check manually.${NC}"
    PUBLIC_IP="YOUR_SERVER_IP"
fi

# Create info file
cat > /etc/wireguard/server_info.txt << EOF
WireGuard VPN Server Information
Generated on: $(date)

Server Public Key: $SERVER_PUBLIC_KEY
Server Endpoint: $PUBLIC_IP:$VPN_PORT
VPN Network: $VPN_NETWORK
Server VPN IP: $SERVER_IP

Configuration file: /etc/wireguard/$INTERFACE.conf

To add clients, use the management tools:
- python3 -m src.cli.keygen --client <client_name>
- python3 -m src.cli.client_config --name <client_name> --server-ip $PUBLIC_IP

To check status:
- wg show
- systemctl status wg-quick@$INTERFACE

To restart WireGuard:
- systemctl restart wg-quick@$INTERFACE
EOF

# Display setup completion
echo -e "${GREEN}🎉 WireGuard VPN Server Setup Complete!${NC}"
echo -e "${GREEN}=====================================\n${NC}"

echo -e "${BLUE}📋 Server Information:${NC}"
echo -e "   Public IP: ${GREEN}$PUBLIC_IP${NC}"
echo -e "   VPN Port: ${GREEN}$VPN_PORT${NC}"
echo -e "   VPN Network: ${GREEN}$VPN_NETWORK${NC}"
echo -e "   Server VPN IP: ${GREEN}$SERVER_IP${NC}"
echo -e "   Interface: ${GREEN}$INTERFACE${NC}"

echo -e "\n${BLUE}🔐 Server Public Key:${NC}"
echo -e "   ${GREEN}$SERVER_PUBLIC_KEY${NC}"

echo -e "\n${BLUE}📁 Important Files:${NC}"
echo -e "   Config: ${GREEN}/etc/wireguard/$INTERFACE.conf${NC}"
echo -e "   Server Info: ${GREEN}/etc/wireguard/server_info.txt${NC}"
echo -e "   Private Key: ${GREEN}/etc/wireguard/server_private.key${NC}"
echo -e "   Public Key: ${GREEN}/etc/wireguard/server_public.key${NC}"

echo -e "\n${BLUE}🔧 Management Commands:${NC}"
echo -e "   Status: ${GREEN}wg show${NC}"
echo -e "   Restart: ${GREEN}systemctl restart wg-quick@$INTERFACE${NC}"
echo -e "   Logs: ${GREEN}journalctl -u wg-quick@$INTERFACE -f${NC}"

echo -e "\n${BLUE}🚀 Next Steps:${NC}"
echo -e "   1. Use the VPN management tools to create client configurations"
echo -e "   2. Distribute client configs to users"
echo -e "   3. Test connections with ${GREEN}ping $SERVER_IP${NC} from clients"

echo -e "\n${YELLOW}⚠️  Important Security Notes:${NC}"
echo -e "   • Keep your private keys secure and backed up"
echo -e "   • Only share client configs through secure channels"
echo -e "   • Regularly update your VPS and WireGuard"
echo -e "   • Monitor access logs and connected clients"

echo -e "\n${GREEN}✅ Setup completed successfully! Your VPN server is ready.${NC}"
