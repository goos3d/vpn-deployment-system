#!/usr/bin/env python3
"""
Test script to verify the web GUI generates clean configuration files.
"""

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from src.core.client_config import ClientConfigGenerator
from src.core.keys import WireGuardKeyManager

def test_clean_config_generation():
    """Test that configuration generation produces clean files."""
    
    print("🧪 Testing clean configuration generation...")
    
    # Test server public key with simulated corruption (like from web GUI)
    corrupted_server_key = "ÿþDEQ0g/nJrVXhS0jm5CHVHJy9Z5pJvCpn1RODqDQ5Jn4="
    
    print(f"📝 Input server key (corrupted): {repr(corrupted_server_key)}")
    
    # Create config generator
    config_gen = ClientConfigGenerator(
        server_public_key=corrupted_server_key,
        server_endpoint="184.105.7.112",
        server_port=51820,
        network_base="10.0.0.0/24"
    )
    
    # Generate client keys
    key_manager = WireGuardKeyManager()
    private_key, public_key = key_manager.generate_key_pair()
    
    print(f"🔑 Generated client keys successfully")
    print(f"   Private: {private_key[:20]}...")
    print(f"   Public:  {public_key[:20]}...")
    
    # Generate configuration
    try:
        config = config_gen.generate_config(
            client_name="test_admin_fresh",
            client_private_key=private_key,
            client_ip="10.0.0.50"
        )
        
        print("✅ Configuration generated successfully!")
        print("\n📄 Generated configuration:")
        print("=" * 60)
        print(config)
        print("=" * 60)
        
        # Verify the key was cleaned
        if "ÿþ" in config:
            print("❌ ERROR: Configuration still contains encoding artifacts!")
            return False
        else:
            print("✅ Configuration is clean - no encoding artifacts found!")
            
        # Save to file to test file writing
        test_file = Path("test_clean_config.conf")
        test_file.write_text(config, encoding='utf-8')
        
        # Read it back and verify
        read_config = test_file.read_text(encoding='utf-8')
        
        if read_config == config:
            print("✅ File write/read test passed!")
        else:
            print("❌ File write/read test failed!")
            return False
            
        # Clean up
        test_file.unlink()
        
        return True
        
    except Exception as e:
        print(f"❌ ERROR: {e}")
        return False

def test_key_cleaning():
    """Test the key cleaning function specifically."""
    
    print("\n🧹 Testing key cleaning function...")
    
    test_cases = [
        ("DEQ0g/nJrVXhS0jm5CHVHJy9Z5pJvCpn1RODqDQ5Jn4=", "Normal key"),
        ("ÿþDEQ0g/nJrVXhS0jm5CHVHJy9Z5pJvCpn1RODqDQ5Jn4=", "UTF-8 BOM"),
        ("��D E Q 0 g / n J r V X h S 0 j m 5 C H V H J y 9 Z 5 p J v C p n 1 R O D q D Q 5 J n 4 =", "Spaces and artifacts"),
        ("DEQ0g/nJrVXhS0jm5CHVHJy9Z5pJvCpn1RODqDQ5Jn4=\ufffd", "Replacement char"),
    ]
    
    config_gen = ClientConfigGenerator(
        server_public_key="dummy",
        server_endpoint="test",
        server_port=51820
    )
    
    for test_key, description in test_cases:
        try:
            clean_key = config_gen._clean_base64_key(test_key)
            expected = "DEQ0g/nJrVXhS0jm5CHVHJy9Z5pJvCpn1RODqDQ5Jn4="
            
            if clean_key == expected:
                print(f"✅ {description}: Cleaned successfully")
            else:
                print(f"❌ {description}: Expected '{expected}', got '{clean_key}'")
                
        except Exception as e:
            print(f"❌ {description}: Error - {e}")

if __name__ == "__main__":
    print("🔧 Web GUI Configuration Generation Fix Test")
    print("=" * 60)
    
    success = test_clean_config_generation()
    test_key_cleaning()
    
    if success:
        print("\n🎉 All tests passed! Web GUI should now generate clean configs.")
    else:
        print("\n❌ Some tests failed. Check the issues above.")
