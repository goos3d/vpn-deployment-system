# 🧪 Complete End-to-End VPN System Validation Test (PowerShell Edition)
# Tests the entire workflow: VPN → Web GUI → Client Creation → New Client Test

Write-Host "🧪 Dr. Kover's Complete VPN System Validation Test" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "💰 Testing `$200 Professional Automation System End-to-End" -ForegroundColor Yellow
Write-Host ""

# Phase tracking
$Phase1Success = $false
$Phase2Success = $false
$Phase3Success = $false
$Phase4Success = $false

Write-Host "📋 TEST OVERVIEW:" -ForegroundColor Green
Write-Host "Phase 1: Test different VPN config (prove placeholder fix worked)"
Write-Host "Phase 2: Access web GUI through VPN tunnel"
Write-Host "Phase 3: Create new client via web interface"
Write-Host "Phase 4: Test newly created client config"
Write-Host ""

# Configuration options for Phase 1
$ConfigOptions = @(
    @{Name = "Your-Laptop-Test.conf"; IP = "10.0.0.4"},
    @{Name = "Test-Client-1.conf"; IP = "10.0.0.2"},
    @{Name = "ThomasEastBayAV-Web_GUI_Peer_Add_Test.conf"; IP = "10.0.0.3"},
    @{Name = "Your-Laptop-REAL-CONFIG.conf"; IP = "10.0.0.5"}
)

Write-Host "🔧 PHASE 1: Test Different VPN Configuration" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "📋 Available test configurations:"
for ($i = 0; $i -lt $ConfigOptions.Count; $i++) {
    Write-Host "  $($i+1). $($ConfigOptions[$i].Name) (Expected IP: $($ConfigOptions[$i].IP))"
}
Write-Host ""

$selection = Read-Host "🔢 Select configuration to test (1-4)"

if ($selection -ge 1 -and $selection -le 4) {
    $selectedConfig = $ConfigOptions[$selection - 1]
    Write-Host "✅ Selected: $($selectedConfig.Name) (Expected IP: $($selectedConfig.IP))" -ForegroundColor Green
} else {
    Write-Host "❌ Invalid selection. Exiting." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🚨 CRITICAL: Disconnect your current MacBook-Test VPN connection first!" -ForegroundColor Yellow
Write-Host "We need to test a DIFFERENT config to validate the placeholder fix."
Read-Host "Press Enter after disconnecting current VPN"
Write-Host ""

Write-Host "📥 Verifying config file exists and has real keys..." -ForegroundColor Blue
$configPath = "..\VPN_Configs\$($selectedConfig.Name)"
if (Test-Path $configPath) {
    Write-Host "✅ Found: $configPath" -ForegroundColor Green
} else {
    Write-Host "❌ Config file not found: $configPath" -ForegroundColor Red
    exit 1
}

# Check for real keys
$configContent = Get-Content $configPath -Raw
if ($configContent -match "<GENERATED_PRIVATE_KEY" -or $configContent -match "<SERVER_PUBLIC_KEY>") {
    Write-Host "❌ Config still has placeholder keys! Fix not applied." -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ Config has real keys - placeholder fix confirmed" -ForegroundColor Green
}

Write-Host ""
Write-Host "🔧 Step 1: Import and connect with $($selectedConfig.Name)" -ForegroundColor Cyan
Write-Host "1. Import $configPath into your WireGuard client"
Write-Host "2. Connect to the VPN"
Write-Host "3. Verify you get IP: $($selectedConfig.IP)"
Write-Host ""

Read-Host "Press Enter after connecting to VPN with new config"

Write-Host ""
Write-Host "🧪 Phase 1 Validation Tests:" -ForegroundColor Blue

# Test 1: VPN Server Connectivity
Write-Host "Test 1: VPN Server Connectivity"
try {
    $pingResult = Test-Connection -ComputerName "10.0.0.1" -Count 3 -Quiet
    if ($pingResult) {
        Write-Host "✅ Can ping VPN server (10.0.0.1)" -ForegroundColor Green
    } else {
        Write-Host "❌ Cannot ping VPN server (10.0.0.1)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error pinging VPN server: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: IP Assignment Check
Write-Host "Test 2: IP Assignment"
try {
    $vpnInterface = Get-NetIPAddress | Where-Object { $_.IPAddress -like "10.0.0.*" -and $_.AddressFamily -eq "IPv4" }
    if ($vpnInterface) {
        $currentIP = $vpnInterface.IPAddress
        Write-Host "Current VPN IP: $currentIP (Expected: $($selectedConfig.IP))"
        if ($currentIP -eq $selectedConfig.IP) {
            Write-Host "✅ Correct IP assignment" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Different IP than expected" -ForegroundColor Yellow
        }
    } else {
        $currentIP = Read-Host "Enter your current VPN IP (10.0.0.x)"
    }
} catch {
    $currentIP = Read-Host "Enter your current VPN IP (10.0.0.x)"
}

# Test 3: External IP Check
Write-Host "Test 3: External IP via VPN"
try {
    $externalIP = (Invoke-RestMethod -Uri "http://ifconfig.me" -TimeoutSec 10).Trim()
    if ($externalIP -eq "184.105.7.112") {
        Write-Host "✅ Correct external IP via VPN: $externalIP" -ForegroundColor Green
        $Phase1Success = $true
    } else {
        Write-Host "⚠️ External IP: $externalIP (Expected: 184.105.7.112)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Unable to determine external IP" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🌐 PHASE 2: Web GUI Access Test" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host "🎯 Goal: Access Dr. Kover's web dashboard through VPN tunnel"
Write-Host ""

# Test web GUI access
Write-Host "📱 Testing web GUI access..." -ForegroundColor Blue
Write-Host "1. Open browser and navigate to: http://10.0.0.1:5000"
Write-Host "2. OR try: http://184.105.7.112:5000"
Write-Host ""
Write-Host "Expected to see:"
Write-Host "- 🛡️ Dr. Kover's Professional VPN Management System"
Write-Host "- Current client list"
Write-Host "- Add Client form"
Write-Host "- Server status showing 184.105.7.112:51820"
Write-Host ""

$webAccess = Read-Host "Can you access the web GUI? (y/n)"
if ($webAccess -match "^[Yy]") {
    Write-Host "✅ Web GUI accessible through VPN tunnel" -ForegroundColor Green
    $Phase2Success = $true
} else {
    Write-Host "❌ Web GUI not accessible" -ForegroundColor Red
    Write-Host "Troubleshooting:"
    Write-Host "- Ensure VPN is connected"
    Write-Host "- Try both http://10.0.0.1:5000 and http://184.105.7.112:5000"
    Write-Host "- Check if web service is running on server"
}

Write-Host ""
Write-Host "🔧 PHASE 3: Remote Client Creation Test" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "🎯 Goal: Create new VPN client via web interface while connected via VPN"
Write-Host ""

if ($Phase2Success) {
    Write-Host "📝 Instructions for creating new client:" -ForegroundColor Blue
    Write-Host "1. In the web interface, find the 'Add New VPN Client' section"
    Write-Host "2. Enter client name: 'Remote-GUI-Test-Client'"
    Write-Host "3. Select device type: 'desktop' or 'mobile'"
    Write-Host "4. Click 'Add Client with Real Keys'"
    Write-Host ""
    Write-Host "Expected results:"
    Write-Host "- Success message appears"
    Write-Host "- New client appears in client list"
    Write-Host "- Download button available for new config"
    Write-Host ""
    
    $clientCreated = Read-Host "Did you successfully create the new client? (y/n)"
    if ($clientCreated -match "^[Yy]") {
        Write-Host "✅ New client created via web GUI" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "📥 Download the new config file:" -ForegroundColor Blue
        Write-Host "1. Click the 'Download' button for Remote-GUI-Test-Client"
        Write-Host "2. Save the .conf file"
        Write-Host "3. Verify it contains real keys (no placeholders)"
        Write-Host ""
        
        $configDownloaded = Read-Host "Did you download the new config file? (y/n)"
        if ($configDownloaded -match "^[Yy]") {
            Write-Host "✅ New config file downloaded" -ForegroundColor Green
            $Phase3Success = $true
        } else {
            Write-Host "❌ Config file not downloaded" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Client creation failed" -ForegroundColor Red
    }
} else {
    Write-Host "⏭️ Skipping Phase 3 - Web GUI not accessible" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🧪 PHASE 4: New Client Configuration Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎯 Goal: Test the newly created client config"
Write-Host ""

if ($Phase3Success) {
    Write-Host "🔄 Testing new client config:" -ForegroundColor Blue
    Write-Host "1. Disconnect current VPN connection"
    Write-Host "2. Import Remote-GUI-Test-Client.conf into WireGuard"
    Write-Host "3. Connect with the new configuration"
    Write-Host ""
    
    Read-Host "Press Enter after connecting with new client config"
    
    Write-Host ""
    Write-Host "🧪 New Client Validation Tests:" -ForegroundColor Blue
    
    # Test new client connectivity
    Write-Host "Test 1: VPN Server Connectivity (New Client)"
    try {
        $newClientPing = Test-Connection -ComputerName "10.0.0.1" -Count 3 -Quiet
        if ($newClientPing) {
            Write-Host "✅ New client can ping VPN server (10.0.0.1)" -ForegroundColor Green
        } else {
            Write-Host "❌ New client cannot ping VPN server" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Error pinging VPN server with new client" -ForegroundColor Red
    }
    
    # Test new client external IP
    Write-Host "Test 2: External IP (New Client)"
    try {
        $newExternalIP = (Invoke-RestMethod -Uri "http://ifconfig.me" -TimeoutSec 10).Trim()
        if ($newExternalIP -eq "184.105.7.112") {
            Write-Host "✅ New client correct external IP: $newExternalIP" -ForegroundColor Green
        } else {
            Write-Host "⚠️ New client external IP: $newExternalIP" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️ Unable to determine new client external IP" -ForegroundColor Yellow
    }
    
    # Test accessing web GUI from new client
    Write-Host "Test 3: Web GUI Access (New Client)"
    $newWebAccess = Read-Host "Can you access http://10.0.0.1:5000 from new client? (y/n)"
    if ($newWebAccess -match "^[Yy]") {
        Write-Host "✅ Web GUI accessible from new client" -ForegroundColor Green
        $Phase4Success = $true
    } else {
        Write-Host "❌ Web GUI not accessible from new client" -ForegroundColor Red
    }
} else {
    Write-Host "⏭️ Skipping Phase 4 - New client not created" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📊 COMPLETE TEST RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Phase 1 (Different VPN Config): $(if ($Phase1Success) { "✅ SUCCESS" } else { "❌ FAILED" })" -ForegroundColor $(if ($Phase1Success) { "Green" } else { "Red" })
Write-Host "Phase 2 (Web GUI Access): $(if ($Phase2Success) { "✅ SUCCESS" } else { "❌ FAILED" })" -ForegroundColor $(if ($Phase2Success) { "Green" } else { "Red" })
Write-Host "Phase 3 (Remote Client Creation): $(if ($Phase3Success) { "✅ SUCCESS" } else { "❌ FAILED" })" -ForegroundColor $(if ($Phase3Success) { "Green" } else { "Red" })
Write-Host "Phase 4 (New Client Test): $(if ($Phase4Success) { "✅ SUCCESS" } else { "❌ FAILED" })" -ForegroundColor $(if ($Phase4Success) { "Green" } else { "Red" })
Write-Host ""

# Overall result
if ($Phase1Success -and $Phase2Success -and $Phase3Success -and $Phase4Success) {
    Write-Host "🎉 COMPLETE END-TO-END TEST: SUCCESS!" -ForegroundColor Green
    Write-Host "💰 Dr. Kover's `$200 automation system FULLY VALIDATED!" -ForegroundColor Yellow
    Write-Host "🚀 Complete workflow proven: VPN → Web GUI → Client Creation → New Client Test" -ForegroundColor Green
    
    # Generate results for commit
    $results = @"
✅ COMPLETE END-TO-END VPN SYSTEM VALIDATION SUCCESSFUL
🔗 Phase 1: $($selectedConfig.Name) tested - IP: $currentIP
🌐 Phase 2: Web GUI accessible at http://10.0.0.1:5000
🔧 Phase 3: Created Remote-GUI-Test-Client via web interface  
🧪 Phase 4: New client config works - External IP: $newExternalIP
🎉 Result: Complete workflow validation SUCCESSFUL
⏱️ Test completed: $(Get-Date)
💰 Dr. Kover's `$200 automation system: FULLY OPERATIONAL!
"@
    
    $results | Out-File -FilePath "end_to_end_test_results.txt" -Encoding UTF8
    
    Write-Host ""
    Write-Host "📝 Results saved to end_to_end_test_results.txt" -ForegroundColor Blue
    Write-Host "💾 Ready to commit comprehensive test validation!" -ForegroundColor Blue
    
} else {
    Write-Host "⚠️ PARTIAL SUCCESS - Some phases failed" -ForegroundColor Yellow
    Write-Host "🔧 Review failed phases and retry" -ForegroundColor Yellow
}
