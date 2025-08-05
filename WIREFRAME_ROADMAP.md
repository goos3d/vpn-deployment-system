# 🔧 VPN DEPLOYMENT - STRIPPED WIREFRAME ROADMAP
**Date:** August 4, 2025  
**Focus:** Core Working Functions Only - No Bloat  
**Branch:** revert-to-CLI

## ✅ **VERIFIED WORKING COMPONENTS**
These are the ONLY components we trust and will build on:

### **Core Engine (TESTED ✅)**
- `src/core/client_config.py` - Generates clean UTF-8 configs (BOM fix working)
- `src/core/keys.py` - WireGuard key generation (working)
- Server: 184.105.7.112:51820 (operational)
- Network: 10.0.0.0/24 (working IP allocation)

### **Proven CLI Command (WORKING ✅)**
```bash
python -c "
import sys; sys.path.insert(0, 'src')
from src.core.client_config import ClientConfigGenerator
from src.core.keys import WireGuardKeyManager
# ... generates clean configs
"
```

## 🎯 **MINIMAL VIABLE AUTOMATION**

### **Phase 1: Basic User Addition (24-48 hours)**
**Goal:** Dr. Kover can add 1 client with 1 command

#### Core Script: `cli/add_client.py`
```
Input: Client name
Output: Clean .conf file + QR code
Function: Wrap the working CLI command
```

#### Required Features ONLY:
- Generate client private/public keys
- Assign next available IP (10.0.0.2, 10.0.0.3, etc.)
- Create clean .conf file (UTF-8, no BOM)
- Generate QR code PNG
- Save to `clients/{client_name}/` folder

#### NO fancy features:
- No web interface
- No database
- No user management
- No revocation
- No monitoring

### **Phase 2: Batch Addition (1 week)**
**Goal:** Add multiple clients from a simple list

#### Script: `cli/add_batch.py`
```
Input: Text file with client names (one per line)
Output: Folder per client with configs
Function: Loop the add_client script
```

### **Phase 3: Server Config Update (1 week)**
**Goal:** Auto-update server with new peers

#### Script: `cli/update_server.py`
```
Input: None (reads existing client folders)
Output: Updated server config with all peers
Function: Generate [Peer] sections for server
```

## 🚫 **STRIPPED OUT (REMOVED)**
All of this is gone - too complex, doesn't work, or unnecessary:

- ❌ Web GUI dashboard
- ❌ Flask application
- ❌ Background jobs
- ❌ User authentication
- ❌ Database systems
- ❌ API endpoints
- ❌ Monitoring dashboards
- ❌ Service tiers
- ❌ HIPAA documentation (client can handle their own compliance)
- ❌ Marketing materials
- ❌ Business planning
- ❌ Revenue projections

## 📁 **MINIMAL FILE STRUCTURE**
```
vpn-deployment-system/
├── cli/
│   ├── add_client.py          # Add 1 client
│   ├── add_batch.py           # Add multiple clients
│   └── update_server.py       # Update server config
├── src/core/                  # DO NOT TOUCH - WORKING
│   ├── client_config.py       # UTF-8 clean generation ✅
│   ├── keys.py                # Key management ✅
│   └── network.py             # IP allocation ✅
├── clients/                   # Output folder
│   ├── client1/
│   │   ├── client1.conf
│   │   └── client1_qr.png
│   └── client2/
└── server/
    └── wg0.conf               # Generated server config
```

## 🎯 **IMMEDIATE TASKS**

### **Today (4 hours max)**
1. Create `cli/add_client.py` - wrap the working CLI command
2. Test with dummy client - verify clean output
3. Generate Dr. Kover's actual client config
4. Deliver to Dr. Kover with simple instructions

### **This Week**
1. Create `cli/add_batch.py` - process client list
2. Create `cli/update_server.py` - generate server peers
3. Test with 5 dummy clients
4. Document the 3 commands Dr. Kover needs

## 🧪 **TESTING REQUIREMENTS**
Before delivering anything:

1. **Test add_client.py**:
   - Generates clean .conf (no UTF-8 BOM)
   - Creates QR code PNG
   - Assigns unique IP
   - Saves to correct folder

2. **Test server connectivity**:
   - Client connects to 184.105.7.112:51820
   - Traffic routes correctly
   - No DNS leaks

3. **Test file encoding**:
   - .conf files open cleanly in WireGuard
   - No corruption artifacts
   - QR codes scan properly

## 💰 **BUSINESS MODEL (SIMPLIFIED)**
- **Dr. Kover:** $200 for working automation (3 scripts)
- **Next clients:** $300-500 for same 3 scripts
- **No service tiers, no complexity, no ongoing support**

## ⚠️ **CRITICAL SUCCESS FACTORS**
1. **Don't break what works** - core modules are off-limits
2. **Keep it simple** - 3 scripts maximum
3. **Test everything** - verify before delivery
4. **Focus on working** - not pretty, not fancy, just working

## 📋 **DELIVERY CHECKLIST**
```
[ ] add_client.py works with test client
[ ] Generated .conf file is clean (no BOM)
[ ] QR code generates and scans
[ ] Client connects to VPN server
[ ] Dr. Kover can run the script
[ ] Simple instructions written
[ ] $200 project ready for delivery
```

---
## 💡 **CORE PRINCIPLE**
*"Make it work, make it simple, deliver it fast. No bloat, no complexity, no breaking changes. Dr. Kover needs to add VPN clients - give him exactly that, nothing more."*

## 🚀 **SUCCESS DEFINITION**
Dr. Kover runs one command, gets one working VPN client config. Done.

**STATUS: FOCUSED ON ESSENTIALS** ✅
