"""
Client Configuration Generator

Creates WireGuard client configuration files and QR codes for easy setup.
"""

import ipaddress
import qrcode
from pathlib import Path
from typing import Dict, Optional, List
from jinja2 import Template
import io
import base64


class ClientConfigGenerator:
    """Generates WireGuard client configurations."""
    
    def __init__(self, server_public_key: str, server_endpoint: str, 
                 server_port: int = 51820, network_base: str = "10.0.0.0/24"):
        self.server_public_key = server_public_key
        self.server_endpoint = server_endpoint
        self.server_port = server_port
        self.network = ipaddress.ip_network(network_base)
        self.allocated_ips = set()
        
    def allocate_client_ip(self) -> str:
        """Allocate the next available IP address for a client."""
        # Start from .2 (server typically uses .1)
        for ip in list(self.network.hosts())[1:]:
            if str(ip) not in self.allocated_ips:
                self.allocated_ips.add(str(ip))
                return str(ip)
        raise ValueError("No available IP addresses in the network")
    
    def generate_config(self, client_name: str, client_private_key: str,
                       client_ip: Optional[str] = None, 
                       dns_servers: List[str] = None,
                       allowed_ips: str = "0.0.0.0/0",
                       preshared_key: Optional[str] = None) -> str:
        """
        Generate WireGuard client configuration.
        
        Args:
            client_name: Name/identifier for the client
            client_private_key: Client's private key
            client_ip: Specific IP to assign (optional, will auto-allocate)
            dns_servers: List of DNS servers
            allowed_ips: Traffic to route through VPN
            preshared_key: Optional preshared key for additional security
            
        Returns:
            WireGuard configuration as string
        """
        if dns_servers is None:
            dns_servers = ["1.1.1.1", "8.8.8.8"]
            
        if client_ip is None:
            client_ip = self.allocate_client_ip()
        else:
            self.allocated_ips.add(client_ip)
        
        # Validate and clean server public key to prevent encoding issues
        clean_server_key = self._clean_base64_key(self.server_public_key)
        
        config_template = Template("""[Interface]
# {{ client_name }} - Generated on {{ timestamp }}
PrivateKey = {{ client_private_key }}
Address = {{ client_ip }}/32
DNS = {{ dns_servers|join(', ') }}

[Peer]
# Server
PublicKey = {{ server_public_key }}
{% if preshared_key %}PresharedKey = {{ preshared_key }}
{% endif %}Endpoint = {{ server_endpoint }}:{{ server_port }}
AllowedIPs = {{ allowed_ips }}
PersistentKeepalive = 25""")
        
        from datetime import datetime
        config = config_template.render(
            client_name=client_name,
            client_private_key=client_private_key,
            client_ip=client_ip,
            dns_servers=dns_servers,
            server_public_key=clean_server_key,
            preshared_key=preshared_key,
            server_endpoint=self.server_endpoint,
            server_port=self.server_port,
            allowed_ips=allowed_ips,
            timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        )
        
        return config
    
    def _clean_base64_key(self, key: str) -> str:
        """
        Clean base64 key by removing any non-base64 characters and BOM.
        
        Args:
            key: Raw key string that may contain encoding artifacts
            
        Returns:
            Clean base64-encoded key
        """
        import re
        
        # Remove byte order marks and other encoding artifacts
        key = key.replace('\ufeff', '')  # Remove UTF-8 BOM
        key = key.replace('\ufffd', '')  # Remove replacement characters
        
        # Remove any non-base64 characters except padding
        key = re.sub(r'[^A-Za-z0-9+/=]', '', key)
        
        # Validate it's a proper base64 string
        if not re.match(r'^[A-Za-z0-9+/]*={0,2}$', key):
            raise ValueError(f"Invalid base64 key format: {key}")
            
        return key
    
    def generate_qr_code(self, config: str, size: int = 10, border: int = 4) -> str:
        """
        Generate QR code for WireGuard configuration.
        
        Args:
            config: WireGuard configuration string
            size: QR code box size
            border: QR code border size
            
        Returns:
            Base64 encoded PNG image of QR code
        """
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=size,
            border=border,
        )
        qr.add_data(config)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Convert to base64
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        img_str = base64.b64encode(buffer.getvalue()).decode()
        
        return img_str
    
    def save_client_package(self, client_name: str, client_private_key: str,
                           output_dir: str, generate_qr: bool = True,
                           **config_kwargs) -> Dict[str, str]:
        """
        Generate and save complete client package.
        
        Args:
            client_name: Client identifier
            client_private_key: Client's private key
            output_dir: Directory to save files
            generate_qr: Whether to generate QR code
            **config_kwargs: Additional configuration options
            
        Returns:
            Dictionary with file paths and information
        """
        output_path = Path(output_dir) / client_name
        output_path.mkdir(parents=True, exist_ok=True)
        
        # Generate configuration
        config = self.generate_config(client_name, client_private_key, **config_kwargs)
        
        # Save configuration file with explicit UTF-8 encoding
        config_file = output_path / f"{client_name}.conf"
        config_file.write_text(config, encoding='utf-8')
        
        result = {
            "client_name": client_name,
            "config_file": str(config_file),
            "config": config
        }
        
        # Generate and save QR code if requested
        if generate_qr:
            qr_data = self.generate_qr_code(config)
            qr_file = output_path / f"{client_name}_qr.png"
            
            # Decode and save QR code image
            import base64
            qr_image_data = base64.b64decode(qr_data)
            qr_file.write_bytes(qr_image_data)
            
            result["qr_file"] = str(qr_file)
            result["qr_base64"] = qr_data
        
        return result
    
    def generate_server_config_section(self, client_public_key: str, 
                                     client_ip: str,
                                     preshared_key: Optional[str] = None) -> str:
        """
        Generate server-side peer configuration for a client.
        
        Args:
            client_public_key: Client's public key
            client_ip: Client's assigned IP
            preshared_key: Optional preshared key
            
        Returns:
            Server configuration section for this peer
        """
        template = Template("""
[Peer]
# Client: {{ client_ip }}
PublicKey = {{ client_public_key }}
{% if preshared_key %}PresharedKey = {{ preshared_key }}
{% endif %}AllowedIPs = {{ client_ip }}/32""")
        
        return template.render(
            client_public_key=client_public_key,
            client_ip=client_ip,
            preshared_key=preshared_key
        )
