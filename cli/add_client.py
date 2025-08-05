#!/usr/bin/env python3
"""
add_client.py - Minimal VPN Client Generator
 
Usage: python cli/add_client.py <client_name>
Output: Creates client folder with .conf file and QR code

This script wraps the proven working core modules to generate
clean, UTF-8 encoded WireGuard client configurations.
"""

import sys
import os
from pathlib import Path
import argparse

# Add src to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from src.core.client_config import ClientConfigGenerator
from src.core.keys import WireGuardKeyManager


class SimpleClientGenerator:
    """Minimal client generation with no bloat."""
    
    def __init__(self):
        # Server configuration (hardcoded - working values)
        self.server_public_key = 'DEQ0g/nJrVXhS0jm5CHVHJy9Z5pJvCpn1RODqDQ5Jn4='
        self.server_endpoint = '184.105.7.112'
        self.server_port = 51820
        self.network_base = '10.0.0.0/24'
        
        # Initialize core components
        self.key_manager = WireGuardKeyManager()
        self.config_gen = ClientConfigGenerator(
            server_public_key=self.server_public_key,
            server_endpoint=self.server_endpoint,
            server_port=self.server_port,
            network_base=self.network_base
        )
        
        # Output directory
        self.clients_dir = Path('clients')
        self.clients_dir.mkdir(exist_ok=True)
    
    def get_next_ip(self) -> str:
        """Get next available IP address."""
        # Simple approach: check existing client folders and increment
        existing_ips = set()
        
        if self.clients_dir.exists():
            for client_folder in self.clients_dir.iterdir():
                if client_folder.is_dir():
                    conf_file = client_folder / f"{client_folder.name}.conf"
                    if conf_file.exists():
                        # Extract IP from existing config
                        content = conf_file.read_text(encoding='utf-8')
                        for line in content.split('\n'):
                            if line.startswith('Address = '):
                                ip = line.split(' = ')[1].split('/')[0]
                                existing_ips.add(ip)
        
        # Start from 10.0.0.2 (server typically uses .1)
        for i in range(2, 255):
            ip = f"10.0.0.{i}"
            if ip not in existing_ips:
                return ip
        
        raise ValueError("No available IP addresses")
    
    def add_client(self, client_name: str) -> dict:
        """
        Add a single VPN client.
        
        Args:
            client_name: Name for the client
            
        Returns:
            Dictionary with client information and file paths
        """
        print(f"Generating VPN config for client: {client_name}")
        
        # Generate keys
        print("  Generating WireGuard keys...")
        private_key, public_key = self.key_manager.generate_key_pair()
        
        # Get IP address
        client_ip = self.get_next_ip()
        print(f"  Assigned IP: {client_ip}")
        
        # Create client directory
        client_dir = self.clients_dir / client_name
        client_dir.mkdir(exist_ok=True)
        
        # Generate configuration
        print("  Generating configuration...")
        config = self.config_gen.generate_config(
            client_name=client_name,
            client_private_key=private_key,
            client_ip=client_ip
        )
        
        # Save configuration file with explicit UTF-8 encoding
        conf_file = client_dir / f"{client_name}.conf"
        conf_file.write_text(config, encoding='utf-8')
        print(f"  Saved: {conf_file}")
        
        # Generate QR code
        print("  Generating QR code...")
        qr_base64 = self.config_gen.generate_qr_code(config)
        
        # Save QR code as PNG
        import base64
        qr_file = client_dir / f"{client_name}_qr.png"
        qr_image_data = base64.b64decode(qr_base64)
        qr_file.write_bytes(qr_image_data)
        print(f"  Saved: {qr_file}")
        
        # Return client information
        result = {
            'client_name': client_name,
            'client_ip': client_ip,
            'public_key': public_key,
            'private_key': private_key,
            'conf_file': str(conf_file),
            'qr_file': str(qr_file),
            'config': config
        }
        
        print(f"✅ Client '{client_name}' created successfully!")
        print(f"   Config: {conf_file}")
        print(f"   QR Code: {qr_file}")
        print(f"   IP Address: {client_ip}")
        
        return result


def main():
    """Main function for CLI usage."""
    parser = argparse.ArgumentParser(description='Add a VPN client')
    parser.add_argument('client_name', help='Name for the VPN client')
    
    args = parser.parse_args()
    
    # Validate client name
    client_name = args.client_name.strip()
    if not client_name:
        print("Error: Client name cannot be empty")
        sys.exit(1)
    
    # Check if client already exists
    clients_dir = Path('clients')
    client_dir = clients_dir / client_name
    if client_dir.exists():
        print(f"Error: Client '{client_name}' already exists in {client_dir}")
        sys.exit(1)
    
    try:
        # Generate client
        generator = SimpleClientGenerator()
        result = generator.add_client(client_name)
        
        print("\n" + "="*50)
        print("CLIENT GENERATION COMPLETE")
        print("="*50)
        print(f"Client Name: {result['client_name']}")
        print(f"IP Address: {result['client_ip']}")
        print(f"Config File: {result['conf_file']}")
        print(f"QR Code: {result['qr_file']}")
        print("\nNext steps:")
        print("1. Send the .conf file to your client")
        print("2. Or have them scan the QR code with WireGuard app")
        print("3. Client connects to VPN server")
        
    except Exception as e:
        print(f"Error generating client: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
