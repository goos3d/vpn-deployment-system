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
