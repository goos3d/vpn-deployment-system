#!/usr/bin/env python3
"""
Generate Server Keys - Fix for Web GUI
This script generates the missing server keys needed for VPN operation
"""

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

def generate_server_keys():
    """Generate WireGuard server keys"""
    
    try:
        from src.core.keys import WireGuardKeyManager
        
        print("🔑 Generating WireGuard Server Keys")
        print("=" * 40)
        
        # Initialize key manager
        keys_dir = Path("./wireguard-keys")
        keys_dir.mkdir(exist_ok=True)
        
        key_manager = WireGuardKeyManager(str(keys_dir))
        
        # Generate server keys
        print("📝 Generating server key pair...")
        server_keys = key_manager.generate_server_keys()
        
        print("✅ Server keys generated successfully!")
        print(f"   Public Key: {server_keys['public_key'][:20]}...")
        print(f"   Private Key: {server_keys['private_key'][:20]}...")
        
        # Save to standard locations
        server_public_file = keys_dir / "server_public.key"
        server_private_file = keys_dir / "server_private.key"
        
        server_public_file.write_text(server_keys['public_key'])
        server_private_file.write_text(server_keys['private_key'])
        
        print(f"📁 Keys saved:")
        print(f"   Public:  {server_public_file}")
        print(f"   Private: {server_private_file}")
        
        return {
            "success": True,
            "public_key": server_keys['public_key'],
            "private_key": server_keys['private_key']
        }
        
    except Exception as e:
        print(f"❌ Error generating server keys: {e}")
        return {"success": False, "error": str(e)}

def main():
    """Main function"""
    result = generate_server_keys()
    
    if result["success"]:
        print(f"\n🏆 SUCCESS: Server keys generated!")
        print(f"🌐 Web GUI should now work for creating clients")
        print(f"🔧 Try creating a user through the web interface again")
        return 0
    else:
        print(f"\n❌ FAILED: {result['error']}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
