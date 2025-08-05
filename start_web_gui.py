#!/usr/bin/env python3
"""
Temporary script to start the VPN Web GUI for AI handoff testing
"""

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

try:
    from src.web.app import VPNDashboard
    
    print("🌐 Starting VPN Dashboard on http://0.0.0.0:5000")
    print("📁 Keys directory: ./wireguard-keys")
    
    # Create dashboard with local keys directory
    dashboard = VPNDashboard(keys_dir="./wireguard-keys", server_endpoint="184.105.7.112")
    
    # Start the web server
    dashboard.run(host="0.0.0.0", port=5000, debug=True)
    
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("Installing missing dependencies...")
    import subprocess
    subprocess.run([sys.executable, "-m", "pip", "install", "click"])
    
except Exception as e:
    print(f"❌ Error starting web GUI: {e}")
    print("Continuing with other tasks...")
