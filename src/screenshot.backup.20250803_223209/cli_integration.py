"""
Screenshot Intelligence CLI Integration
Adds screenshot processing commands to the main VPN CLI
"""

import click
from pathlib import Path
from typing import Optional
from PIL import Image
import os


def add_screenshot_commands(cli_group):
    """Add screenshot commands to existing CLI group"""
    
    @cli_group.group(name='screenshot')
    def screenshot_group():
        """Screenshot Intelligence System commands"""
        pass
    
    @screenshot_group.command('parse')
    @click.argument('image_path', type=click.Path(exists=True))
    @click.option('--output', '-o', type=click.Path(), help='Output directory for extracted data')
    @click.option('--format', '-f', type=click.Choice(['json', 'markdown', 'both']), default='both', help='Output format')
    @click.option('--confidence', '-c', type=int, default=70, help='Minimum confidence threshold')
    @click.option('--debug', is_flag=True, help='Enable debug output')
    def parse_screenshot(image_path: str, output: Optional[str], format: str, confidence: int, debug: bool):
        """Parse screenshot and extract VPN-related data"""
        try:
            # Import here to avoid dependency issues if not installed
            from src.screenshot.ocr_engine import OCREngine
            from src.screenshot.pattern_matcher import VPNPatternMatcher
            from src.screenshot.knowledge_base import KnowledgeBase
            
            if debug:
                click.echo(f"🔍 Processing screenshot: {image_path}")
            
            # Initialize components
            ocr = OCREngine()
            matcher = VPNPatternMatcher()
            kb = KnowledgeBase(output or "screenshots")
            
            # Extract text from image
            click.echo("📸 Extracting text from screenshot...")
            ocr_result = ocr.extract_with_confidence(image_path)
            
            if ocr_result['confidence'] < confidence:
                click.echo(f"⚠️  Low confidence OCR result: {ocr_result['confidence']}%")
                if not click.confirm("Continue anyway?"):
                    return
            
            if debug:
                click.echo(f"📝 Extracted text ({len(ocr_result['text'])} chars)")
                click.echo("=" * 50)
                click.echo(ocr_result['text'][:500] + "..." if len(ocr_result['text']) > 500 else ocr_result['text'])
                click.echo("=" * 50)
            
            # Detect screenshot type and extract patterns
            click.echo("🔍 Analyzing content patterns...")
            screenshot_type = matcher.detect_screenshot_type(ocr_result['text'])
            extracted_data = matcher.extract_patterns(ocr_result['text'])
            
            click.echo(f"📊 Screenshot type detected: {screenshot_type}")
            click.echo(f"🎯 Extracted {len(extracted_data)} data points")
            
            # Format for knowledge base
            kb_format = matcher.format_for_knowledge_base(extracted_data, image_path)
            
            # Store in knowledge base
            result_data = {
                'screenshot_type': screenshot_type,
                'extracted_fields': extracted_data,
                'confidence': ocr_result['confidence']
            }
            
            entry_id = kb.add_entry(result_data, image_path, kb_format)
            
            if entry_id:
                click.echo(f"✅ Added to knowledge base with ID: {entry_id}")
                click.echo(f"📁 Knowledge base: {kb.knowledge_file}")
            
            # Output results based on format choice
            if format in ['json', 'both']:
                output_data = {
                    'image_path': image_path,
                    'screenshot_type': screenshot_type,
                    'ocr_confidence': ocr_result['confidence'],
                    'extracted_data': extracted_data,
                    'knowledge_base_entry': entry_id
                }
                click.echo("\n🔧 JSON Output:")
                click.echo(click.style(str(output_data), fg='cyan'))
            
            if format in ['markdown', 'both']:
                click.echo("\n📝 Markdown Output:")
                click.echo(click.style(kb_format, fg='green'))
            
        except ImportError as e:
            if 'pytesseract' in str(e):
                click.echo("❌ Tesseract OCR not found!")
                click.echo("📦 Install with: brew install tesseract")
                click.echo("📦 Then: pip install pytesseract")
            else:
                click.echo(f"❌ Missing dependency: {e}")
        except Exception as e:
            click.echo(f"❌ Error processing screenshot: {e}")
            if debug:
                import traceback
                click.echo(traceback.format_exc())
    
    @screenshot_group.command('search')
    @click.argument('query')
    @click.option('--output', '-o', type=click.Path(), help='Screenshot directory to search')
    @click.option('--limit', '-l', type=int, default=10, help='Maximum results to show')
    def search_knowledge_base(query: str, output: Optional[str], limit: int):
        """Search the screenshot knowledge base"""
        try:
            from src.screenshot.knowledge_base import KnowledgeBase
            
            kb = KnowledgeBase(output or "screenshots")
            results = kb.search(query)
            
            if not results:
                click.echo(f"🔍 No results found for: {query}")
                return
            
            click.echo(f"🔍 Found {len(results)} results for: {query}")
            click.echo("=" * 60)
            
            for i, result in enumerate(results[:limit]):
                click.echo(f"\n📸 Result {i+1}:")
                click.echo(f"   📅 Time: {result['timestamp']}")
                click.echo(f"   📱 Type: {result['screenshot_type']}")
                click.echo(f"   📁 Image: {result['image_path']}")
                click.echo(f"   🎯 Confidence: {result['confidence']}%")
                
                # Show matching fields
                for field, value in result['extracted_fields'].items():
                    click.echo(f"   📊 {field}: {value}")
            
        except Exception as e:
            click.echo(f"❌ Error searching knowledge base: {e}")
    
    @screenshot_group.command('status')
    @click.option('--output', '-o', type=click.Path(), help='Screenshot directory to check')
    def show_status(output: Optional[str]):
        """Show screenshot intelligence system status"""
        try:
            from src.screenshot.knowledge_base import KnowledgeBase
            
            kb = KnowledgeBase(output or "screenshots")
            summary = kb.generate_summary()
            
            click.echo("📊 Screenshot Intelligence Status")
            click.echo("=" * 40)
            click.echo(f"📈 Total entries: {summary['total_entries']}")
            
            if summary['total_entries'] > 0:
                click.echo(f"📅 First entry: {summary['first_entry']}")
                click.echo(f"📅 Last entry: {summary['last_entry']}")
                click.echo(f"📁 Knowledge base: {summary['knowledge_base_file']}")
                click.echo(f"🗃️ Data file: {summary['data_file']}")
                
                click.echo("\n📊 Screenshot Types:")
                for screenshot_type, count in summary['screenshot_types'].items():
                    click.echo(f"   {screenshot_type}: {count}")
                
                # Show latest entries
                latest = kb.get_latest_entries(5)
                click.echo("\n🔄 Latest Entries:")
                for entry in latest:
                    click.echo(f"   📸 {entry['timestamp']}: {entry['screenshot_type']}")
            
        except Exception as e:
            click.echo(f"❌ Error getting status: {e}")
    
    @screenshot_group.command('test')
    @click.option('--debug', is_flag=True, help='Enable debug output')
    def test_system(debug: bool):
        """Test screenshot intelligence system"""
        click.echo("🧪 Testing Screenshot Intelligence System")
        click.echo("=" * 45)
        
        # Test OCR availability
        try:
            import pytesseract
            click.echo("✅ Tesseract OCR: Available")
        except ImportError:
            click.echo("❌ Tesseract OCR: Not installed")
            click.echo("   Install with: brew install tesseract && pip install pytesseract")
        
        # Test PIL
        try:
            from PIL import Image
            click.echo("✅ PIL (Pillow): Available")
        except ImportError:
            click.echo("❌ PIL: Not installed")
            click.echo("   Install with: pip install Pillow")
        
        # Test our modules
        try:
            from src.screenshot.ocr_engine import OCREngine
            from src.screenshot.pattern_matcher import VPNPatternMatcher
            from src.screenshot.knowledge_base import KnowledgeBase
            click.echo("✅ Screenshot Intelligence modules: Available")
        except Exception as e:
            click.echo(f"❌ Module error: {e}")
        
        # Test knowledge base creation
        try:
            kb = KnowledgeBase("test_screenshots")
            click.echo("✅ Knowledge base: Can create")
        except Exception as e:
            click.echo(f"❌ Knowledge base error: {e}")
        
        click.echo("\n🚀 System ready for screenshot processing!")


def create_sample_screenshot():
    """Create a sample screenshot for testing"""
    from PIL import Image, ImageDraw, ImageFont
    
    # Create a simple test image with VPN-like text
    img = Image.new('RGB', (800, 600), color='white')
    draw = ImageDraw.Draw(img)
    
    # Try to use default font, fallback if not available
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 24)
    except:
        font = ImageFont.load_default()
    
    # Draw sample VPN text
    text_lines = [
        "WireGuard VPN Status",
        "",
        "Status: Active",
        "Endpoint: 184.105.7.112:51820",
        "Data Sent: 1.01 KiB",
        "Data Received: 2.34 KiB",
        "",
        "Ping Results:",
        "PING 8.8.8.8: 64 bytes: time=23.4ms",
        "PING google.com: 64 bytes: time=45.2ms"
    ]
    
    y_pos = 50
    for line in text_lines:
        draw.text((50, y_pos), line, fill='black', font=font)
        y_pos += 40
    
    # Save test image
    test_path = Path("test_screenshot.png")
    img.save(test_path)
    
    return str(test_path)
