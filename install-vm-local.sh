#!/bin/bash

# Dr. Kover VPN - Local VM Installation Script
# Run this script directly on the VM (184.105.7.112) to install the management system

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║              Dr. Kover VPN - Local VM Installation                          ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

echo "🎯 Installing VPN management system locally on this VM..."
echo "📍 Current location: $(hostname) - $(curl -s ifconfig.me 2>/dev/null || echo "Local VM")"
echo ""

# Ensure we're in the right directory
cd /etc/wireguard || { echo "❌ /etc/wireguard directory not found!"; exit 1; }

echo "📁 Working in: $(pwd)"
echo ""

# Copy the management scripts from our development folder
echo "📋 Installing management scripts..."

# Create add-peer.sh script
cat > add-peer.sh << 'EOF'
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
cat > "$CONFIG_FILE" << EOFCONFIG
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = 10.0.0.$NEXT_IP/32
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0
Endpoint = 184.105.7.112:51820
PersistentKeepalive = 25
EOFCONFIG

# Add peer to server configuration
cat >> "$SERVER_CONFIG" << EOFCONFIG

# DrKover - $DEVICE_NAME
[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = 10.0.0.$NEXT_IP/32
EOFCONFIG

echo "✅ Peer '$DEVICE_NAME' added successfully!"
echo "📁 Configuration saved as: $CONFIG_FILE"
echo "🌐 Assigned IP: 10.0.0.$NEXT_IP"
echo ""
echo "Next steps:"
echo "1. systemctl restart wg-quick@wg0"
echo "2. Transfer $CONFIG_FILE to your device"
echo "3. Import into WireGuard app"
EOF

# Create vpn-manager.sh script
cat > vpn-manager.sh << 'EOF'
#!/bin/bash

# Dr. Kover VPN Management System
clear

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                        Dr. Kover VPN Management System                      ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

while true; do
    echo "What would you like to do?"
    echo ""
    echo "1) 📱 Add a new device"
    echo "2) 📊 Check VPN status"
    echo "3) 📋 List all devices"
    echo "4) 🔍 Show connected devices"
    echo "5) 🔄 Restart VPN service"
    echo "6) 📁 List configuration files"
    echo "7) ❌ Exit"
    echo ""
    read -p "Enter your choice (1-7): " choice

    case $choice in
        1)
            echo ""
            read -p "Enter device name (e.g., iPad, iPhone, OfficePC): " device_name
            if [ ! -z "$device_name" ]; then
                ./add-peer.sh "$device_name"
                echo ""
                read -p "Restart VPN service now? (y/n): " restart
                if [ "$restart" = "y" ]; then
                    systemctl restart wg-quick@wg0
                    echo "✅ VPN service restarted"
                fi
            else
                echo "❌ Device name cannot be empty"
            fi
            ;;
        2)
            echo ""
            echo "VPN Service Status:"
            systemctl status wg-quick@wg0 --no-pager -l
            ;;
        3)
            echo ""
            echo "All configured devices:"
            grep -E "# DrKover -" /etc/wireguard/wg0.conf | sed 's/# DrKover - /- /'
            ;;
        4)
            echo ""
            echo "Currently connected devices:"
            wg show
            ;;
        5)
            echo ""
            systemctl restart wg-quick@wg0
            echo "✅ VPN service restarted"
            ;;
        6)
            echo ""
            echo "Configuration files:"
            ls -la DrKover-*.conf 2>/dev/null || echo "No configuration files found"
            ;;
        7)
            echo ""
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo ""
            echo "❌ Invalid choice. Please enter 1-7."
            ;;
    esac
    
    echo ""
    echo "Press Enter to continue..."
    read
    clear
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                        Dr. Kover VPN Management System                      ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""
done
EOF

# Create vpn-status.sh script
cat > vpn-status.sh << 'EOF'
#!/bin/bash

# Dr. Kover VPN Status Checker
clear

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                           Dr. Kover VPN Status                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if VPN service is running
echo "🔍 VPN Service Status:"
if systemctl is-active --quiet wg-quick@wg0; then
    echo "✅ WireGuard VPN is RUNNING"
else
    echo "❌ WireGuard VPN is NOT RUNNING"
    echo "   Try: systemctl start wg-quick@wg0"
fi
echo ""

# Show server information
echo "🌐 Server Information:"
echo "   Server IP: 184.105.7.112"
echo "   VPN Port: 51820"
echo "   Network: 10.0.0.x"
echo ""

# Show configured devices
echo "📱 Configured Devices:"
DEVICE_COUNT=$(grep -c "# DrKover -" /etc/wireguard/wg0.conf 2>/dev/null || echo "0")
if [ "$DEVICE_COUNT" -gt 0 ]; then
    grep -E "# DrKover -" /etc/wireguard/wg0.conf | sed 's/# DrKover - /   ✓ /'
    echo "   Total: $DEVICE_COUNT devices configured"
else
    echo "   No devices configured yet"
fi
echo ""

# Show currently connected devices
echo "🔗 Currently Connected:"
CONNECTED=$(wg show wg0 peers 2>/dev/null | wc -l)
if [ "$CONNECTED" -gt 0 ]; then
    echo "   $CONNECTED devices connected"
    wg show wg0 | grep -A2 "peer:" | while read line; do
        if [[ $line == peer:* ]]; then
            echo "   📱 Device connected"
        fi
    done
else
    echo "   No devices currently connected"
fi
echo ""

# Show recent connection activity
echo "📊 Recent Activity:"
journalctl -u wg-quick@wg0 --since "1 hour ago" --no-pager -q | tail -5 | while read line; do
    echo "   $line"
done || echo "   No recent activity"
echo ""

# Show system resources
echo "💾 System Resources:"
echo "   Uptime: $(uptime -p)"
echo "   Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "   Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
echo ""

echo "Need help? Contact thomas@eastbayav.com or (510) 666-5915"
EOF

# Make all scripts executable
echo "🔧 Setting up permissions..."
chmod +x add-peer.sh
chmod +x vpn-manager.sh
chmod +x vpn-status.sh

echo "✅ All scripts installed and made executable"

# Test the VPN service
echo ""
echo "🧪 Testing VPN service..."
if systemctl is-active --quiet wg-quick@wg0; then
    echo "✅ VPN service is running"
else
    echo "🔄 Starting VPN service..."
    systemctl start wg-quick@wg0
    if systemctl is-active --quiet wg-quick@wg0; then
        echo "✅ VPN service started successfully"
    else
        echo "❌ Failed to start VPN service"
        echo "   Try: systemctl status wg-quick@wg0"
    fi
fi

# Create a quick reference file
echo ""
echo "📖 Creating quick reference guide..."
cat > VPN_QUICK_REFERENCE.txt << 'EOF'
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
echo "🎉 INSTALLATION COMPLETE!"
echo ""
echo "Dr. Kover's VPN management system is ready:"
echo ""
echo "📱 To add devices: ./add-peer.sh [DeviceName]"
echo "🎛️  Interactive menu: ./vpn-manager.sh"
echo "📊 Check status: ./vpn-status.sh"
echo "📖 Reference: cat VPN_QUICK_REFERENCE.txt"
echo ""
echo "✅ All systems operational and ready for use!"
echo "🏆 The VPN will continue running independently after installation!"

# Run a quick test
echo ""
echo "🚀 Running final system test..."
./vpn-status.sh
