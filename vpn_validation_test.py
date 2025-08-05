#!/usr/bin/env python3
"""
VPN System Validation Script - AI Handoff Testing
Created as part of AI handoff execution
"""

import sys
import subprocess
import socket
from pathlib import Path

def test_wireguard_service():
    """Test WireGuard service status"""
    print("🔍 Testing WireGuard Service Status...")
    try:
        result = subprocess.run(['powershell', 'Get-Service | Where-Object {$_.Name -like "*wireguard*"}'], 
                              capture_output=True, text=True)
        if "Running" in result.stdout:
            print("✅ WireGuard services are running")
            return True
        else:
            print("❌ WireGuard services not running")
            return False
    except Exception as e:
        print(f"❌ Error checking WireGuard service: {e}")
        return False

def test_port_listening():
    """Test if port 51820 is listening"""
    print("🔍 Testing Port 51820 Status...")
    try:
        result = subprocess.run(['netstat', '-an'], capture_output=True, text=True)
        if ":51820" in result.stdout:
            print("✅ Port 51820 is listening")
            return True
        else:
            print("❌ Port 51820 not listening")
            return False
    except Exception as e:
        print(f"❌ Error checking port status: {e}")
        return False

def test_vpn_interface():
    """Test VPN interface configuration"""
    print("🔍 Testing VPN Interface...")
    try:
        result = subprocess.run(['ipconfig', '/all'], capture_output=True, text=True)
        if "10.0.0.1" in result.stdout:
            print("✅ VPN interface configured with gateway IP 10.0.0.1")
            return True
        else:
            print("❌ VPN interface not configured")
            return False
    except Exception as e:
        print(f"❌ Error checking VPN interface: {e}")
        return False

def test_web_gui_dependencies():
    """Test if web GUI dependencies are installed"""
    print("🔍 Testing Web GUI Dependencies...")
    try:
        required_packages = ['flask', 'jinja2', 'qrcode', 'pillow']
        all_installed = True
        
        for package in required_packages:
            try:
                __import__(package)
                print(f"✅ {package} installed")
            except ImportError:
                print(f"❌ {package} not installed")
                all_installed = False
        
        return all_installed
    except Exception as e:
        print(f"❌ Error checking dependencies: {e}")
        return False

def test_config_pattern():
    """Test MacBook-Test pattern configuration"""
    print("🔍 Testing MacBook-Test Pattern Configuration...")
    try:
        web_app_file = Path("src/web/app.py")
        if web_app_file.exists():
            content = web_app_file.read_text()
            if "10.0.0.0/24" in content:
                print("✅ MacBook-Test pattern (10.0.0.0/24) configured in web app")
                return True
            else:
                print("❌ MacBook-Test pattern not found in web app")
                return False
        else:
            print("❌ Web app file not found")
            return False
    except Exception as e:
        print(f"❌ Error checking config pattern: {e}")
        return False

def main():
    """Run all validation tests"""
    print("🚀 VPN System Validation - AI Handoff Testing")
    print("=" * 50)
    
    tests = [
        ("WireGuard Service", test_wireguard_service),
        ("Port 51820 Listening", test_port_listening),
        ("VPN Interface", test_vpn_interface),
        ("Web GUI Dependencies", test_web_gui_dependencies),
        ("MacBook-Test Pattern", test_config_pattern)
    ]
    
    results = {}
    
    for test_name, test_func in tests:
        print(f"\n📋 {test_name}")
        results[test_name] = test_func()
    
    print("\n" + "=" * 50)
    print("📊 VALIDATION SUMMARY")
    print("=" * 50)
    
    passed = sum(results.values())
    total = len(results)
    
    for test_name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    print(f"\n🎯 Overall Result: {passed}/{total} tests passed")
    
    if passed == total:
        print("🏆 ALL TESTS PASSED - VPN system ready for deployment!")
        return 0
    else:
        print("⚠️  Some tests failed - review issues above")
        return 1

if __name__ == "__main__":
    sys.exit(main())
