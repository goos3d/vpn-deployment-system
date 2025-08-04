#!/bin/bash
# Simple VPN Management Script for Dr. Kover
# This script provides easy menu-driven peer management

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Dr. Kover VPN Management System${NC}"
echo "=================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ This script must be run as root${NC}"
    echo "Please run: sudo $0"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "wg0.conf" ]; then
    echo "Changing to WireGuard directory..."
    cd /etc/wireguard || {
        echo -e "${RED}❌ WireGuard directory not found${NC}"
        exit 1
    }
fi

# Menu function
show_menu() {
    echo ""
    echo -e "${YELLOW}📋 What would you like to do?${NC}"
    echo "1. Add a new device"
    echo "2. View VPN status"
    echo "3. List all devices"
    echo "4. List client config files"
    echo "5. Remove a device"
    echo "6. Backup configuration"
    echo "7. Exit"
    echo ""
}

# Add peer function
add_peer() {
    echo ""
    echo -e "${GREEN}📱 Adding New Device${NC}"
    echo "==================="
    
    read -p "Enter device name (e.g., iPad, iPhone, OfficePC): " DEVICE_NAME
    
    if [ -z "$DEVICE_NAME" ]; then
        echo -e "${RED}❌ Device name cannot be empty${NC}"
        return 1
    fi
    
    # Check if device already exists
    if grep -q "# Peer: $DEVICE_NAME" wg0.conf; then
        echo -e "${RED}❌ Device '$DEVICE_NAME' already exists${NC}"
        return 1
    fi
    
    echo "🔑 Generating configuration for $DEVICE_NAME..."
    ./add-peer.sh "$DEVICE_NAME"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${YELLOW}🔄 Restarting VPN service...${NC}"
        systemctl restart wg-quick@wg0
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Device '$DEVICE_NAME' added successfully!${NC}"
            echo -e "${BLUE}📁 Config file: DrKover-$DEVICE_NAME.conf${NC}"
        else
            echo -e "${RED}❌ Failed to restart VPN service${NC}"
        fi
    else
        echo -e "${RED}❌ Failed to add device${NC}"
    fi
}

# Show status function
show_status() {
    echo ""
    echo -e "${GREEN}📊 VPN Status${NC}"
    echo "============="
    
    echo ""
    echo -e "${YELLOW}Service Status:${NC}"
    systemctl status wg-quick@wg0 --no-pager -l | head -5
    
    echo ""
    echo -e "${YELLOW}Active Connections:${NC}"
    wg show
    
    echo ""
    echo -e "${YELLOW}Server Information:${NC}"
    echo "Server IP: $(curl -s ifconfig.me 2>/dev/null || echo 'Unable to detect')"
    echo "VPN Port: $(grep ListenPort wg0.conf | cut -d' ' -f3)"
    echo "Total Peers: $(grep -c '\[Peer\]' wg0.conf)"
}

# List devices function
list_devices() {
    echo ""
    echo -e "${GREEN}📱 Configured Devices${NC}"
    echo "===================="
    
    echo ""
    PEER_COUNT=$(grep -c "\[Peer\]" wg0.conf)
    echo "Total devices configured: $PEER_COUNT"
    
    if [ $PEER_COUNT -gt 0 ]; then
        echo ""
        echo "Device list:"
        grep "# Peer:" wg0.conf | while read -r line; do
            DEVICE=$(echo "$line" | cut -d' ' -f3)
            echo "  • $DEVICE"
        done
    fi
}

# List config files function
list_configs() {
    echo ""
    echo -e "${GREEN}📁 Client Configuration Files${NC}"
    echo "============================="
    
    CONFIG_COUNT=$(ls -1 DrKover-*.conf 2>/dev/null | wc -l)
    echo "Available config files: $CONFIG_COUNT"
    
    if [ $CONFIG_COUNT -gt 0 ]; then
        echo ""
        ls -la DrKover-*.conf | while read -r line; do
            FILE=$(echo "$line" | awk '{print $9}')
            SIZE=$(echo "$line" | awk '{print $5}')
            echo "  📄 $FILE ($SIZE bytes)"
        done
        
        echo ""
        echo -e "${YELLOW}💡 To download a config file to your computer:${NC}"
        echo "   scp root@184.105.7.112:/etc/wireguard/DrKover-DeviceName.conf ./"
    fi
}

# Remove peer function
remove_peer() {
    echo ""
    echo -e "${RED}🗑️  Remove Device${NC}"
    echo "================="
    
    # Show current devices
    PEER_COUNT=$(grep -c "\[Peer\]" wg0.conf)
    if [ $PEER_COUNT -eq 0 ]; then
        echo "No devices configured to remove."
        return 1
    fi
    
    echo "Current devices:"
    grep "# Peer:" wg0.conf | while read -r line; do
        DEVICE=$(echo "$line" | cut -d' ' -f3)
        echo "  • $DEVICE"
    done
    
    echo ""
    read -p "Enter device name to remove: " DEVICE_NAME
    
    if [ -z "$DEVICE_NAME" ]; then
        echo -e "${RED}❌ Device name cannot be empty${NC}"
        return 1
    fi
    
    # Check if device exists
    if ! grep -q "# Peer: $DEVICE_NAME" wg0.conf; then
        echo -e "${RED}❌ Device '$DEVICE_NAME' not found${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${RED}⚠️  This will permanently remove device '$DEVICE_NAME'${NC}"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Backup first
        cp wg0.conf "wg0.conf.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Remove peer from config (this is complex, recommend manual editing)
        echo -e "${YELLOW}📝 Please manually edit the configuration:${NC}"
        echo "1. Run: nano wg0.conf"
        echo "2. Find and delete the [Peer] section for $DEVICE_NAME"
        echo "3. Save and exit"
        echo "4. Run: systemctl restart wg-quick@wg0"
        echo "5. Run: rm DrKover-$DEVICE_NAME.conf"
        
        read -p "Press Enter when you've completed the manual removal..."
        
        echo -e "${GREEN}✅ Manual removal process completed${NC}"
    else
        echo "❌ Removal cancelled"
    fi
}

# Backup function
backup_config() {
    echo ""
    echo -e "${BLUE}💾 Backup Configuration${NC}"
    echo "======================"
    
    BACKUP_FILE="wg0-backup-$(date +%Y%m%d_%H%M%S).conf"
    cp wg0.conf "$BACKUP_FILE"
    
    echo "✅ Configuration backed up to: $BACKUP_FILE"
    echo "📁 Backup location: /etc/wireguard/$BACKUP_FILE"
}

# Main menu loop
while true; do
    show_menu
    read -p "Enter your choice (1-7): " choice
    
    case $choice in
        1)
            add_peer
            ;;
        2)
            show_status
            ;;
        3)
            list_devices
            ;;
        4)
            list_configs
            ;;
        5)
            remove_peer
            ;;
        6)
            backup_config
            ;;
        7)
            echo ""
            echo -e "${GREEN}👋 Thanks for using Dr. Kover VPN Management!${NC}"
            echo "Your VPN is running securely."
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid option. Please choose 1-7.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done
