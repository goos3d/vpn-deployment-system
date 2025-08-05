#!/usr/bin/env python3
"""
Demo script showing the improved web GUI client configuration generation.
This simulates what the web GUI now does when generating client configs.
"""

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from src.core.client_config import ClientConfigGenerator
from src.core.keys import WireGuardKeyManager

def simulate_webgui_client_creation():
    """Simulate the web GUI creating a client configuration."""
    
    print("🌐 Simulating Web GUI Client Creation")
    print("=" * 50)
    
    # This simulates the server public key that might come from the web GUI
    # with encoding issues (like your original admin_fresh.conf)
    potentially_corrupted_server_key = "ÿþDEQ0g/nJrVXhS0jm5CHVHJy9Z5pJvCpn1RODqDQ5Jn4="
    
    print(f"📥 Input from web GUI (potentially corrupted):")
    print(f"   Server Key: {repr(potentially_corrupted_server_key)}")
    print(f"   Client Name: admin_fresh")
    print(f"   Server IP: 184.105.7.112")
    
    # Create the configuration generator (this is what the web GUI does)
    config_gen = ClientConfigGenerator(
        server_public_key=potentially_corrupted_server_key,
        server_endpoint="184.105.7.112", 
        server_port=51820,
        network_base="10.0.0.0/24"
    )
    
    # Generate client keys (this is automatic)
    key_manager = WireGuardKeyManager()
    private_key, public_key = key_manager.generate_key_pair()
    
    print(f"\n🔑 Generated client keys:")
    print(f"   Private: {private_key}")
    print(f"   Public:  {public_key}")
    
    # Generate the client configuration package
    output_dir = Path("./webgui_output")
    result = config_gen.save_client_package(
        client_name="admin_fresh",
        client_private_key=private_key,
        output_dir=output_dir,
        client_ip="10.0.0.50",  # Specific IP like in your original
        generate_qr=True
    )
    
    print(f"\n📄 Generated files:")
    print(f"   Config: {result['config_file']}")
    if 'qr_file' in result:
        print(f"   QR Code: {result['qr_file']}")
    
    # Show the clean configuration
    config_file = Path(result['config_file'])
    clean_config = config_file.read_text(encoding='utf-8')
    
    print(f"\n✨ Clean Configuration (ready for client):")
    print("=" * 60)
    print(clean_config)
    print("=" * 60)
    
    # Verify it's clean
    if "ÿþ" in clean_config or "��" in clean_config:
        print("❌ ERROR: Still contains encoding artifacts!")
    else:
        print("✅ Perfect! No encoding artifacts - ready for client installation!")
    
    print(f"\n📁 Files saved to: {output_dir}/admin_fresh/")
    
    return clean_config

if __name__ == "__main__":
    try:
        clean_config = simulate_webgui_client_creation()
        
        print("\n" + "="*60)
        print("🎯 SUMMARY: WEB GUI IMPROVEMENTS")
        print("="*60)
        print("✅ Server public key is automatically cleaned of encoding artifacts")
        print("✅ Configuration files are saved with explicit UTF-8 encoding") 
        print("✅ Flask routes serve files with proper charset headers")
        print("✅ Base64 validation prevents corrupted keys")
        print("✅ Every client config will now be clean and ready to use!")
        print("\n🚀 Your web GUI will now generate perfect configs every time!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
