# 📋 Windows VPS Quick Reference

## Server Details
- **IP:** `184.105.7.112`
- **Hostname:** `optimasmile`
- **OS:** Windows 11 Pro x64
- **Access:** RDP (admin credentials)

## VPN Configuration
- **Recommended:** WireGuard (simpler) or OpenVPN (more features)
- **Port:** 51820 (WireGuard) or 1194 (OpenVPN)
- **Protocol:** UDP preferred for performance
- **Encryption:** AES-256 minimum

## Windows Firewall Rules
```powershell
# For WireGuard
New-NetFirewallRule -DisplayName "WireGuard" -Direction Inbound -Port 51820 -Protocol UDP -Action Allow

# For OpenVPN  
New-NetFirewallRule -DisplayName "OpenVPN" -Direction Inbound -Port 1194 -Protocol UDP -Action Allow
```

## Network Configuration
- **VPN Subnet:** 10.0.0.0/24 (or 192.168.100.0/24)
- **Server IP:** 10.0.0.1 (VPN internal)
- **DNS:** 1.1.1.1, 8.8.8.8 (Cloudflare, Google)
- **Route:** All traffic (0.0.0.0/0)

## Client Requirements
- **OS:** Windows 10/11, macOS, iOS, Android
- **Software:** WireGuard client or OpenVPN Connect
- **Configuration:** Import provided .conf or .ovpn file

## Testing Commands
```cmd
# Check VPN service status
sc query "WireGuardTunnel$wg0"

# Test connectivity
ping 10.0.0.1

# Check public IP (should show VPS IP when connected)
curl ifconfig.me
```

## HIPAA Considerations
- ✅ Strong encryption (AES-256 or ChaCha20)
- ✅ No connection logging
- ✅ DNS leak protection  
- ✅ IPv6 disabled
- ✅ Kill switch enabled
- ✅ Certificate-based auth (recommended)

## Deliverables Checklist
- [ ] Server configuration file
- [ ] Client configuration file
- [ ] Windows installation script
- [ ] Firewall configuration
- [ ] Testing procedures
- [ ] Client setup guide
- [ ] Troubleshooting guide

---
**Project:** Dr. Jeff Kover - Dental Practice VPN  
**Contract:** $375 via Thumbtack  
**Timeline:** Setup and testing complete
