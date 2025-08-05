#!/usr/bin/env python3
"""
Create the test2 user that the web GUI is looking for
"""

import sys
import json
from pathlib import Path
from datetime import datetime

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

def create_test2_user():
    """Create the test2 user for web GUI"""
    
    try:
        from src.core.keys import WireGuardKeyManager  
        from src.core.client_config import ClientConfigGenerator
        
        print("🔑 Creating test2 user for Web GUI")
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
        
        # Generate client keys for test2
        client_name = "test2"
        print(f"📝 Creating user: {client_name}")
        
        client_keys = key_manager.generate_client_keys(client_name)
        print(f"✅ Keys generated for {client_name}")
        print(f"   Public Key: {client_keys['public_key'][:20]}...")
        
        # Create client configuration with HIPAA-compliant pattern
        config_gen = ClientConfigGenerator(
            server_public_key=server_public_key,
            server_endpoint="184.105.7.112",
            server_port=51820,
            network_base="10.0.0.0/24"
        )
        
        # Generate config with HIPAA compliant settings
        vpn_config = config_gen.generate_config(
            client_name=client_name,
            client_private_key=client_keys['private_key'],
            allowed_ips="10.0.0.0/24",  # VPN network only
            dns_servers=["1.1.1.1", "8.8.8.8"]
        )
        
        # Save configuration file in web GUI expected location
        config_dir = Path("./wireguard-keys/clients") / client_name
        config_dir.mkdir(parents=True, exist_ok=True)
        
        config_file = config_dir / f"{client_name}.conf"
        config_file.write_text(vpn_config)
        
        print(f"✅ Configuration saved: {config_file}")
        
        # Also save to src/web location where web GUI looks
        web_config_dir = Path("./src/web/wireguard-keys/clients") / client_name
        web_config_dir.mkdir(parents=True, exist_ok=True)
        web_config_file = web_config_dir / f"{client_name}.conf"
        web_config_file.write_text(vpn_config)
        
        print(f"✅ Web GUI config saved: {web_config_file}")
        
        # Generate QR code if possible
        try:
            import qrcode
            qr = qrcode.QRCode(version=1, box_size=10, border=5)
            qr.add_data(vpn_config)
            qr.make(fit=True)
            
            qr_file = config_dir / f"{client_name}_qr.png"
            qr_img = qr.make_image(fill_color="black", back_color="white")
            qr_img.save(qr_file)
            
            # Also save QR to web GUI location
            web_qr_file = web_config_dir / f"{client_name}_qr.png"
            qr_img.save(web_qr_file)
            
            print(f"✅ QR codes saved")
            
        except ImportError:
            print("⚠️  QR code generation skipped (qrcode not available)")
        
        print("\n" + "=" * 50)
        print("📋 test2 VPN CONFIGURATION")
        print("=" * 50)
        print(vpn_config)
        print("=" * 50)
        
        return {
            "success": True,
            "client_name": client_name,
            "config_file": str(config_file),
            "web_config_file": str(web_config_file),
            "config": vpn_config
        }
        
    except Exception as e:
        print(f"❌ Error creating test2 user: {e}")
        import traceback
        traceback.print_exc()
        return {"success": False, "error": str(e)}

if __name__ == "__main__":
    result = create_test2_user()
    if result["success"]:
        print(f"\n🏆 SUCCESS: test2 user created!")
        print(f"📁 Web GUI should now be able to download the config")
    else:
        print(f"\n❌ FAILED: {result['error']}")
