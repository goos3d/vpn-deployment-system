"""
Screenshot Intelligence System - OCR Engine
Alpha version for extracting text from technical screenshots
"""

import pytesseract
from PIL import Image
import os
from typing import Dict, Optional
from datetime import datetime


class OCREngine:
    """Handles OCR processing of screenshots"""
    
    def __init__(self):
        self.tesseract_config = '--oem 3 --psm 6'  # Optimized for technical text
        
    def extract_text(self, image_path: str) -> str:
        """Extract raw text from screenshot"""
        try:
            if not os.path.exists(image_path):
                raise FileNotFoundError(f"Screenshot not found: {image_path}")
                
            # Open and process image
            image = Image.open(image_path)
            
            # Convert to RGB if needed (handles PNG transparency)
            if image.mode != 'RGB':
                image = image.convert('RGB')
            
            # Extract text using Tesseract
            text = pytesseract.image_to_string(image, config=self.tesseract_config)
            
            return text.strip()
            
        except Exception as e:
            print(f"❌ OCR Error: {e}")
            return ""
    
    def extract_with_confidence(self, image_path: str) -> Dict:
        """Extract text with confidence scores"""
        try:
            image = Image.open(image_path)
            if image.mode != 'RGB':
                image = image.convert('RGB')
                
            # Get detailed OCR data
            data = pytesseract.image_to_data(image, config=self.tesseract_config, output_type=pytesseract.Output.DICT)
            
            # Calculate average confidence
            confidences = [int(conf) for conf in data['conf'] if int(conf) > 0]
            avg_confidence = sum(confidences) / len(confidences) if confidences else 0
            
            # Extract text
            text = pytesseract.image_to_string(image, config=self.tesseract_config).strip()
            
            return {
                'text': text,
                'confidence': round(avg_confidence, 2),
                'word_count': len(text.split()),
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                'text': '',
                'confidence': 0,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }


def test_ocr():
    """Test OCR functionality"""
    engine = OCREngine()
    print("🔍 OCR Engine Test")
    print("==================")
    
    # Test if tesseract is available
    try:
        version = pytesseract.get_tesseract_version()
        print(f"✅ Tesseract version: {version}")
    except Exception as e:
        print(f"❌ Tesseract not found: {e}")
        print("💡 Install with: brew install tesseract (macOS)")
        return
    
    print("✅ OCR Engine ready!")


if __name__ == "__main__":
    test_ocr()
