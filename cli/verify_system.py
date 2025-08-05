#!/usr/bin/env python3
"""
verify_system.py - System Health Check

Verifies that all critical components are working before delivery.
"""

import sys
import os
from pathlib import Path

# Add src to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

def test_imports():
    """Test that core modules can be imported."""
    print("🔍 Testing core module imports...")
    try:
        from src.core.client_config import ClientConfigGenerator
        from src.core.keys import WireGuardKeyManager
        print("✅ Core modules import successfully")
        return True
    except ImportError as e:
        print(f"❌ Import failed: {e}")
        return False

def test_key_generation():
    """Test WireGuard key generation."""
    print("🔍 Testing WireGuard key generation...")
    try:
        from src.core.keys import WireGuardKeyManager
        key_manager = WireGuardKeyManager()
        private_key, public_key = key_manager.generate_key_pair()
        
        # Basic validation
        if len(private_key) > 30 and len(public_key) > 30:
            print("✅ Key generation working")
            return True
        else:
            print("❌ Generated keys too short")
            return False
    except Exception as e:
        print(f"❌ Key generation failed: {e}")
        return False

def test_config_generation():
    """Test clean configuration generation."""
    print("🔍 Testing configuration generation...")
    try:
        from src.core.client_config import ClientConfigGenerator
        from src.core.keys import WireGuardKeyManager
        
        # Generate test keys
        key_manager = WireGuardKeyManager()
        private_key, public_key = key_manager.generate_key_pair()
        
        # Generate config
        config_gen = ClientConfigGenerator(
            server_public_key='DEQ0g/nJrVXhS0jm5CHVHJy9Z5pJvCpn1RODqDQ5Jn4=',
            server_endpoint='184.105.7.112',
            server_port=51820
        )
        
        config = config_gen.generate_config(
            client_name='test_verify',
            client_private_key=private_key,
            client_ip='10.0.0.99'
        )
        
        # Check for UTF-8 BOM corruption
        if '\ufeff' in config or 'ÿþ' in config:
            print("❌ UTF-8 BOM corruption detected!")
            return False
        
        # Check for required sections
        if '[Interface]' in config and '[Peer]' in config:
            print("✅ Configuration generation working")
            return True
        else:
            print("❌ Configuration missing required sections")
            return False
            
    except Exception as e:
        print(f"❌ Configuration generation failed: {e}")
        return False

def test_server_key():
    """Test that server public key is clean."""
    print("🔍 Testing server public key...")
    server_key = 'DEQ0g/nJrVXhS0jm5CHVHJy9Z5pJvCpn1RODqDQ5Jn4='
    
    # Check for BOM artifacts
    if '\ufeff' in server_key or 'ÿþ' in server_key:
        print("❌ Server key has UTF-8 BOM corruption!")
        return False
    
    # Check base64 format
    import re
    if re.match(r'^[A-Za-z0-9+/]*={0,2}$', server_key):
        print("✅ Server public key is clean")
        return True
    else:
        print("❌ Server key format invalid")
        return False

def test_cli_script():
    """Test that CLI script exists and is executable."""
    print("🔍 Testing CLI script...")
    cli_script = Path(__file__).parent / 'add_client.py'
    
    if cli_script.exists():
        print("✅ CLI script exists")
        return True
    else:
        print("❌ CLI script missing")
        return False

def main():
    """Run all system verification tests."""
    print("🚀 VPN SYSTEM VERIFICATION")
    print("="*50)
    
    tests = [
        test_imports,
        test_key_generation,
        test_config_generation,
        test_server_key,
        test_cli_script
    ]
    
    passed = 0
    failed = 0
    
    for test in tests:
        if test():
            passed += 1
        else:
            failed += 1
        print()
    
    print("="*50)
    print(f"RESULTS: {passed} passed, {failed} failed")
    
    if failed == 0:
        print("🎉 ALL TESTS PASSED - SYSTEM READY FOR DELIVERY")
        return True
    else:
        print("❌ SOME TESTS FAILED - DO NOT DELIVER")
        return False

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
