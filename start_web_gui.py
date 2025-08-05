#!/usr/bin/env python3
"""
Patched VPN Web GUI Startup Script - Bug Fixed Version
This script starts the VPN Web GUI with all backends properly configured
"""

import sys
import os
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

def install_missing_packages():
    """Install any missing required packages"""
    required_packages = ['flask', 'jinja2', 'qrcode', 'pillow', 'click']
    
    for package in required_packages:
        try:
            __import__(package)
        except ImportError:
            print(f"📦 Installing missing package: {package}")
            import subprocess
            subprocess.run([sys.executable, "-m", "pip", "install", package])

def setup_directories():
    """Create required directories"""
    dirs_to_create = [
        "./wireguard-keys",
        "./clients",
        "./src/web/templates"
    ]
    
    for dir_path in dirs_to_create:
        Path(dir_path).mkdir(parents=True, exist_ok=True)
        print(f"📁 Directory ready: {dir_path}")

def main():
    """Main startup function with error handling"""
    
    print("🚀 Starting VPN Web GUI - Patched Version")
    print("=" * 50)
    
    # Install missing packages
    try:
        install_missing_packages()
        print("✅ All packages available")
    except Exception as e:
        print(f"⚠️ Package installation issue: {e}")
    
    # Setup directories
    setup_directories()
    
    # Import with error handling
    try:
        from src.web.app import VPNDashboard
        print("✅ VPN Dashboard module imported")
    except Exception as e:
        print(f"❌ Import error: {e}")
        print("🔧 Attempting to continue with basic Flask app...")
        
        # Create a basic Flask fallback
        from flask import Flask, jsonify
        app = Flask(__name__)
        
        @app.route('/')
        def index():
            return '''
            <html>
                <head><title>VPN Dashboard - Setup Required</title></head>
                <body>
                    <h1>🏥 VPN Dashboard</h1>
                    <h2>Setup Required</h2>
                    <p>The VPN system needs to be configured. Please run:</p>
                    <pre>python generate_server_keys.py</pre>
                    <p>Then restart the web GUI.</p>
                </body>
            </html>
            '''
        
        @app.route('/api/status')
        def status():
            return jsonify({"status": "setup_required", "message": "Server keys need to be generated"})
        
        print("🌐 Starting basic Flask server on http://0.0.0.0:5000")
        app.run(host="0.0.0.0", port=5000, debug=True)
        return
    
    try:
        print("🌐 Starting VPN Dashboard on http://0.0.0.0:5000")
        print("📁 Keys directory: ./wireguard-keys")
        print("🔒 Server endpoint: 184.105.7.112")
        
        # Create dashboard with error handling
        dashboard = VPNDashboard(keys_dir="./wireguard-keys", server_endpoint="184.105.7.112")
        
        print("✅ VPN Dashboard initialized successfully")
        print("🌐 Access URLs:")
        print("   - Local: http://127.0.0.1:5000")
        print("   - Server: http://184.105.7.112:5000")
        print("   - VPN Gateway: http://10.0.0.1:5000")
        print("")
        print("🏥 Ready for Dr. Kover's practice!")
        print("👨‍⚕️ Create VPN users through the web interface")
        
        # Start the web server
        dashboard.run(host="0.0.0.0", port=5000, debug=True)
        
    except Exception as e:
        print(f"❌ Error starting VPN Dashboard: {e}")
        print("🔧 Check the error details above and try:")
        print("   1. python generate_server_keys.py")
        print("   2. Restart this script")

if __name__ == "__main__":
    main()
