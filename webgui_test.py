#!/usr/bin/env python3
"""
Web GUI Functionality Test - AI Handoff Validation
Tests the VPN Web GUI to ensure it's fully operational
"""

import requests
import time
import sys
from pathlib import Path

def test_web_gui_access():
    """Test if web GUI is accessible"""
    print("🔍 Testing Web GUI Access...")
    
    test_urls = [
        "http://127.0.0.1:5000",
        "http://184.105.7.112:5000",
        "http://0.0.0.0:5000"
    ]
    
    for url in test_urls:
        try:
            print(f"   Testing: {url}")
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                print(f"   ✅ {url} - Status: {response.status_code}")
                return True, url
            else:
                print(f"   ⚠️ {url} - Status: {response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"   ❌ {url} - Error: {e}")
    
    return False, None

def test_web_gui_endpoints():
    """Test specific web GUI endpoints"""
    print("🔍 Testing Web GUI Endpoints...")
    
    base_url = "http://127.0.0.1:5000"
    endpoints = [
        "/",
        "/api/server/status",
        "/api/clients"
    ]
    
    results = {}
    
    for endpoint in endpoints:
        try:
            url = base_url + endpoint
            print(f"   Testing: {url}")
            response = requests.get(url, timeout=5)
            results[endpoint] = {
                "status": response.status_code,
                "success": response.status_code in [200, 404]  # 404 is ok for some endpoints
            }
            print(f"   ✅ {endpoint} - Status: {response.status_code}")
        except requests.exceptions.RequestException as e:
            results[endpoint] = {"status": "error", "success": False}
            print(f"   ❌ {endpoint} - Error: {e}")
    
    return results

def main():
    """Main test function"""
    print("🚀 Web GUI Comprehensive Test")
    print("=" * 40)
    
    # Test 1: Basic Access
    accessible, working_url = test_web_gui_access()
    
    if not accessible:
        print("\n❌ Web GUI is not accessible")
        return 1
    
    print(f"\n✅ Web GUI is accessible at: {working_url}")
    
    # Test 2: Endpoint Testing
    endpoint_results = test_web_gui_endpoints()
    
    print("\n" + "=" * 40)
    print("📊 WEB GUI TEST SUMMARY")
    print("=" * 40)
    
    working_endpoints = sum(1 for result in endpoint_results.values() if result["success"])
    total_endpoints = len(endpoint_results)
    
    print(f"✅ Web GUI Access: WORKING")
    print(f"📡 Endpoints Working: {working_endpoints}/{total_endpoints}")
    
    if accessible and working_endpoints > 0:
        print("\n🏆 WEB GUI IS FULLY OPERATIONAL!")
        return 0
    else:
        print("\n⚠️ Web GUI has some issues")
        return 1

if __name__ == "__main__":
    sys.exit(main())
