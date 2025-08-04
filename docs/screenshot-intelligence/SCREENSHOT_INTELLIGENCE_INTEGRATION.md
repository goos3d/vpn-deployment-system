# 📸 Screenshot Intelligence Integration

## Quick Start for Other Projects

The Screenshot Intelligence System has been extracted as a standalone package and is available at:
**https://github.com/goos3d/screenshot-intelligence-system**

### Integration Options

#### 1. As a Git Submodule
```bash
# Add as submodule to your project
git submodule add https://github.com/goos3d/screenshot-intelligence-system.git screenshot-intel

# Use in your project
from screenshot_intel.screenshot import ScreenshotIntelligence
```

#### 2. Direct Installation
```bash
# Clone and install
git clone https://github.com/goos3d/screenshot-intelligence-system.git
cd screenshot-intelligence-system
pip install -e .
```

#### 3. Copy Integration (for this VPN project)
```python
# Import from our existing src/screenshot/ directory
from src.screenshot import OCREngine, KnowledgeBase, PatternMatcher
```

### Usage in Other Projects

#### Basic Usage
```python
from screenshot import ScreenshotIntelligence

# Initialize system
si = ScreenshotIntelligence(base_dir="my_screenshots")

# Process screenshots
result = si.process_image("screenshot.png")
print(f"Extracted: {result['text']}")
print(f"Confidence: {result['confidence']}%")
print(f"Patterns: {result['patterns']}")
```

#### CLI Usage
```bash
# Process screenshots
python3 -m screenshot screenshot parse image.png

# Search knowledge base
python3 -m screenshot screenshot search "Active"

# System status
python3 -m screenshot screenshot status
```

### Custom Pattern Recognition

Extend the system for your specific use case:

```python
from screenshot import PatternMatcher

class MyCustomMatcher(PatternMatcher):
    def extract_custom_patterns(self, text):
        # Your application-specific patterns
        patterns = {}
        
        # Example: Extract database connections
        import re
        db_pattern = r'mongodb://[^\s]+'
        patterns['databases'] = re.findall(db_pattern, text)
        
        return patterns
```

### Perfect for:
- **DevOps**: Server deployment screenshots
- **Testing**: UI test result captures  
- **Documentation**: Auto-generate docs from screenshots
- **Monitoring**: Parse system status screens
- **Compliance**: Visual audit trails

---

*The Screenshot Intelligence System provides 94%+ accuracy OCR with specialized pattern recognition for technical screenshots, making it perfect for automating visual data extraction in any technical workflow.*
