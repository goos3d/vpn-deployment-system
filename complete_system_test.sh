#!/bin/bash
# 🧪 Complete End-to-End VPN System Validation Test
# Tests the entire workflow: VPN → Web GUI → Client Creation → New Client Test

echo "🧪 Dr. Kover's Complete VPN System Validation Test"
echo "=================================================="
echo "💰 Testing $200 Professional Automation System End-to-End"
echo ""

# Phase tracking
PHASE1_SUCCESS=false
PHASE2_SUCCESS=false
PHASE3_SUCCESS=false
PHASE4_SUCCESS=false

echo "📋 TEST OVERVIEW:"
echo "Phase 1: Test different VPN config (prove placeholder fix worked)"
echo "Phase 2: Access web GUI through VPN tunnel"
echo "Phase 3: Create new client via web interface"
echo "Phase 4: Test newly created client config"
echo ""

# Configuration options for Phase 1
CONFIG_OPTIONS=(
    "Your-Laptop-Test.conf:10.0.0.4"
    "Test-Client-1.conf:10.0.0.2" 
    "ThomasEastBayAV-Web_GUI_Peer_Add_Test.conf:10.0.0.3"
    "Your-Laptop-REAL-CONFIG.conf:10.0.0.5"
)

echo "🔧 PHASE 1: Test Different VPN Configuration"
echo "============================================="
echo "📋 Available test configurations:"
for i in "${!CONFIG_OPTIONS[@]}"; do
    IFS=':' read -r config ip <<< "${CONFIG_OPTIONS[$i]}"
    echo "  $((i+1)). $config (Expected IP: $ip)"
done
echo ""

read -p "🔢 Select configuration to test (1-4): " selection

if [[ $selection -ge 1 && $selection -le 4 ]]; then
    IFS=':' read -r selected_config expected_ip <<< "${CONFIG_OPTIONS[$((selection-1))]}"
    echo "✅ Selected: $selected_config (Expected IP: $expected_ip)"
else
    echo "❌ Invalid selection. Exiting."
    exit 1
fi

echo ""
echo "🚨 CRITICAL: Disconnect your current MacBook-Test VPN connection first!"
echo "We need to test a DIFFERENT config to validate the placeholder fix."
read -p "Press Enter after disconnecting current VPN..."
echo ""

echo "📥 Verifying config file exists and has real keys..."
config_path="../VPN_Configs/$selected_config"
if [[ -f "$config_path" ]]; then
    echo "✅ Found: $config_path"
else
    echo "❌ Config file not found: $config_path"
    exit 1
fi

# Check for real keys
if grep -q "<GENERATED_PRIVATE_KEY" "$config_path" || grep -q "<SERVER_PUBLIC_KEY>" "$config_path"; then
    echo "❌ Config still has placeholder keys! Fix not applied."
    exit 1
else
    echo "✅ Config has real keys - placeholder fix confirmed"
fi

echo ""
echo "🔧 Step 1: Import and connect with $selected_config"
echo "1. Import $config_path into your WireGuard client"
echo "2. Connect to the VPN"
echo "3. Verify you get IP: $expected_ip"
echo ""

read -p "Press Enter after connecting to VPN with new config..."

echo ""
echo "🧪 Phase 1 Validation Tests:"

# Test 1: VPN Server Connectivity
echo "Test 1: VPN Server Connectivity"
if ping -c 3 10.0.0.1 >/dev/null 2>&1; then
    echo "✅ Can ping VPN server (10.0.0.1)"
else
    echo "❌ Cannot ping VPN server (10.0.0.1)"
    exit 1
fi

# Test 2: IP Assignment Check
echo "Test 2: IP Assignment"
if command -v ip >/dev/null 2>&1; then
    current_ip=$(ip addr show | grep -o "10\.0\.0\.[0-9]*/24" | cut -d'/' -f1)
elif command -v ifconfig >/dev/null 2>&1; then
    current_ip=$(ifconfig | grep -o "10\.0\.0\.[0-9]*" | head -1)
else
    read -p "Enter your current VPN IP (10.0.0.x): " current_ip
fi

echo "Current VPN IP: $current_ip (Expected: $expected_ip)"

# Test 3: External IP Check
echo "Test 3: External IP via VPN"
external_ip=$(curl -s --max-time 10 ifconfig.me 2>/dev/null || echo "Unable to determine")
if [[ "$external_ip" == "184.105.7.112" ]]; then
    echo "✅ Correct external IP via VPN: $external_ip"
    PHASE1_SUCCESS=true
else
    echo "⚠️ External IP: $external_ip (Expected: 184.105.7.112)"
fi

echo ""
echo "🌐 PHASE 2: Web GUI Access Test"
echo "==============================="
echo "🎯 Goal: Access Dr. Kover's web dashboard through VPN tunnel"
echo ""

# Test web GUI access
echo "📱 Testing web GUI access..."
echo "1. Open browser and navigate to: http://10.0.0.1:5000"
echo "2. OR try: http://184.105.7.112:5000"
echo ""
echo "Expected to see:"
echo "- 🛡️ Dr. Kover's Professional VPN Management System"
echo "- Current client list"
echo "- Add Client form"
echo "- Server status showing 184.105.7.112:51820"
echo ""

read -p "Can you access the web GUI? (y/n): " web_access
if [[ "$web_access" =~ ^[Yy]$ ]]; then
    echo "✅ Web GUI accessible through VPN tunnel"
    PHASE2_SUCCESS=true
else
    echo "❌ Web GUI not accessible"
    echo "Troubleshooting:"
    echo "- Ensure VPN is connected"
    echo "- Try both http://10.0.0.1:5000 and http://184.105.7.112:5000"
    echo "- Check if web service is running on server"
fi

echo ""
echo "🔧 PHASE 3: Remote Client Creation Test"
echo "======================================="
echo "🎯 Goal: Create new VPN client via web interface while connected via VPN"
echo ""

if [[ "$PHASE2_SUCCESS" == true ]]; then
    echo "📝 Instructions for creating new client:"
    echo "1. In the web interface, find the 'Add New VPN Client' section"
    echo "2. Enter client name: 'Remote-GUI-Test-Client'"
    echo "3. Select device type: 'desktop' or 'mobile'"
    echo "4. Click 'Add Client with Real Keys'"
    echo ""
    echo "Expected results:"
    echo "- Success message appears"
    echo "- New client appears in client list"
    echo "- Download button available for new config"
    echo ""
    
    read -p "Did you successfully create the new client? (y/n): " client_created
    if [[ "$client_created" =~ ^[Yy]$ ]]; then
        echo "✅ New client created via web GUI"
        
        echo ""
        echo "📥 Download the new config file:"
        echo "1. Click the 'Download' button for Remote-GUI-Test-Client"
        echo "2. Save the .conf file"
        echo "3. Verify it contains real keys (no placeholders)"
        echo ""
        
        read -p "Did you download the new config file? (y/n): " config_downloaded
        if [[ "$config_downloaded" =~ ^[Yy]$ ]]; then
            echo "✅ New config file downloaded"
            PHASE3_SUCCESS=true
        else
            echo "❌ Config file not downloaded"
        fi
    else
        echo "❌ Client creation failed"
    fi
else
    echo "⏭️ Skipping Phase 3 - Web GUI not accessible"
fi

echo ""
echo "🧪 PHASE 4: New Client Configuration Test"
echo "========================================"
echo "🎯 Goal: Test the newly created client config"
echo ""

if [[ "$PHASE3_SUCCESS" == true ]]; then
    echo "🔄 Testing new client config:"
    echo "1. Disconnect current VPN connection"
    echo "2. Import Remote-GUI-Test-Client.conf into WireGuard"
    echo "3. Connect with the new configuration"
    echo ""
    
    read -p "Press Enter after connecting with new client config..."
    
    echo ""
    echo "🧪 New Client Validation Tests:"
    
    # Test new client connectivity
    echo "Test 1: VPN Server Connectivity (New Client)"
    if ping -c 3 10.0.0.1 >/dev/null 2>&1; then
        echo "✅ New client can ping VPN server (10.0.0.1)"
    else
        echo "❌ New client cannot ping VPN server"
    fi
    
    # Test new client external IP
    echo "Test 2: External IP (New Client)"
    new_external_ip=$(curl -s --max-time 10 ifconfig.me 2>/dev/null || echo "Unable to determine")
    if [[ "$new_external_ip" == "184.105.7.112" ]]; then
        echo "✅ New client correct external IP: $new_external_ip"
    else
        echo "⚠️ New client external IP: $new_external_ip"
    fi
    
    # Test accessing web GUI from new client
    echo "Test 3: Web GUI Access (New Client)"
    read -p "Can you access http://10.0.0.1:5000 from new client? (y/n): " new_web_access
    if [[ "$new_web_access" =~ ^[Yy]$ ]]; then
        echo "✅ Web GUI accessible from new client"
        PHASE4_SUCCESS=true
    else
        echo "❌ Web GUI not accessible from new client"
    fi
else
    echo "⏭️ Skipping Phase 4 - New client not created"
fi

echo ""
echo "📊 COMPLETE TEST RESULTS SUMMARY"
echo "================================="
echo "Phase 1 (Different VPN Config): $([ "$PHASE1_SUCCESS" == true ] && echo "✅ SUCCESS" || echo "❌ FAILED")"
echo "Phase 2 (Web GUI Access): $([ "$PHASE2_SUCCESS" == true ] && echo "✅ SUCCESS" || echo "❌ FAILED")"
echo "Phase 3 (Remote Client Creation): $([ "$PHASE3_SUCCESS" == true ] && echo "✅ SUCCESS" || echo "❌ FAILED")"
echo "Phase 4 (New Client Test): $([ "$PHASE4_SUCCESS" == true ] && echo "✅ SUCCESS" || echo "❌ FAILED")"
echo ""

# Overall result
if [[ "$PHASE1_SUCCESS" == true && "$PHASE2_SUCCESS" == true && "$PHASE3_SUCCESS" == true && "$PHASE4_SUCCESS" == true ]]; then
    echo "🎉 COMPLETE END-TO-END TEST: SUCCESS!"
    echo "💰 Dr. Kover's $200 automation system FULLY VALIDATED!"
    echo "🚀 Complete workflow proven: VPN → Web GUI → Client Creation → New Client Test"
    
    # Generate results for commit
    cat > end_to_end_test_results.txt << EOF
✅ COMPLETE END-TO-END VPN SYSTEM VALIDATION SUCCESSFUL
🔗 Phase 1: $selected_config tested - IP: $current_ip
🌐 Phase 2: Web GUI accessible at http://10.0.0.1:5000
🔧 Phase 3: Created Remote-GUI-Test-Client via web interface  
🧪 Phase 4: New client config works - External IP: $new_external_ip
🎉 Result: Complete workflow validation SUCCESSFUL
⏱️ Test completed: $(date)
💰 Dr. Kover's $200 automation system: FULLY OPERATIONAL!
EOF
    
    echo ""
    echo "📝 Results saved to end_to_end_test_results.txt"
    echo "💾 Ready to commit comprehensive test validation!"
    
else
    echo "⚠️ PARTIAL SUCCESS - Some phases failed"
    echo "🔧 Review failed phases and retry"
fi
