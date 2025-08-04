#!/usr/bin/env python3
"""
Screenshot Intelligence System - Basic Usage Example
"""

from screenshot.ocr_engine import OCREngine
from screenshot.knowledge_base import KnowledgeBase
from screenshot.pattern_matcher import PatternMatcher


def basic_example():
    """Basic usage example"""
    print("🚀 Screenshot Intelligence System - Basic Example")
    print("=" * 50)
    
    # Initialize components
    ocr = OCREngine()
    kb = KnowledgeBase("example_screenshots")
    matcher = PatternMatcher()
    
    print("✅ Components initialized")
    
    # Test OCR functionality
    print("\n📝 Testing OCR Engine:")
    print("- Tesseract version check...")
    try:
        import pytesseract
        version = pytesseract.get_tesseract_version()
        print(f"  ✅ Tesseract {version} found")
    except Exception as e:
        print(f"  ❌ Tesseract not found: {e}")
        print("  💡 Install with: brew install tesseract (macOS)")
        return
    
    # Example: Process a hypothetical screenshot
    print("\n🔍 Pattern Recognition Examples:")
    
    # Simulate extracted text from a VPN screenshot
    sample_text = """
    interface: wg0
      public key: ABC123DEF456
      private key: (hidden)
      listening port: 51820

    peer: XYZ789
      endpoint: 184.105.7.112:51820
      allowed ips: 10.0.0.2/32
      latest handshake: 1 minute, 23 seconds ago
      transfer: 1.01 KiB received, 2.43 KiB sent
    """
    
    # Extract patterns
    patterns = matcher.extract_patterns(sample_text)
    print(f"  📊 Extracted patterns: {len(patterns)} found")
    
    for category, data in patterns.items():
        print(f"    • {category}: {data}")
    
    # Add to knowledge base
    sample_data = {
        'screenshot_type': 'wireguard_status',
        'extracted_fields': patterns,
        'confidence': 95
    }
    
    kb_format = f"| {datetime.now().strftime('%H:%M:%S')} | WireGuard: Active | [example.png](example.png) | Endpoint: 184.105.7.112:51820 |"
    
    entry_id = kb.add_entry(sample_data, "example.png", kb_format)
    print(f"\n💾 Added to knowledge base with ID: {entry_id}")
    
    # Search example
    results = kb.search("184.105.7.112")
    print(f"🔍 Search results for '184.105.7.112': {len(results)} found")
    
    # Generate summary
    summary = kb.generate_summary()
    print(f"\n📈 Knowledge base summary:")
    print(f"  • Total entries: {summary['total_entries']}")
    print(f"  • Knowledge base file: {summary.get('knowledge_base_file', 'N/A')}")
    
    print("\n🎉 Example completed successfully!")


def advanced_example():
    """Advanced usage with custom patterns"""
    print("\n🎯 Advanced Example - Custom Pattern Recognition")
    print("=" * 50)
    
    # Custom pattern matcher
    class CustomMatcher(PatternMatcher):
        def extract_custom_patterns(self, text):
            """Extract custom application-specific patterns"""
            import re
            
            patterns = {}
            
            # Example: Extract database connection strings
            db_pattern = r'mongodb://[^\s]+'
            db_matches = re.findall(db_pattern, text)
            if db_matches:
                patterns['database_connections'] = db_matches
            
            # Example: Extract API endpoints
            api_pattern = r'https?://[^\s/]+/api/[^\s]*'
            api_matches = re.findall(api_pattern, text)
            if api_matches:
                patterns['api_endpoints'] = api_matches
            
            # Example: Extract log levels
            log_pattern = r'\[(ERROR|WARN|INFO|DEBUG)\]'
            log_matches = re.findall(log_pattern, text)
            if log_matches:
                patterns['log_levels'] = log_matches
            
            return patterns
    
    # Test custom patterns
    sample_log_text = """
    [INFO] Starting application server
    [ERROR] Database connection failed: mongodb://user:pass@db.example.com:27017/mydb
    [WARN] API endpoint https://api.example.com/api/v1/users responded slowly
    [DEBUG] Processing request
    """
    
    custom_matcher = CustomMatcher()
    custom_patterns = custom_matcher.extract_custom_patterns(sample_log_text)
    
    print("🔧 Custom patterns extracted:")
    for category, data in custom_patterns.items():
        print(f"  • {category}: {data}")
    
    print("\n✨ Advanced example completed!")


if __name__ == "__main__":
    from datetime import datetime
    
    # Run basic example
    basic_example()
    
    # Run advanced example  
    advanced_example()
    
    print("\n" + "=" * 50)
    print("🎯 Ready to integrate Screenshot Intelligence into your project!")
    print("📚 Check the README.md for more integration examples")
