#!/usr/bin/env python3
"""
Create New VPN User - Home Laptop Test
This script creates a new VPN user for testing from home laptop
"""

import sys
import json
from pathlib import Path
from datetime import datetime

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

def create_test_user():
    """Create a new VPN user for home laptop testing"""
    
    try:
        from src.core.keys import WireGuardKeyManager  
        from src.core.client_config import ClientConfigGenerator
        
        print("🔑 Creating VPN User for Home Laptop Test")
        print("=" * 50)
        
        # Initialize key manager
        keys_dir = Path("./wireguard-keys")
        keys_dir.mkdir(exist_ok=True)
        
        key_manager = WireGuardKeyManager(str(keys_dir))
        
        # Load or generate server keys
        server_public_file = keys_dir / "server_public.key"
        if not server_public_file.exists():
            print("🔑 Server keys not found, generating...")
            server_keys = key_manager.generate_server_keys()
            server_public_file.write_text(server_keys['public_key'])
            server_private_file = keys_dir / "server_private.key"
            server_private_file.write_text(server_keys['private_key'])
            print("✅ Server keys generated")
        
        server_public_key = server_public_file.read_text().strip()
        print(f"🔑 Using server public key: {server_public_key[:20]}...")
        
        # Generate client keys
        client_name = f"home_laptop_test_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        print(f"📝 Creating user: {client_name}")
        
        client_keys = key_manager.generate_client_keys(client_name)
        print(f"✅ Keys generated for {client_name}")
        print(f"   Public Key: {client_keys['public_key'][:20]}...")
        
        # Create client configuration with HIPAA-compliant pattern
        config_gen = ClientConfigGenerator(
            server_public_key=server_public_key,  # Real server public key
            server_endpoint="184.105.7.112",
            server_port=51820,
            network_base="10.0.0.0/24"
        )
        
        # Generate config with MacBook-Test pattern (HIPAA compliant)
        vpn_config = config_gen.generate_config(
            client_name=client_name,
            client_private_key=client_keys['private_key'],
            allowed_ips="10.0.0.0/24",  # CRITICAL: VPN network only, preserves internet
            dns_servers=["1.1.1.1", "8.8.8.8"]
        )
        
        # Save configuration file - using web GUI compatible path
        config_dir = Path("./wireguard-keys/clients") / client_name
        config_dir.mkdir(parents=True, exist_ok=True)
        
        config_file = config_dir / f"{client_name}.conf"
        config_file.write_text(vpn_config)
        
        print(f"✅ Configuration saved: {config_file}")
        
        # Generate QR code for mobile setup
        try:
            import qrcode
            qr = qrcode.QRCode(version=1, box_size=10, border=5)
            qr.add_data(vpn_config)
            qr.make(fit=True)
            
            qr_file = config_dir / f"{client_name}_qr.png"
            qr_img = qr.make_image(fill_color="black", back_color="white")
            qr_img.save(qr_file)
            print(f"✅ QR code saved: {qr_file}")
            
        except ImportError:
            print("⚠️  QR code generation skipped (qrcode not available)")
        
        # Display configuration for copying
        print("\n" + "=" * 50)
        print("📋 VPN CONFIGURATION FOR HOME LAPTOP")
        print("=" * 50)
        print(vpn_config)
        print("=" * 50)
        
        # Create summary
        summary = {
            "client_name": client_name,
            "config_file": str(config_file),
            "created": datetime.now().isoformat(),
            "server_endpoint": "184.105.7.112:51820",
            "allowed_ips": "10.0.0.0/24",
            "hipaa_compliant": True,
            "internet_access": "preserved"
        }
        
        summary_file = config_dir / "user_summary.json"
        summary_file.write_text(json.dumps(summary, indent=2))
        
        print(f"📊 Summary saved: {summary_file}")
        print(f"\n🎯 Next Steps:")
        print(f"1. Copy the configuration above to your home laptop")
        print(f"2. Save as {client_name}.conf")
        print(f"3. Import into WireGuard client")
        print(f"4. Connect and test VPN functionality")
        print(f"5. Verify internet access is preserved")
        
        return {
            "success": True,
            "client_name": client_name,
            "config_file": str(config_file),
            "config": vpn_config
        }
        
    except Exception as e:
        print(f"❌ Error creating VPN user: {e}")
        return {"success": False, "error": str(e)}

def main():
    """Main function"""
    result = create_test_user()
    
    if result["success"]:
        print(f"\n🏆 SUCCESS: VPN user created successfully!")
        print(f"📁 Client name: {result['client_name']}")
        return 0
    else:
        print(f"\n❌ FAILED: {result['error']}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
