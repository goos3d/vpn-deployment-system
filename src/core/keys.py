"""
WireGuard Key Management Module

Handles secure generation and management of WireGuard keys for VPN deployment.
"""

import os
import subprocess
import base64
from pathlib import Path
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from typing import Tuple, Optional


class WireGuardKeyManager:
    """Manages WireGuard key generation and encryption."""
    
    def __init__(self, output_dir: str = "/etc/wireguard"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def generate_key_pair(self) -> Tuple[str, str]:
        """
        Generate a WireGuard private/public key pair.
        
        Returns:
            Tuple of (private_key, public_key)
        """
        # Generate private key
        private_key_result = subprocess.run(
            ["wg", "genkey"], 
            capture_output=True, 
            text=True, 
            check=True
        )
        private_key = private_key_result.stdout.strip()
        
        # Generate public key from private key
        public_key_result = subprocess.run(
            ["wg", "pubkey"], 
            input=private_key, 
            capture_output=True, 
            text=True, 
            check=True
        )
        public_key = public_key_result.stdout.strip()
        
        return private_key, public_key
    
    def generate_preshared_key(self) -> str:
        """Generate a WireGuard preshared key for additional security."""
        result = subprocess.run(
            ["wg", "genpsk"], 
            capture_output=True, 
            text=True, 
            check=True
        )
        return result.stdout.strip()
    
    def encrypt_private_key(self, private_key: str, password: str) -> str:
        """
        Encrypt a private key with a password.
        
        Args:
            private_key: The private key to encrypt
            password: Password for encryption
            
        Returns:
            Base64 encoded encrypted private key
        """
        password_bytes = password.encode()
        salt = os.urandom(16)
        
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=100000,
        )
        key = base64.urlsafe_b64encode(kdf.derive(password_bytes))
        fernet = Fernet(key)
        
        encrypted = fernet.encrypt(private_key.encode())
        # Combine salt and encrypted data
        return base64.b64encode(salt + encrypted).decode()
    
    def decrypt_private_key(self, encrypted_key: str, password: str) -> str:
        """
        Decrypt an encrypted private key.
        
        Args:
            encrypted_key: Base64 encoded encrypted private key
            password: Password for decryption
            
        Returns:
            Decrypted private key
        """
        password_bytes = password.encode()
        encrypted_data = base64.b64decode(encrypted_key.encode())
        
        # Extract salt and encrypted key
        salt = encrypted_data[:16]
        encrypted = encrypted_data[16:]
        
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=100000,
        )
        key = base64.urlsafe_b64encode(kdf.derive(password_bytes))
        fernet = Fernet(key)
        
        return fernet.decrypt(encrypted).decode()
    
    def save_server_keys(self, name: str = "server", encrypt: bool = False, 
                        password: Optional[str] = None) -> dict:
        """
        Generate and save server keys.
        
        Args:
            name: Server name/identifier
            encrypt: Whether to encrypt the private key
            password: Password for encryption (required if encrypt=True)
            
        Returns:
            Dictionary with key information
        """
        private_key, public_key = self.generate_key_pair()
        preshared_key = self.generate_preshared_key()
        
        # Save keys
        private_file = self.output_dir / f"{name}_private.key"
        public_file = self.output_dir / f"{name}_public.key"
        preshared_file = self.output_dir / f"{name}_preshared.key"
        
        if encrypt and password:
            encrypted_private = self.encrypt_private_key(private_key, password)
            private_file.write_text(encrypted_private)
        else:
            private_file.write_text(private_key)
            
        public_file.write_text(public_key)
        preshared_file.write_text(preshared_key)
        
        # Set secure permissions
        os.chmod(private_file, 0o600)
        os.chmod(public_file, 0o644)
        os.chmod(preshared_file, 0o600)
        
        return {
            "name": name,
            "private_key": private_key if not encrypt else "[ENCRYPTED]",
            "public_key": public_key,
            "preshared_key": preshared_key,
            "private_file": str(private_file),
            "public_file": str(public_file),
            "preshared_file": str(preshared_file),
            "encrypted": encrypt
        }
    
    def save_client_keys(self, client_name: str) -> dict:
        """
        Generate and save client keys.
        
        Args:
            client_name: Client identifier
            
        Returns:
            Dictionary with client key information
        """
        private_key, public_key = self.generate_key_pair()
        
        # Create client directory
        client_dir = self.output_dir / "clients" / client_name
        client_dir.mkdir(parents=True, exist_ok=True)
        
        private_file = client_dir / "private.key"
        public_file = client_dir / "public.key"
        
        private_file.write_text(private_key)
        public_file.write_text(public_key)
        
        # Set secure permissions
        os.chmod(private_file, 0o600)
        os.chmod(public_file, 0o644)
        
        return {
            "client_name": client_name,
            "private_key": private_key,
            "public_key": public_key,
            "private_file": str(private_file),
            "public_file": str(public_file)
        }


def check_wireguard_installation() -> bool:
    """Check if WireGuard tools are installed."""
    try:
        subprocess.run(["wg", "--version"], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False
