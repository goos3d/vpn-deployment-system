# Manual WireGuard Server Setup Instructions
# For Windows 11 Pro VPS (optimasmile - 184.105.7.112)

## Step 1: Download and Install WireGuard

1. RDP into your Windows VPS (184.105.7.112)
2. Download WireGuard from: https://download.wireguard.com/windows-client/wireguard-installer.exe
3. Run the installer as Administrator
4. Complete the installation (it will install to Program Files\WireGuard)

## Step 2: Generate Cryptographic Keys

Open PowerShell as Administrator and run:

```powershell
cd "C:\Program Files\WireGuard"
$serverPrivateKey = .\wg.exe genkey
$serverPublicKey = $serverPrivateKey | .\wg.exe pubkey
$clientPrivateKey = .\wg.exe genkey  
$clientPublicKey = $clientPrivateKey | .\wg.exe pubkey

Write-Host "Server Private: $serverPrivateKey"
Write-Host "Server Public:  $serverPublicKey"
Write-Host "Client Private: $clientPrivateKey"
Write-Host "Client Public:  $clientPublicKey"
```

**IMPORTANT**: Save these keys - you'll need them for the configuration files!

## Step 3: Create Server Configuration

1. Create directory: `C:\ProgramData\WireGuard`
2. Create file: `C:\ProgramData\WireGuard\wg0.conf`
3. Copy the content from `wg0.conf` file, replacing the placeholder keys with your generated keys

## Step 4: Create Client Configuration

1. Create file: `C:\ProgramData\WireGuard\client-dental-office.conf`
2. Copy the content from `client-dental-office.conf` file, replacing the placeholder keys

## Step 5: Configure Windows Firewall

Run these commands in PowerShell as Administrator:

```powershell
# Allow WireGuard traffic
netsh advfirewall firewall add rule name="WireGuard-UDP-51820" dir=in action=allow protocol=UDP localport=51820

# Allow VPN subnet traffic
netsh advfirewall firewall add rule name="WireGuard-VPN-Traffic" dir=in action=allow protocol=any localip=10.8.0.0/24

# Enable IP forwarding
netsh interface ipv4 set global forwarding=enabled
```

## Step 6: Start WireGuard Server

1. Open WireGuard application
2. Click "Add Tunnel" → "Add from File"
3. Select your `wg0.conf` file
4. Click "Activate" to start the tunnel

OR use command line:
```powershell
cd "C:\Program Files\WireGuard"
.\wireguard.exe /installtunnelservice "C:\ProgramData\WireGuard\wg0.conf"
```

## Step 7: Verify Server is Running

Check that the tunnel is active:
```powershell
netstat -an | findstr :51820
```

You should see: `UDP    0.0.0.0:51820    *:*`

## Client Setup (Dental Office Laptop)

1. Install WireGuard on the client machine
2. Copy the `client-dental-office.conf` file to the client
3. Import the configuration in WireGuard client
4. Activate the tunnel

## Testing the Connection

After client connects, test from client machine:

```cmd
# Check VPN IP
ipconfig

# Verify external IP shows VPS IP
curl ifconfig.me

# Test DNS leak protection
nslookup google.com
```

## Troubleshooting

**If connection fails:**
1. Check Windows Firewall rules
2. Verify port 51820 is open on VPS
3. Check ServerOptima firewall/security groups
4. Verify key pairs match between server and client configs

**For HIPAA compliance:**
- No connection logs are stored by default
- All traffic is encrypted with modern cryptography
- DNS queries are protected from leaks
- IPv6 is disabled to prevent leaks
