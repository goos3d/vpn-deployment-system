# WireGuard Server Setup for Windows VM (184.105.7.112)

## Files to Copy to Windows Server:
1. `wg0.conf` - Server configuration
2. `setup-windows-server.ps1` - Automated setup script

## Installation Steps:

### Step 1: Download & Install WireGuard
- Go to: https://www.wireguard.com/install/
- Download "WireGuard for Windows"
- Install on the Windows server

### Step 2: Copy Files
- Copy both `wg0.conf` and `setup-windows-server.ps1` to the Windows server
- Place them in the same folder (e.g., Desktop)

### Step 3: Run Setup Script
- Right-click on PowerShell → "Run as Administrator"
- Navigate to the folder with the files
- Run: `.\setup-windows-server.ps1`

### Step 4: Start WireGuard Server
- Open WireGuard app
- Click "Add Tunnel" → "Add from file"
- Select: `C:\Program Files\WireGuard\Data\Configurations\wg0.conf`
- Click "Activate"

## Firewall Requirements:
- **Port 51820 UDP** must be open on:
  - Windows Firewall (script handles this)
  - Cloud provider firewall/security groups
  - Router firewall if applicable

## Network Configuration:
- **Server IP**: 10.0.0.1/24
- **Client IP**: 10.0.0.2/32
- **Listen Port**: 51820

## Troubleshooting:
If the VPN doesn't work, check:
1. WireGuard service is running on Windows
2. Port 51820 is open in cloud provider security groups
3. Windows Firewall allows WireGuard
4. Client configuration matches server settings

## Testing:
Once server is running, test from MacBook:
1. Activate WireGuard tunnel on MacBook
2. Try to ping: `ping 10.0.0.1`
3. Check WireGuard status shows data transfer
