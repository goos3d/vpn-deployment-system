# 🧠 Claude Handoff: VPN Setup on ServerOptima Windows VPS

Hey Claude, I need help configuring a secure, HIPAA-conscious VPN on a Windows VPS for a dental office client.

## 🔧 VPS Details

**Provider:** ServerOptima  
**Hostname:** `optimasmile`  
**IP:** `184.105.7.112`  
**OS:** `Windows 11 Pro x64`  
**Specs:** `6 vCPU, 20GB RAM, 300GB NVMe`  
**Status:** RDP & admin access working  
**Use case:** Secure access for Optima + OpenDental over VPN

## ✅ What I Need

1. **Recommend WireGuard or OpenVPN** (based on security + ease of use for Windows)
2. **Generate server config** for the Windows VPS
3. **Generate 1 client config** (for a dental office laptop)
4. **Provide setup instructions** for:
   - Installing VPN server on Windows VPS
   - Setting up the server tunnel
   - Opening Windows Firewall ports
   - Exporting client config for handoff

## 🛡️ Requirements

- **AES-256 encryption minimum**
- **Include DNS leak protection**
- **Route all traffic through the tunnel**
- **HIPAA-conscious defaults** (no logging preferred, disable IPv6)
- **Windows-friendly output** (copy/paste into Notepad or PowerShell)

## ✉️ Deliverables

- `server.conf` or `.ovpn` file
- `client.conf` or `.ovpn` file  
- Windows setup script or step-by-step instructions
- Summary README to send to client

## 📋 Context

- **Client:** Dr. Jeff Kover
- **Contract:** $375 flat-rate via Thumbtack
- **Goal:** Once VPN is working, Optima + OpenDental will only be accessible through the tunnel
- **Security Focus:** HIPAA compliance for dental practice environment

## 🎯 Success Criteria

1. VPN server running on Windows VPS
2. Client can connect securely from dental office
3. All traffic routes through VPN (verified with IP check)
4. DNS queries protected from leaks
5. Ready for dental software deployment

Keep the output Windows-friendly. Assume I'll copy/paste into Notepad or PowerShell.

---

*This is a handoff from an existing VPN deployment system project - focus on the Windows-specific implementation for this ServerOptima VPS.*
