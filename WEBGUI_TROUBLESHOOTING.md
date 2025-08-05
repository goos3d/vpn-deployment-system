# 🔧 Web GUI Troubleshooting Guide

## Common Errors and Solutions

### 1. **Server Key Missing Error**
**Error**: "Server public key not found" or key-related errors
**Solution**:
```bash
# Generate server keys if missing
python vpn.py keygen --server
```

### 2. **Import/Module Errors**
**Error**: "ModuleNotFoundError" or import issues
**Solution**:
```bash
# Install missing dependencies
pip install flask jinja2 qrcode pillow click
```

### 3. **Directory/Path Errors**
**Error**: "Directory not found" or path issues
**Solution**:
```bash
# Create required directories
mkdir wireguard-keys
mkdir clients
```

### 4. **Permission Errors**
**Error**: "Permission denied" when creating files
**Solution**:
- Run as administrator
- Check folder permissions

### 5. **Port Already in Use**
**Error**: "Address already in use" on port 5000
**Solution**:
```bash
# Use different port
python start_web_gui.py --port=5001
```

### 6. **Template/HTML Errors**
**Error**: Template not found or rendering issues
**Solution**:
- Check if src/web/templates directory exists
- Verify Flask template files are present

## 🚀 Quick Fix Command
If you're getting errors, try this comprehensive fix:

```bash
# Navigate to project directory
cd C:\Users\Administrator\vpn-deployment-system

# Create required directories
mkdir -p wireguard-keys clients

# Install all dependencies
pip install flask jinja2 qrcode pillow click

# Generate server keys if missing
python vpn.py keygen --server

# Start web GUI
python start_web_gui.py
```

## 📋 Error Reporting Template
Please share:
1. **Exact error message**
2. **When it occurred** (startup, user creation, etc.)
3. **Browser console errors** (if any)

This will help me provide a specific solution!
