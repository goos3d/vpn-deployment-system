#!/usr/bin/env python3
"""
Simple Web GUI Import and Configuration Test
"""

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

def test_web_gui_import():
    """Test if we can import and configure the web GUI"""
    print("🔍 Testing Web GUI Import...")
    
    try:
        from src.web.app import VPNDashboard
        print("✅ Web GUI module imported successfully")
        
        # Test dashboard creation
        dashboard = VPNDashboard(keys_dir="./wireguard-keys", server_endpoint="184.105.7.112")
        print("✅ VPN Dashboard created successfully")
        
        # Test Flask app creation
        app = dashboard.app
        print(f"✅ Flask app created: {app}")
        
        return True
        
    except ImportError as e:
        print(f"❌ Import error: {e}")
        return False
    except Exception as e:
        print(f"❌ Configuration error: {e}")
        return False

def test_dependencies():
    """Test if all required dependencies are available"""
    print("🔍 Testing Dependencies...")
    
    dependencies = ['flask', 'jinja2', 'qrcode', 'PIL']  # PIL is pillow
    all_good = True
    
    for dep in dependencies:
        try:
            __import__(dep)
            print(f"✅ {dep} available")
        except ImportError:
            print(f"❌ {dep} missing")
            all_good = False
    
    return all_good

def main():
    print("🚀 Web GUI Configuration Test")
    print("=" * 40)
    
    deps_ok = test_dependencies()
    import_ok = test_web_gui_import()
    
    print("\n" + "=" * 40)
    print("📊 CONFIGURATION TEST SUMMARY")
    print("=" * 40)
    
    if deps_ok and import_ok:
        print("🏆 WEB GUI IS PROPERLY CONFIGURED!")
        print("📋 Ready for deployment and execution")
        return 0
    else:
        print("⚠️ Web GUI configuration has issues")
        return 1

if __name__ == "__main__":
    sys.exit(main())
