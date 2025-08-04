#!/bin/bash
# Debug Print Statement Cleaner
# Removes debugging print statements while preserving user-facing output

echo "🧹 Cleaning debugging print statements from Screenshot Intelligence System"
echo "========================================================================"

cd "/Users/Administrator/Desktop/VPN work 8:3:25"

# Create backup before cleaning
echo "📦 Creating backup..."
cp -r src/screenshot src/screenshot.backup.$(date +%Y%m%d_%H%M%S)

# Count current debug prints
BEFORE_COUNT=$(grep -r "print(" src/screenshot/ | grep -v "print(f'" | grep -v "click.echo" | wc -l)
echo "🔍 Found $BEFORE_COUNT debugging print statements"

# Clean each file
for file in src/screenshot/*.py; do
    filename=$(basename "$file")
    echo "🧽 Cleaning $filename..."
    
    # Remove debug prints but keep user-facing prints and click.echo statements
    # This is a safe approach - only remove obvious debug prints
    sed -i '' '/^[[:space:]]*print("✅/d; /^[[:space:]]*print("❌/d; /^[[:space:]]*print("📸/d; /^[[:space:]]*print("🔍/d; /^[[:space:]]*print("📊/d; /^[[:space:]]*print("🗃️/d' "$file"
done

# Count after cleaning
AFTER_COUNT=$(grep -r "print(" src/screenshot/ | grep -v "print(f'" | grep -v "click.echo" | wc -l)
CLEANED_COUNT=$((BEFORE_COUNT - AFTER_COUNT))

echo ""
echo "✅ Cleaning complete!"
echo "📊 Results:"
echo "  - Before: $BEFORE_COUNT print statements"  
echo "  - After: $AFTER_COUNT print statements"
echo "  - Cleaned: $CLEANED_COUNT statements"
echo ""
echo "📁 Backup saved in: src/screenshot.backup.*"
echo "🧪 Run system test to verify functionality: python vpn.py screenshot test"
