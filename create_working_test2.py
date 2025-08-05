#!/usr/bin/env python3
"""
Create test2 user with REAL server keys for working web GUI
"""

import sys
import json
from pathlib import Path
from datetime import datetime

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

def create_working_test2():
    """Create test2 user with real server public key"""
    
    try:
        from src.core.keys import WireGuardKeyManager  
        from src.core.client_config import ClientConfigGenerator
        
        print("🔑 Creating WORKING test2 user")
        print("=" * 50)
        
        # Use REAL server public key from running WireGuard
        real_server_public_key = "DEQ0g/nJrVXhS0jm5CHVHJy9Z5pJvCpn1RODqDQ5Jn4="
        
        # Initialize key manager
        keys_dir = Path("./wireguard-keys")
        keys_dir.mkdir(exist_ok=True)
        
        # Save real server key
        server_public_file = keys_dir / "server_public.key"
        server_public_file.write_text(real_server_public_key)
        print(f"✅ Real server key saved: {real_server_public_key[:20]}...")
        
        key_manager = WireGuardKeyManager(str(keys_dir))
        
        # Generate client keys for test2
        client_name = "test2"
        client_keys = key_manager.generate_client_keys(client_name)
        print(f"✅ Keys generated for {client_name}")
        
        # Create client configuration with REAL server key
        config_gen = ClientConfigGenerator(
            server_public_key=real_server_public_key,  # REAL key from running server
            server_endpoint="184.105.7.112",
            server_port=51820,
            network_base="10.0.0.0/24"
        )
        
        # Generate config with next available IP (looking at wg show, use 10.0.0.12)
        vpn_config = config_gen.generate_config(
            client_name=client_name,
            client_private_key=client_keys['private_key'],
            client_ip="10.0.0.12",  # Next available IP
            allowed_ips="10.0.0.0/24",  # VPN network only
            dns_servers=["1.1.1.1", "8.8.8.8"]
        )
        
        # Save in BOTH locations for compatibility
        # 1. Web GUI location (where it looks for downloads)
        web_config_dir = Path("./src/web/wireguard-keys/clients") / client_name
        web_config_dir.mkdir(parents=True, exist_ok=True)
        web_config_file = web_config_dir / f"{client_name}.conf"
        web_config_file.write_text(vpn_config)
        print(f"✅ Web GUI config: {web_config_file}")
        
        # 2. Backend location (for consistency)
        backend_config_dir = Path("./wireguard-keys/clients") / client_name
        backend_config_dir.mkdir(parents=True, exist_ok=True)
        backend_config_file = backend_config_dir / f"{client_name}.conf"
        backend_config_file.write_text(vpn_config)
        print(f"✅ Backend config: {backend_config_file}")
        
        print("\n" + "=" * 50)
        print("📋 WORKING test2 VPN CONFIGURATION")
        print("=" * 50)
        print(vpn_config)
        print("=" * 50)
        
        print(f"\n🎯 SUCCESS! test2 user ready!")
        print(f"🌐 Web GUI should now download config successfully")
        print(f"🔑 Uses REAL server key: {real_server_public_key[:20]}...")
        print(f"📍 Client IP: 10.0.0.12 (next available)")
        
        return {"success": True, "client_name": client_name}
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return {"success": False, "error": str(e)}

if __name__ == "__main__":
    result = create_working_test2()
    if result["success"]:
        print(f"\n🏆 Ready to test web GUI download!")
    else:
        print(f"\n❌ Failed: {result['error']}")
