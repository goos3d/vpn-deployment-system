#!/usr/bin/env python3
"""
Simple VPN Configuration Check - AI Handoff Validation
"""

import sys
from pathlib import Path

def check_macbook_pattern():
    """Check for MacBook-Test pattern in web app"""
    print("🔍 Checking MacBook-Test Pattern Configuration...")
    
    web_app_file = Path("src/web/app.py")
    if not web_app_file.exists():
        print("❌ Web app file not found")
        return False
    
    try:
        # Try different encodings
        for encoding in ['utf-8', 'latin-1', 'cp1252']:
            try:
                content = web_app_file.read_text(encoding=encoding)
                if "10.0.0.0/24" in content:
                    print(f"✅ MacBook-Test pattern (10.0.0.0/24) found in web app (encoding: {encoding})")
                    
                    # Find the specific line
                    lines = content.split('\n')
                    for i, line in enumerate(lines, 1):
                        if "10.0.0.0/24" in line:
                            print(f"   Line {i}: {line.strip()}")
                    
                    return True
                break
            except UnicodeDecodeError:
                continue
        
        print("❌ MacBook-Test pattern (10.0.0.0/24) not found in web app")
        return False
        
    except Exception as e:
        print(f"❌ Error reading web app file: {e}")
        return False

def main():
    """Main validation"""
    print("🚀 Quick VPN Configuration Check")
    print("=" * 40)
    
    result = check_macbook_pattern()
    
    if result:
        print("\n✅ Configuration validation PASSED")
    else:
        print("\n❌ Configuration validation FAILED")
    
    return 0 if result else 1

if __name__ == "__main__":
    sys.exit(main())
