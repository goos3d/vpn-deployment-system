"""
Screenshot Intelligence System - Pattern Matcher
Alpha version for extracting VPN-specific data patterns
"""

import re
from typing import Dict, List, Optional
from datetime import datetime


class VPNPatternMatcher:
    """Extracts VPN-specific data from OCR text"""
    
    def __init__(self):
        self.patterns = {
            # WireGuard specific patterns
            'wireguard_status': {
                'interface': r'Interface:\s*(\S+)',
                'status': r'Status:\s*([A-Za-z]+)',
                'public_key': r'Public key:\s*([A-Za-z0-9+/=]+)',
                'addresses': r'Addresses:\s*([\d\./]+)',
                'listen_port': r'Listen port:\s*(\d+)',
                'dns_servers': r'DNS servers:\s*([\d\., ]+)',
                'peer_public_key': r'Peer:\s*([A-Za-z0-9+/=]+)',
                'endpoint': r'Endpoint:\s*([\d\.]+:\d+)',
                'allowed_ips': r'Allowed IPs:\s*([\d\./,\s]+)',
                'persistent_keepalive': r'Persistent keepalive:\s*(.+)',
                'data_sent': r'Data sent:\s*([\d\.]+ \w+)',
                'data_received': r'Data received:\s*([\d\.]+ \w+)',
                'on_demand': r'On-Demand:\s*(\w+)'
            },
            
            # Network testing patterns  
            'ping_results': {
                'target': r'PING\s+([\w\.-]+)',
                'target_ip': r'PING\s+[\w\.-]+\s+\(([\d\.]+)\)',
                'packets_sent': r'(\d+)\s+packets transmitted',
                'packets_received': r'(\d+)\s+received',
                'packet_loss': r'(\d+)%\s+packet loss',
                'min_time': r'min/avg/max/stddev\s*=\s*([\d\.]+)',
                'avg_time': r'min/avg/max/stddev\s*=\s*[\d\.]+/([\d\.]+)',
                'max_time': r'min/avg/max/stddev\s*=\s*[\d\.]+/[\d\.]+/([\d\.]+)'
            },
            
            # System status patterns
            'system_status': {
                'hostname': r'hostname[:=]\s*(\S+)',
                'os_version': r'(Ubuntu|CentOS|Windows|macOS)[\s\d\.]*',
                'memory_usage': r'Memory.*?(\d+)%',
                'cpu_usage': r'CPU.*?(\d+)%',
                'uptime': r'up\s+([\d\w\s,]+)',
                'service_status': r'(Active|inactive|failed):\s*(.+)',
            },
            
            # General network patterns
            'network_info': {
                'ipv4_addresses': r'\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b',
                'ports': r':(\d{1,5})\b',
                'mac_addresses': r'([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})',
                'subnet_masks': r'/(\d{1,2})\b'
            }
        }
    
    def detect_screenshot_type(self, text: str) -> str:
        """Detect what type of screenshot this is"""
        text_lower = text.lower()
        
        if 'wireguard' in text_lower or 'interface:' in text_lower:
            return 'wireguard_status'
        elif 'ping' in text_lower and 'packets transmitted' in text_lower:
            return 'ping_results'
        elif 'systemctl' in text_lower or 'service' in text_lower:
            return 'system_status'
        else:
            return 'general_network'
    
    def extract_patterns(self, text: str, screenshot_type: str = None) -> Dict:
        """Extract structured data based on screenshot type"""
        if not screenshot_type:
            screenshot_type = self.detect_screenshot_type(text)
        
        extracted_data = {
            'screenshot_type': screenshot_type,
            'timestamp': datetime.now().isoformat(),
            'raw_text': text,
            'extracted_fields': {}
        }
        
        # Get patterns for this screenshot type
        if screenshot_type in self.patterns:
            pattern_set = self.patterns[screenshot_type]
            
            for field_name, pattern in pattern_set.items():
                matches = re.findall(pattern, text, re.IGNORECASE | re.MULTILINE)
                if matches:
                    extracted_data['extracted_fields'][field_name] = matches[0] if len(matches) == 1 else matches
        
        # Always extract general network info
        network_patterns = self.patterns['network_info']
        for field_name, pattern in network_patterns.items():
            matches = re.findall(pattern, text)
            if matches:
                extracted_data['extracted_fields'][field_name] = list(set(matches))  # Remove duplicates
        
        return extracted_data
    
    def format_for_knowledge_base(self, extracted_data: Dict, image_path: str) -> str:
        """Format extracted data for markdown knowledge base"""
        screenshot_type = extracted_data['screenshot_type']
        fields = extracted_data['extracted_fields']
        timestamp = datetime.now().strftime('%H:%M:%S')
        
        # Create markdown table row
        if screenshot_type == 'wireguard_status':
            status = fields.get('status', 'Unknown')
            endpoint = fields.get('endpoint', 'N/A')
            data_sent = fields.get('data_sent', 'N/A')
            
            return f"| {timestamp} | WireGuard: {status} | [{image_path}]({image_path}) | Endpoint: {endpoint}, Data: {data_sent} |\n"
            
        elif screenshot_type == 'ping_results':
            target = fields.get('target', 'Unknown')
            loss = fields.get('packet_loss', 'N/A')
            avg_time = fields.get('avg_time', 'N/A')
            
            return f"| {timestamp} | Ping {target}: {loss}% loss, {avg_time}ms avg | [{image_path}]({image_path}) | Network test |\n"
        
        else:
            # Generic format
            key_data = ', '.join([f"{k}: {v}" for k, v in list(fields.items())[:3]])  # First 3 fields
            return f"| {timestamp} | {screenshot_type} | [{image_path}]({image_path}) | {key_data} |\n"


def test_patterns():
    """Test pattern matching with sample data"""
    matcher = VPNPatternMatcher()
    
    # Test WireGuard status text (from your screenshot)
    sample_wireguard = """
    Interface: MacBook-Test
    Status: Active
    Public key: kbHYg+iaeOsOVA0jtMPQkLv/QkQapVviNMpWoNRb7mM=
    Addresses: 10.0.0.2/32
    Listen port: 62894
    DNS servers: 1.1.1.1, 8.8.8.8
    
    Peer: ux8bIFUDZgfOQ4XTnTA8bL45QFtDfwRgC9fTcJwLrxo=
    Endpoint: 184.105.7.112:51820
    Allowed IPs: 10.0.0.0/24
    Persistent keepalive: every 25 seconds
    Data sent: 1.01 KiB
    """
    
    print("🧪 Testing VPN Pattern Matcher")
    print("===============================")
    
    result = matcher.extract_patterns(sample_wireguard)
    print(f"Screenshot type: {result['screenshot_type']}")
    print(f"Extracted fields: {len(result['extracted_fields'])}")
    
    for field, value in result['extracted_fields'].items():
        print(f"  {field}: {value}")
    
    print("\n📋 Knowledge base format:")
    kb_entry = matcher.format_for_knowledge_base(result, "test_screenshot.png")
    print(kb_entry)


if __name__ == "__main__":
    test_patterns()
