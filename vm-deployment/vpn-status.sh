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
