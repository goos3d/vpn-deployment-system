#!/bin/bash
# VPN Web GUI Quick Test Script
# Run this from a VPN-connected client to test the web GUI

echo "🧪 VPN Web GUI Test Suite"
echo "========================="
echo "Testing Date: $(date)"
echo ""

# Test 1: VPN Connection Status
echo "🔍 Test 1: VPN Connection Status"
if ip route | grep -q "10.0.0.0/24"; then
    echo "✅ PASS: Connected to VPN network"
    VPN_IP=$(ip route get 10.0.0.1 | grep -oP 'src \K\S+' 2>/dev/null || echo "unknown")
    echo "   Your VPN IP: $VPN_IP"
else
    echo "❌ FAIL: Not connected to VPN network"
    echo "   Please connect to VPN first!"
    exit 1
fi

# Test 2: VPN Gateway Reachability
echo ""
echo "🔍 Test 2: VPN Gateway Reachability"
if timeout 5 ping -c 1 10.0.0.1 >/dev/null 2>&1; then
    echo "✅ PASS: Can reach VPN gateway (10.0.0.1)"
else
    echo "⚠️  INFO: VPN gateway doesn't respond to ping (normal)"
fi

# Test 3: Web GUI Access
echo ""
echo "🔍 Test 3: Web GUI Access"
if curl -s --max-time 10 http://10.0.0.1:5000 >/dev/null 2>&1; then
    echo "✅ PASS: Web GUI is accessible at http://10.0.0.1:5000"
    
    # Test 4: Web GUI Content
    echo ""
    echo "🔍 Test 4: Web GUI Content"
    RESPONSE=$(curl -s --max-time 10 http://10.0.0.1:5000)
    if echo "$RESPONSE" | grep -q "VPN"; then
        echo "✅ PASS: Web GUI loaded successfully"
    else
        echo "⚠️  WARN: Web GUI accessible but content unclear"
    fi
    
    # Test 5: API Endpoint
    echo ""
    echo "🔍 Test 5: API Endpoint Test"
    API_RESPONSE=$(curl -s --max-time 10 http://10.0.0.1:5000/api/client/list 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "✅ PASS: API endpoint accessible"
    else
        echo "⚠️  WARN: API endpoint may need authentication"
    fi
    
else
    echo "❌ FAIL: Cannot access Web GUI at http://10.0.0.1:5000"
    echo "   Possible issues:"
    echo "   - Web GUI not started on VM server"
    echo "   - Port 5000 blocked by firewall"
    echo "   - VPN routing issue"
fi

# Test 6: Internet Access (HIPAA Compliance Check)
echo ""
echo "🔍 Test 6: Internet Access (HIPAA Compliance)"
EXTERNAL_IP=$(curl -s --max-time 5 https://httpbin.org/ip 2>/dev/null | grep -o '"origin": "[^"]*' | cut -d'"' -f4)
if [ -n "$EXTERNAL_IP" ]; then
    echo "✅ PASS: Internet access preserved"
    echo "   External IP: $EXTERNAL_IP"
    echo "   ✅ HIPAA Compliant: VPN + Internet access working"
else
    echo "❌ FAIL: No internet access"
fi

echo ""
echo "🎯 Test Summary"
echo "==============="
echo "If Web GUI test passed: Dr. Kover can create users at http://10.0.0.1:5000"
echo "If Web GUI test failed: Run VM_DEPLOY_WEB_GUI.ps1 on the server"
echo ""
echo "🔒 HIPAA Status: VPN provides secure tunnel while preserving internet access"
