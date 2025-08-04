#!/bin/bash

# Dr. Kover VPN Automation Installation Script
# Professional Service by East Bay AV Solutions
# Support: thomas@eastbayav.com | (510) 666-5915

echo "================================================================================================"
echo "                       DR. KOVER VPN AUTOMATION INSTALLER"
echo "                     Professional Service - $200 Value Package"
echo "================================================================================================"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ This installer must be run as root"
    echo "   Please run: sudo $0"
    exit 1
fi

echo "✅ Root access confirmed"

# Check if WireGuard is installed
if ! command -v wg >/dev/null 2>&1; then
    echo "❌ WireGuard is not installed"
    echo "   Please install WireGuard first: apt update && apt install wireguard"
    exit 1
fi

echo "✅ WireGuard installation confirmed"

# Create professional directory structure
echo "📁 Creating professional directory structure..."
mkdir -p /etc/wireguard/backups
mkdir -p /etc/wireguard/clients
chmod 700 /etc/wireguard/backups
chmod 700 /etc/wireguard/clients

# Install the professional script
echo "📋 Installing professional peer addition script..."
cp production-add-peer.sh /etc/wireguard/add-peer.sh
chmod +x /etc/wireguard/add-peer.sh
chown root:root /etc/wireguard/add-peer.sh

# Create symlink for easy access
ln -sf /etc/wireguard/add-peer.sh /usr/local/bin/add-peer

echo "✅ Professional VPN automation installed successfully!"
echo
echo "USAGE:"
echo "  add-peer iPhone-DrKover          # Add Dr. Kover's iPhone"
echo "  add-peer iPad-Reception          # Add reception iPad"
echo "  add-peer --help                  # Show all options"
echo
echo "FEATURES:"
echo "  ⚡ 30-second peer addition vs 15-minute manual process"
echo "  🔒 Automatic backups and rollback protection"
echo "  📊 Professional logging and monitoring"
echo "  🛠️  Error handling and recovery"
echo
echo "SUPPORT:"
echo "  📧 Email: thomas@eastbayav.com"
echo "  📱 Phone: (510) 666-5915"
echo
echo "Your $200 professional automation investment is now active!"
echo "================================================================================================"
