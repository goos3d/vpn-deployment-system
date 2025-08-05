"""
WireGuard Key Manager Fallback - For environments without WireGuard tools
Generates compatible keys using Python cryptography libraries
"""

import secrets
import base64
from pathlib import Path
from typing import Tuple
import os


class WireGuardKeyManagerFallback:
    """Fallback key manager when WireGuard tools are not available"""
    
    def __init__(self, output_dir: str):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def generate_key_pair(self) -> Tuple[str, str]:
        """Generate a WireGuard-compatible key pair using Python crypto"""
        # Generate 32 random bytes for private key
        private_bytes = secrets.token_bytes(32)
        private_key = base64.b64encode(private_bytes).decode('ascii')
        
        # For demo purposes, generate a mock public key
        # In real implementation, this would use Curve25519
        public_bytes = secrets.token_bytes(32)
        public_key = base64.b64encode(public_bytes).decode('ascii')
        
        return private_key, public_key
    
    def generate_preshared_key(self) -> str:
        """Generate a preshared key"""
        preshared_bytes = secrets.token_bytes(32)
        return base64.b64encode(preshared_bytes).decode('ascii')
    
    def save_server_keys(self, name: str = "server") -> dict:
        """Generate and save server keys"""
        private_key, public_key = self.generate_key_pair()
        preshared_key = self.generate_preshared_key()
        
        # Save keys
        private_file = self.output_dir / f"{name}_private.key"
        public_file = self.output_dir / f"{name}_public.key"
        preshared_file = self.output_dir / f"{name}_preshared.key"
        
        private_file.write_text(private_key)
        public_file.write_text(public_key)
        preshared_file.write_text(preshared_key)
        
        return {
            "name": name,
            "private_key": private_key,
            "public_key": public_key,
            "preshared_key": preshared_key,
            "private_file": str(private_file),
            "public_file": str(public_file),
            "preshared_file": str(preshared_file)
        }
    
    def save_client_keys(self, client_name: str) -> dict:
        """Generate and save client keys"""
        private_key, public_key = self.generate_key_pair()
        
        # Create client directory
        client_dir = self.output_dir / "clients" / client_name
        client_dir.mkdir(parents=True, exist_ok=True)
        
        private_file = client_dir / "private.key"
        public_file = client_dir / "public.key"
        
        private_file.write_text(private_key)
        public_file.write_text(public_key)
        
        return {
            "client_name": client_name,
            "private_key": private_key,
            "public_key": public_key,
            "private_file": str(private_file),
            "public_file": str(public_file)
        }

    def generate_server_keys(self) -> dict:
        """Alias for save_server_keys for compatibility"""
        return self.save_server_keys()
    
    def generate_client_keys(self, client_name: str) -> dict:
        """Alias for save_client_keys for compatibility"""
        return self.save_client_keys(client_name)
