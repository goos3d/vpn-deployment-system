#!/bin/bash

# Quick launch script for Smart VPN Manager with Web GUI Integration
echo "🎯 Launching Smart VPN Manager with MacBook-Test Pattern"
echo "Uses working configuration: AllowedIPs = 10.0.0.0/24"
echo "Provides: ✅ VPN Access + ✅ Internet Access"
echo ""

# Check if in handoff directory
if [ -f "vpn-deployment-system-handoff-test/smart_vpn_manager.py" ]; then
    echo "📍 Running from handoff directory..."
    cd vpn-deployment-system-handoff-test
    python3 smart_vpn_manager.py
else
    echo "❌ Please run from the main workspace directory"
    echo "Expected: vpn-deployment-system-handoff-test/smart_vpn_manager.py"
    exit 1
fi
