"""
VPN Testing and Debugging Tools

Comprehensive testing utilities for WireGuard VPN deployment.
"""

import subprocess
import socket
import time
import requests
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import psutil
import json


class VPNTester:
    """Comprehensive VPN testing and debugging tools."""
    
    def __init__(self, interface: str = "wg0", server_ip: str = "10.0.0.1"):
        self.interface = interface
        self.server_ip = server_ip
        self.results = {}
    
    def run_all_tests(self) -> Dict:
        """Run comprehensive VPN testing suite."""
        print("🧪 Running VPN Testing Suite")
        print("=" * 30)
        
        tests = [
            "test_wireguard_installation",
            "test_wireguard_service",
            "test_interface_status",
            "test_firewall_config", 
            "test_server_connectivity",
            "test_dns_resolution",
            "test_internet_access",
            "test_peer_connections",
            "test_traffic_routing"
        ]
        
        for test_name in tests:
            print(f"\n📋 Running {test_name.replace('_', ' ').title()}...")
            try:
                result = getattr(self, test_name)()
                self.results[test_name] = result
                status = "✅ PASS" if result.get("success") else "❌ FAIL"
                print(f"   {status}: {result.get('message', 'No message')}")
            except Exception as e:
                self.results[test_name] = {"success": False, "error": str(e)}
                print(f"   ❌ ERROR: {str(e)}")
        
        return self.results
    
    def test_wireguard_installation(self) -> Dict:
        """Test if WireGuard tools are installed and accessible."""
        try:
            result = subprocess.run(["wg", "--version"], 
                                  capture_output=True, text=True, check=True)
            version = result.stdout.strip().split('\n')[0]
            return {
                "success": True,
                "message": f"WireGuard installed: {version}",
                "version": version
            }
        except (subprocess.CalledProcessError, FileNotFoundError):
            return {
                "success": False,
                "message": "WireGuard tools not found or not working",
                "suggestion": "Install WireGuard: apt install wireguard"
            }
    
    def test_wireguard_service(self) -> Dict:
        """Test WireGuard service status."""
        try:
            result = subprocess.run(
                ["systemctl", "is-active", f"wg-quick@{self.interface}"],
                capture_output=True, text=True
            )
            
            if result.returncode == 0:
                return {
                    "success": True,
                    "message": f"WireGuard service {self.interface} is active",
                    "status": "active"
                }
            else:
                # Get detailed status
                status_result = subprocess.run(
                    ["systemctl", "status", f"wg-quick@{self.interface}"],
                    capture_output=True, text=True
                )
                
                return {
                    "success": False,
                    "message": f"WireGuard service {self.interface} is not active",
                    "status": "inactive",
                    "details": status_result.stdout,
                    "suggestion": f"Start service: systemctl start wg-quick@{self.interface}"
                }
        except Exception as e:
            return {"success": False, "message": f"Cannot check service status: {e}"}
    
    def test_interface_status(self) -> Dict:
        """Test WireGuard interface status and configuration."""
        try:
            result = subprocess.run(["wg", "show", self.interface], 
                                  capture_output=True, text=True, check=True)
            
            lines = result.stdout.strip().split('\n')
            interface_info = {}
            peer_count = 0
            
            for line in lines:
                if line.startswith('interface:'):
                    interface_info['name'] = line.split(': ')[1]
                elif line.startswith('  public key:'):
                    interface_info['public_key'] = line.split(': ')[1]
                elif line.startswith('  private key:'):
                    interface_info['has_private_key'] = True
                elif line.startswith('  listening port:'):
                    interface_info['port'] = line.split(': ')[1]
                elif line.startswith('peer:'):
                    peer_count += 1
            
            return {
                "success": True,
                "message": f"Interface {self.interface} is up with {peer_count} peers",
                "interface_info": interface_info,
                "peer_count": peer_count
            }
            
        except subprocess.CalledProcessError:
            return {
                "success": False,
                "message": f"Interface {self.interface} is not up or configured",
                "suggestion": f"Check interface: wg show {self.interface}"
            }
    
    def test_firewall_config(self) -> Dict:
        """Test firewall configuration for VPN traffic."""
        try:
            # Test UFW status
            ufw_result = subprocess.run(["ufw", "status"], 
                                      capture_output=True, text=True)
            
            firewall_info = {"ufw_active": False, "wireguard_allowed": False}
            
            if "Status: active" in ufw_result.stdout:
                firewall_info["ufw_active"] = True
                
                # Check if WireGuard port is allowed
                if "51820" in ufw_result.stdout or "wireguard" in ufw_result.stdout.lower():
                    firewall_info["wireguard_allowed"] = True
            
            # Test IP forwarding
            with open('/proc/sys/net/ipv4/ip_forward', 'r') as f:
                ip_forward = f.read().strip() == '1'
            
            firewall_info["ip_forwarding"] = ip_forward
            
            success = firewall_info["ip_forwarding"]
            if firewall_info["ufw_active"]:
                success = success and firewall_info["wireguard_allowed"]
            
            return {
                "success": success,
                "message": "Firewall configuration checked",
                "firewall_info": firewall_info,
                "suggestion": "Enable IP forwarding and allow WireGuard port" if not success else None
            }
            
        except Exception as e:
            return {"success": False, "message": f"Cannot check firewall: {e}"}
    
    def test_server_connectivity(self) -> Dict:
        """Test connectivity to VPN server."""
        try:
            # Test ping to server IP
            ping_result = subprocess.run(
                ["ping", "-c", "3", "-W", "2", self.server_ip],
                capture_output=True, text=True
            )
            
            ping_success = ping_result.returncode == 0
            
            # Extract ping statistics
            ping_stats = {}
            if ping_success:
                lines = ping_result.stdout.split('\n')
                for line in lines:
                    if 'packets transmitted' in line:
                        parts = line.split(', ')
                        ping_stats['transmitted'] = int(parts[0].split()[0])
                        ping_stats['received'] = int(parts[1].split()[0])
                        ping_stats['loss'] = parts[2].split()[0]
            
            return {
                "success": ping_success,
                "message": f"Server {self.server_ip} {'reachable' if ping_success else 'not reachable'}",
                "ping_stats": ping_stats,
                "output": ping_result.stdout if ping_success else ping_result.stderr
            }
            
        except Exception as e:
            return {"success": False, "message": f"Cannot test server connectivity: {e}"}
    
    def test_dns_resolution(self) -> Dict:
        """Test DNS resolution through VPN."""
        test_domains = ["google.com", "cloudflare.com", "1.1.1.1"]
        results = {}
        
        for domain in test_domains:
            try:
                start_time = time.time()
                socket.gethostbyname(domain)
                resolve_time = (time.time() - start_time) * 1000
                
                results[domain] = {
                    "success": True,
                    "resolve_time_ms": round(resolve_time, 2)
                }
            except socket.gaierror as e:
                results[domain] = {
                    "success": False,
                    "error": str(e)
                }
        
        success_count = sum(1 for r in results.values() if r["success"])
        overall_success = success_count > 0
        
        return {
            "success": overall_success,
            "message": f"DNS resolution: {success_count}/{len(test_domains)} domains resolved",
            "results": results
        }
    
    def test_internet_access(self) -> Dict:
        """Test internet access through VPN."""
        test_urls = [
            "http://ifconfig.me",
            "http://ipinfo.io/ip", 
            "http://icanhazip.com"
        ]
        
        results = {}
        public_ips = set()
        
        for url in test_urls:
            try:
                response = requests.get(url, timeout=10)
                if response.status_code == 200:
                    ip = response.text.strip()
                    public_ips.add(ip)
                    results[url] = {
                        "success": True,
                        "public_ip": ip,
                        "response_time_ms": round(response.elapsed.total_seconds() * 1000, 2)
                    }
                else:
                    results[url] = {
                        "success": False,
                        "status_code": response.status_code
                    }
            except Exception as e:
                results[url] = {
                    "success": False,
                    "error": str(e)
                }
        
        success_count = sum(1 for r in results.values() if r["success"])
        overall_success = success_count > 0
        
        return {
            "success": overall_success,
            "message": f"Internet access: {success_count}/{len(test_urls)} services reachable",
            "results": results,
            "detected_public_ips": list(public_ips)
        }
    
    def test_peer_connections(self) -> Dict:
        """Test peer connection status and statistics."""
        try:
            result = subprocess.run(["wg", "show", self.interface, "dump"], 
                                  capture_output=True, text=True, check=True)
            
            lines = result.stdout.strip().split('\n')
            peers = []
            
            for line in lines[1:]:  # Skip header
                if line.strip():
                    parts = line.split('\t')
                    if len(parts) >= 4:
                        peer = {
                            "public_key": parts[0],
                            "preshared_key": parts[1] if parts[1] != "(none)" else None,
                            "endpoint": parts[2] if parts[2] != "(none)" else None,
                            "allowed_ips": parts[3],
                            "latest_handshake": parts[4] if len(parts) > 4 else None,
                            "transfer_rx": parts[5] if len(parts) > 5 else None,
                            "transfer_tx": parts[6] if len(parts) > 6 else None
                        }
                        peers.append(peer)
            
            active_peers = len([p for p in peers if p["endpoint"]])
            
            return {
                "success": True,
                "message": f"Found {len(peers)} peers, {active_peers} active",
                "total_peers": len(peers),
                "active_peers": active_peers,
                "peers": peers
            }
            
        except subprocess.CalledProcessError:
            return {
                "success": False,
                "message": "Cannot retrieve peer information"
            }
    
    def test_traffic_routing(self) -> Dict:
        """Test traffic routing through VPN."""
        try:
            # Test route table
            route_result = subprocess.run(["ip", "route"], 
                                        capture_output=True, text=True, check=True)
            
            routes = route_result.stdout.split('\n')
            vpn_routes = [route for route in routes if self.interface in route]
            
            # Test traceroute to a common destination
            traceroute_result = subprocess.run(
                ["traceroute", "-n", "-m", "5", "8.8.8.8"],
                capture_output=True, text=True, timeout=30
            )
            
            return {
                "success": len(vpn_routes) > 0,
                "message": f"Found {len(vpn_routes)} VPN routes",
                "vpn_routes": vpn_routes,
                "traceroute": traceroute_result.stdout if traceroute_result.returncode == 0 else None
            }
            
        except Exception as e:
            return {"success": False, "message": f"Cannot test traffic routing: {e}"}
    
    def generate_report(self, output_file: Optional[str] = None) -> str:
        """Generate comprehensive test report."""
        if not self.results:
            self.run_all_tests()
        
        report = []
        report.append("# VPN Testing Report")
        report.append(f"Generated on: {time.strftime('%Y-%m-%d %H:%M:%S')}")
        report.append(f"Interface: {self.interface}")
        report.append(f"Server IP: {self.server_ip}")
        report.append("")
        
        # Summary
        total_tests = len(self.results)
        passed_tests = sum(1 for r in self.results.values() if r.get("success"))
        
        report.append(f"## Summary")
        report.append(f"- Total Tests: {total_tests}")
        report.append(f"- Passed: {passed_tests}")
        report.append(f"- Failed: {total_tests - passed_tests}")
        report.append(f"- Success Rate: {(passed_tests/total_tests)*100:.1f}%")
        report.append("")
        
        # Detailed results
        report.append("## Detailed Results")
        for test_name, result in self.results.items():
            status = "✅ PASS" if result.get("success") else "❌ FAIL"
            report.append(f"### {test_name.replace('_', ' ').title()}")
            report.append(f"**Status:** {status}")
            report.append(f"**Message:** {result.get('message', 'No message')}")
            
            if result.get("suggestion"):
                report.append(f"**Suggestion:** {result.get('suggestion')}")
            
            if result.get("error"):
                report.append(f"**Error:** {result.get('error')}")
            
            report.append("")
        
        report_text = "\n".join(report)
        
        if output_file:
            Path(output_file).write_text(report_text)
            print(f"📄 Report saved to: {output_file}")
        
        return report_text


def main():
    """Main entry point for VPN testing."""
    import argparse
    
    parser = argparse.ArgumentParser(description="VPN Testing and Debugging Tools")
    parser.add_argument("--interface", "-i", default="wg0", help="WireGuard interface name")
    parser.add_argument("--server-ip", "-s", default="10.0.0.1", help="VPN server IP")
    parser.add_argument("--output", "-o", help="Output file for report")
    parser.add_argument("--test", help="Run specific test only")
    
    args = parser.parse_args()
    
    tester = VPNTester(interface=args.interface, server_ip=args.server_ip)
    
    if args.test:
        # Run specific test
        if hasattr(tester, args.test):
            result = getattr(tester, args.test)()
            print(json.dumps(result, indent=2))
        else:
            print(f"❌ Test '{args.test}' not found")
    else:
        # Run all tests
        results = tester.run_all_tests()
        
        # Generate report
        if args.output:
            tester.generate_report(args.output)
        else:
            print("\n" + "="*50)
            print("📊 FINAL SUMMARY")
            print("="*50)
            
            total = len(results)
            passed = sum(1 for r in results.values() if r.get("success"))
            
            print(f"Total Tests: {total}")
            print(f"✅ Passed: {passed}")
            print(f"❌ Failed: {total - passed}")
            print(f"Success Rate: {(passed/total)*100:.1f}%")


if __name__ == "__main__":
    main()
