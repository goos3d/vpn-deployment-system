#!/bin/bash
# VPN Status Check Script
# Shows comprehensive status of WireGuard VPN

echo "🔍 VPN System Status Report"
echo "=========================="
echo "Date: $(date)"
echo "Server: $(hostname)"
echo ""

echo "📊 WireGuard Service Status:"
systemctl status wg-quick@wg0 --no-pager -l | head -10
echo ""

echo "🔗 Active Connections:"
wg show
echo ""

echo "📋 Configured Peers:"
PEER_COUNT=$(grep -c "\[Peer\]" /etc/wireguard/wg0.conf)
echo "Total peers configured: $PEER_COUNT"
echo ""

echo "📁 Available Client Configs:"
CLIENT_CONFIGS=$(ls -1 /etc/wireguard/DrKover-*.conf 2>/dev/null | wc -l)
echo "Client configs available: $CLIENT_CONFIGS"
if [ $CLIENT_CONFIGS -gt 0 ]; then
    echo "Config files:"
    ls -la /etc/wireguard/DrKover-*.conf | awk '{print "  " $9 " (" $5 " bytes)"}'
fi
echo ""

echo "🌐 Network Information:"
echo "Server IP: $(curl -s ifconfig.me 2>/dev/null || echo "Unable to detect")"
echo "WireGuard Port: $(grep ListenPort /etc/wireguard/wg0.conf | cut -d' ' -f3)"
echo ""

echo "🔒 Firewall Status:"
ufw status | head -10
echo ""

echo "💾 Disk Usage (WireGuard directory):"
du -sh /etc/wireguard/
echo ""

echo "✅ Status check complete!"
