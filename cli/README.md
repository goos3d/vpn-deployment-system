# CLI Tools Directory
**Purpose:** Command-line tools for WireGuard VPN client generation and management

## 📁 **Planned CLI Scripts**

### **Core Generation Tools**
- `generate_client.py` - Single client configuration generator
- `batch_operations.py` - Multi-client bulk generation  
- `delivery_package.py` - Complete client package creation
- `management_tools.py` - Client lifecycle management

### **Business Tools**
- `dr_kover_delivery.py` - Dr. Kover project delivery ($200)
- `healthcare_templates.py` - HIPAA-compliant configurations
- `service_tiers.py` - Service tier automation ($500/$1500/$5000)

### **Utility Scripts**
- `test_cli_tools.py` - CLI tool testing and validation
- `setup_environment.py` - Environment setup and validation

## 🎯 **Development Status**
All CLI tools will be built using the proven working core modules:
- `src/core/client_config.py` (UTF-8 encoding fix)
- `src/core/keys.py` (key generation)
- `src/core/network.py` (IP allocation)

**Next:** Create `generate_client.py` for Dr. Kover project delivery
