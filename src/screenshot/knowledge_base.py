"""
Screenshot Intelligence System - Knowledge Base Manager
Alpha version for storing and retrieving screenshot-extracted data
"""

import os
import json
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime


class KnowledgeBase:
    """Manages the screenshot knowledge base"""
    
    def __init__(self, base_dir: str = "screenshots"):
        self.base_dir = Path(base_dir)
        self.knowledge_file = self.base_dir / "knowledge_base.md"
        self.data_file = self.base_dir / "knowledge_data.json"
        self.setup_directories()
    
    def setup_directories(self):
        """Create directory structure"""
        self.base_dir.mkdir(exist_ok=True)
        
        # Create dated subdirectory for today's screenshots
        today = datetime.now().strftime('%Y-%m-%d')
        self.today_dir = self.base_dir / today
        self.today_dir.mkdir(exist_ok=True)
        
        # Initialize knowledge base if it doesn't exist
        if not self.knowledge_file.exists():
            self.create_knowledge_base_template()
    
    def create_knowledge_base_template(self):
        """Create the initial markdown knowledge base"""
        template = """# 📸 Screenshot Knowledge Base

## 🎯 VPN Deployment Sessions

*Auto-generated from screenshot analysis*

### Current Session: {date}

| Time | Data Extracted | Screenshot Source | Details |
|------|----------------|-------------------|---------|

---

### Historical Data

Search this document for:
- **IP addresses**: Use Ctrl+F to find specific IPs
- **Status information**: Look for "Active", "Connected", "Failed"
- **Error messages**: Search for "Error", "Failed", "Timeout"
- **Performance data**: Look for latency, packet loss, transfer rates

### Usage
1. Screenshots are automatically processed when added to the `screenshots/` folder
2. Data is extracted and added to this knowledge base
3. Original screenshots are linked for verification
4. Use this data to enhance AI handoff documents

---

*Last updated: {timestamp}*
""".format(date=datetime.now().strftime('%Y-%m-%d'), timestamp=datetime.now().isoformat())

        self.knowledge_file.write_text(template)
        print(f"✅ Created knowledge base: {self.knowledge_file}")
    
    def add_entry(self, extracted_data: Dict, image_path: str, kb_format: str):
        """Add new entry to knowledge base"""
        try:
            # Load existing data
            data_entries = self.load_data()
            
            # Create new entry
            entry = {
                'id': len(data_entries) + 1,
                'timestamp': datetime.now().isoformat(),
                'image_path': image_path,
                'screenshot_type': extracted_data.get('screenshot_type', 'unknown'),
                'extracted_fields': extracted_data.get('extracted_fields', {}),
                'confidence': extracted_data.get('confidence', 0),
                'kb_format': kb_format
            }
            
            # Add to data store
            data_entries.append(entry)
            self.save_data(data_entries)
            
            # Update markdown knowledge base
            self.update_markdown_kb(kb_format)
            
            print(f"✅ Added entry to knowledge base: {extracted_data['screenshot_type']}")
            return entry['id']
            
        except Exception as e:
            print(f"❌ Error adding entry: {e}")
            return None
    
    def load_data(self) -> List[Dict]:
        """Load JSON data file"""
        if self.data_file.exists():
            try:
                return json.loads(self.data_file.read_text())
            except:
                return []
        return []
    
    def save_data(self, data: List[Dict]):
        """Save JSON data file"""
        self.data_file.write_text(json.dumps(data, indent=2))
    
    def update_markdown_kb(self, new_row: str):
        """Add new row to markdown table"""
        try:
            content = self.knowledge_file.read_text()
            
            # Find the table and add new row
            lines = content.split('\n')
            table_found = False
            
            for i, line in enumerate(lines):
                if '|------|' in line:  # Table header separator
                    # Insert new row after header
                    lines.insert(i + 1, new_row.rstrip())
                    table_found = True
                    break
            
            if table_found:
                # Update timestamp - fix duplicate timestamps issue
                updated_content = '\n'.join(lines)
                # More precise replacement to avoid duplicates
                import re
                updated_content = re.sub(
                    r'\*Last updated: [^*]*\*',
                    f'*Last updated: {datetime.now().isoformat()}*',
                    updated_content
                )
                self.knowledge_file.write_text(updated_content)
            
        except Exception as e:
            print(f"❌ Error updating markdown: {e}")
    
    def search(self, query: str) -> List[Dict]:
        """Search knowledge base for specific data"""
        data_entries = self.load_data()
        results = []
        
        query_lower = query.lower()
        
        for entry in data_entries:
            # Search in extracted fields
            for field, value in entry['extracted_fields'].items():
                if isinstance(value, str) and query_lower in value.lower():
                    results.append(entry)
                    break
                elif isinstance(value, list):
                    for item in value:
                        if isinstance(item, str) and query_lower in item.lower():
                            results.append(entry)
                            break
        
        return results
    
    def get_latest_entries(self, count: int = 10) -> List[Dict]:
        """Get most recent entries"""
        data_entries = self.load_data()
        return sorted(data_entries, key=lambda x: x['timestamp'], reverse=True)[:count]
    
    def generate_summary(self) -> Dict:
        """Generate summary statistics"""
        data_entries = self.load_data()
        
        if not data_entries:
            return {'total_entries': 0}
        
        # Count by screenshot type
        type_counts = {}
        for entry in data_entries:
            screenshot_type = entry['screenshot_type']
            type_counts[screenshot_type] = type_counts.get(screenshot_type, 0) + 1
        
        # Get date range
        timestamps = [entry['timestamp'] for entry in data_entries]
        
        return {
            'total_entries': len(data_entries),
            'screenshot_types': type_counts,
            'first_entry': min(timestamps),
            'last_entry': max(timestamps),
            'knowledge_base_file': str(self.knowledge_file),
            'data_file': str(self.data_file)
        }


def test_knowledge_base():
    """Test knowledge base functionality"""
    print("=========================")
    
    kb = KnowledgeBase("test_screenshots")
    
    # Test data
    sample_data = {
        'screenshot_type': 'wireguard_status',
        'extracted_fields': {
            'status': 'Active',
            'endpoint': '184.105.7.112:51820',
            'data_sent': '1.01 KiB'
        },
        'confidence': 95
    }
    
    sample_kb_format = "| 14:32:15 | WireGuard: Active | [test.png](test.png) | Endpoint: 184.105.7.112:51820 |\n"
    
    # Add entry
    entry_id = kb.add_entry(sample_data, "test.png", sample_kb_format)
    print(f"✅ Added entry with ID: {entry_id}")
    
    # Test search
    results = kb.search("184.105.7.112")
    print(f"✅ Search results: {len(results)} found")
    
    # Generate summary
    summary = kb.generate_summary()
    print(f"✅ Summary: {summary['total_entries']} total entries")
    
    print(f"📁 Knowledge base created at: {kb.knowledge_file}")


if __name__ == "__main__":
    test_knowledge_base()
