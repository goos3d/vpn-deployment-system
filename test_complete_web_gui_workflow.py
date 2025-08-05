#!/usr/bin/env python3
"""
Complete End-to-End VPN Web GUI Test
Tests the full workflow: Connect VPN → Access Web GUI → Create Peer → Test New Peer
"""

import subprocess
import requests
import json
import time
import os
from pathlib import Path
from datetime import datetime

class VPNWebGUITester:
    """Complete end-to-end VPN web GUI test system."""
    
    def __init__(self):
        self.server_ip = "184.105.7.112"
        self.server_port = 51820
        self.web_gui_port = 5000
        self.working_config = "MacBook-Test.conf"
        self.test_client_name = f"WebGUI-Test-{int(datetime.now().timestamp())}"
        
    def log(self, message, level="INFO"):
        """Log test progress."""
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{timestamp}] {level}: {message}")
    
    def run_command(self, command, description=""):
        """Run a shell command and return result."""
        if description:
            self.log(f"Running: {description}")
        
        try:
            result = subprocess.run(command, shell=True, capture_output=True, text=True)
            if result.returncode == 0:
                return True, result.stdout.strip()
            else:
                return False, result.stderr.strip()
        except Exception as e:
            return False, str(e)
    
    def check_vpn_connection(self):
        """Check if VPN is connected and working."""
        self.log("🔍 Checking VPN connection status...")
        
        # Check if WireGuard is running
        success, output = self.run_command("wg show", "Check WireGuard status")
        if not success:
            self.log("❌ WireGuard not active", "ERROR")
            return False
        
        # Check if we can reach VPN network
        success, output = self.run_command(f"ping -c 2 10.0.0.1", "Ping VPN gateway")
        if success:
            self.log("✅ VPN connection active and reachable")
            return True
        else:
            self.log("❌ Cannot reach VPN network", "ERROR")
            return False
    
    def connect_vpn(self):
        """Connect to VPN using working MacBook-Test config."""
        self.log("🔌 Connecting to VPN using MacBook-Test config...")
        
        if not os.path.exists(self.working_config):
            self.log(f"❌ Working config file not found: {self.working_config}", "ERROR")
            return False
        
        # Connect using wg-quick
        success, output = self.run_command(f"sudo wg-quick up {self.working_config}", 
                                         "Connect VPN")
        if success:
            self.log("✅ VPN connected successfully")
            time.sleep(3)  # Wait for connection to stabilize
            return self.check_vpn_connection()
        else:
            self.log(f"❌ VPN connection failed: {output}", "ERROR")
            return False
    
    def disconnect_vpn(self):
        """Disconnect VPN."""
        self.log("🔌 Disconnecting VPN...")
        success, output = self.run_command(f"sudo wg-quick down {self.working_config}", 
                                         "Disconnect VPN")
        if success:
            self.log("✅ VPN disconnected")
        else:
            self.log(f"⚠️  VPN disconnect warning: {output}", "WARN")
    
    def test_internet_access(self):
        """Test that internet access is preserved."""
        self.log("🌐 Testing internet access...")
        
        success, output = self.run_command("curl -s --max-time 5 https://httpbin.org/ip", 
                                         "Test internet connectivity")
        if success:
            try:
                data = json.loads(output)
                public_ip = data.get('origin', 'unknown')
                self.log(f"✅ Internet access working - Public IP: {public_ip}")
                return True
            except:
                self.log("✅ Internet access working (response received)")
                return True
        else:
            self.log("❌ Internet access blocked", "ERROR")
            return False
    
    def test_web_gui_access(self):
        """Test access to web GUI through VPN."""
        self.log("🌐 Testing web GUI access through VPN...")
        
        web_gui_url = f"http://10.0.0.1:{self.web_gui_port}"
        
        try:
            response = requests.get(web_gui_url, timeout=10)
            if response.status_code == 200:
                self.log("✅ Web GUI accessible through VPN")
                return True
            else:
                self.log(f"❌ Web GUI returned status: {response.status_code}", "ERROR")
                return False
        except requests.exceptions.RequestException as e:
            self.log(f"❌ Cannot access web GUI: {e}", "ERROR")
            return False
    
    def create_new_peer_via_gui(self):
        """Create a new peer using the web GUI API."""
        self.log(f"🚀 Creating new peer via web GUI: {self.test_client_name}")
        
        api_url = f"http://10.0.0.1:{self.web_gui_port}/api/client/create"
        
        try:
            response = requests.post(
                api_url,
                json={'name': self.test_client_name},
                timeout=15
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    self.log("✅ New peer created successfully via web GUI")
                    self.log(f"   Client name: {data['client']['name']}")
                    return True, data
                else:
                    self.log(f"❌ API returned error: {data.get('error')}", "ERROR")
                    return False, None
            else:
                self.log(f"❌ API request failed with status: {response.status_code}", "ERROR")
                return False, None
                
        except requests.exceptions.RequestException as e:
            self.log(f"❌ API request failed: {e}", "ERROR")
            return False, None
    
    def download_new_peer_config(self):
        """Download the new peer configuration."""
        self.log("📥 Downloading new peer configuration...")
        
        download_url = f"http://10.0.0.1:{self.web_gui_port}/download/{self.test_client_name}"
        
        try:
            response = requests.get(download_url, timeout=10)
            if response.status_code == 200:
                config_filename = f"{self.test_client_name}.conf"
                with open(config_filename, 'wb') as f:
                    f.write(response.content)
                self.log(f"✅ Configuration downloaded: {config_filename}")
                return True, config_filename
            else:
                self.log(f"❌ Download failed with status: {response.status_code}", "ERROR")
                return False, None
        except requests.exceptions.RequestException as e:
            self.log(f"❌ Download failed: {e}", "ERROR")
            return False, None
    
    def validate_new_config(self, config_file):
        """Validate that the new config uses the working pattern."""
        self.log("🔍 Validating new configuration pattern...")
        
        try:
            with open(config_file, 'r') as f:
                config_content = f.read()
            
            # Check for working pattern
            if "AllowedIPs = 10.0.0.0/24" in config_content:
                self.log("✅ Configuration uses working MacBook-Test pattern")
                self.log("   AllowedIPs = 10.0.0.0/24 (VPN network only)")
                return True
            elif "AllowedIPs = 0.0.0.0/0" in config_content:
                self.log("❌ Configuration uses problematic pattern", "ERROR")
                self.log("   AllowedIPs = 0.0.0.0/0 (would block internet)")
                return False
            else:
                self.log("⚠️  Unknown AllowedIPs pattern in config", "WARN")
                return False
                
        except Exception as e:
            self.log(f"❌ Cannot validate config: {e}", "ERROR")
            return False
    
    def run_complete_test(self):
        """Run the complete end-to-end test."""
        self.log("🎯 Starting Complete VPN Web GUI End-to-End Test")
        self.log("=" * 60)
        
        test_results = {
            'vpn_connect': False,
            'internet_access': False,
            'web_gui_access': False,
            'peer_creation': False,
            'config_download': False,
            'config_validation': False
        }
        
        try:
            # Step 1: Connect VPN
            if self.connect_vpn():
                test_results['vpn_connect'] = True
                
                # Step 2: Test internet access
                if self.test_internet_access():
                    test_results['internet_access'] = True
                
                # Step 3: Test web GUI access
                if self.test_web_gui_access():
                    test_results['web_gui_access'] = True
                    
                    # Step 4: Create new peer via GUI
                    success, peer_data = self.create_new_peer_via_gui()
                    if success:
                        test_results['peer_creation'] = True
                        
                        # Step 5: Download config
                        success, config_file = self.download_new_peer_config()
                        if success:
                            test_results['config_download'] = True
                            
                            # Step 6: Validate config pattern
                            if self.validate_new_config(config_file):
                                test_results['config_validation'] = True
            
        finally:
            # Always disconnect VPN
            self.disconnect_vpn()
        
        # Report results
        self.log("=" * 60)
        self.log("🏁 Test Results Summary:")
        self.log("=" * 60)
        
        all_passed = True
        for test_name, passed in test_results.items():
            status = "✅ PASS" if passed else "❌ FAIL"
            self.log(f"{test_name.replace('_', ' ').title()}: {status}")
            if not passed:
                all_passed = False
        
        self.log("=" * 60)
        if all_passed:
            self.log("🎉 ALL TESTS PASSED! Web GUI integration working perfectly!")
            self.log("✅ VPN provides network access AND preserves internet")
            self.log("✅ Web GUI accessible through VPN tunnel")
            self.log("✅ Peer creation working with correct pattern")
        else:
            self.log("❌ SOME TESTS FAILED - See details above", "ERROR")
        
        return all_passed

if __name__ == '__main__':
    tester = VPNWebGUITester()
    success = tester.run_complete_test()
    exit(0 if success else 1)
