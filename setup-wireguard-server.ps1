# WireGuard VPS Server Setup Script for Windows 11 Pro
# Run this script in PowerShell as Administrator on the VPS

Write-Host "=== WireGuard Server Setup for OptimalSmile VPS ===" -ForegroundColor Green
Write-Host "HIPAA-compliant VPN configuration for dental practice" -ForegroundColor Yellow

# Step 1: Download and install WireGuard
Write-Host "`n1. Downloading WireGuard for Windows..." -ForegroundColor Cyan
$downloadUrl = "https://download.wireguard.com/windows-client/wireguard-installer.exe"
$installerPath = "$env:TEMP\wireguard-installer.exe"

Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath
Write-Host "   Downloaded to: $installerPath" -ForegroundColor Gray

Write-Host "`n2. Installing WireGuard (silent install)..." -ForegroundColor Cyan
Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
Write-Host "   WireGuard installed successfully!" -ForegroundColor Green

# Step 2: Generate server and client key pairs
Write-Host "`n3. Generating cryptographic keys..." -ForegroundColor Cyan
$wgPath = "${env:ProgramFiles}\WireGuard\wg.exe"

# Generate server keys
$serverPrivateKey = & $wgPath genkey
$serverPublicKey = $serverPrivateKey | & $wgPath pubkey

# Generate client keys  
$clientPrivateKey = & $wgPath genkey
$clientPublicKey = $clientPrivateKey | & $wgPath pubkey

Write-Host "   Server Private Key: $serverPrivateKey" -ForegroundColor Gray
Write-Host "   Server Public Key:  $serverPublicKey" -ForegroundColor Gray
Write-Host "   Client Private Key: $clientPrivateKey" -ForegroundColor Gray
Write-Host "   Client Public Key:  $clientPublicKey" -ForegroundColor Gray

# Step 3: Create server configuration
Write-Host "`n4. Creating server configuration..." -ForegroundColor Cyan
$configDir = "C:\ProgramData\WireGuard"
if (!(Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force
}

$serverConfig = @"
# WireGuard Server Configuration for OptimalSmile VPS
# HIPAA-compliant configuration for dental practice

[Interface]
PrivateKey = $serverPrivateKey
Address = 10.8.0.1/24
ListenPort = 51820
DNS = 1.1.1.1, 1.0.0.1
PostUp = netsh interface ipv4 set global forwarding=enabled
PostUp = netsh advfirewall firewall add rule name="WireGuard-In" dir=in action=allow protocol=UDP localport=51820
PostUp = netsh advfirewall firewall add rule name="WireGuard-Forward" dir=in action=allow protocol=any localip=10.8.0.0/24
PostDown = netsh advfirewall firewall delete rule name="WireGuard-In"
PostDown = netsh advfirewall firewall delete rule name="WireGuard-Forward"

[Peer]
PublicKey = $clientPublicKey
AllowedIPs = 10.8.0.2/32
PersistentKeepalive = 25
"@

$serverConfigPath = "$configDir\wg0.conf"
$serverConfig | Out-File -FilePath $serverConfigPath -Encoding UTF8
Write-Host "   Server config saved to: $serverConfigPath" -ForegroundColor Green

# Step 4: Create client configuration
Write-Host "`n5. Creating client configuration..." -ForegroundColor Cyan
$clientConfig = @"
# WireGuard Client Configuration for Dental Office
# HIPAA-compliant client settings

[Interface]
PrivateKey = $clientPrivateKey
Address = 10.8.0.2/24
DNS = 1.1.1.1, 1.0.0.1

[Peer]
PublicKey = $serverPublicKey
Endpoint = 184.105.7.112:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
"@

$clientConfigPath = "$configDir\client-dental-office.conf"
$clientConfig | Out-File -FilePath $clientConfigPath -Encoding UTF8
Write-Host "   Client config saved to: $clientConfigPath" -ForegroundColor Green

# Step 5: Configure Windows Firewall
Write-Host "`n6. Configuring Windows Firewall..." -ForegroundColor Cyan
netsh advfirewall firewall add rule name="WireGuard-UDP-51820" dir=in action=allow protocol=UDP localport=51820
netsh advfirewall firewall add rule name="WireGuard-VPN-Traffic" dir=in action=allow protocol=any localip=10.8.0.0/24
Write-Host "   Firewall rules added successfully!" -ForegroundColor Green

# Step 6: Enable IP forwarding
Write-Host "`n7. Enabling IP forwarding..." -ForegroundColor Cyan
netsh interface ipv4 set global forwarding=enabled
Write-Host "   IP forwarding enabled!" -ForegroundColor Green

# Step 7: Start WireGuard tunnel
Write-Host "`n8. Starting WireGuard tunnel..." -ForegroundColor Cyan
& "${env:ProgramFiles}\WireGuard\wireguard.exe" /installtunnelservice "$serverConfigPath"
Write-Host "   WireGuard tunnel service installed and started!" -ForegroundColor Green

Write-Host "`n=== Setup Complete! ===" -ForegroundColor Green
Write-Host "Server is now running on 184.105.7.112:51820" -ForegroundColor Yellow
Write-Host "Client configuration file: $clientConfigPath" -ForegroundColor Yellow
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Copy the client config file to the dental office laptop" -ForegroundColor White
Write-Host "2. Install WireGuard on the client machine" -ForegroundColor White
Write-Host "3. Import the client configuration" -ForegroundColor White
Write-Host "4. Test the connection" -ForegroundColor White

# Display key information for manual configuration if needed
Write-Host "`n=== Key Information ===" -ForegroundColor Magenta
Write-Host "Server Public Key: $serverPublicKey" -ForegroundColor White
Write-Host "Client Public Key: $clientPublicKey" -ForegroundColor White
Write-Host "VPN Server IP: 10.8.0.1" -ForegroundColor White
Write-Host "Client VPN IP: 10.8.0.2" -ForegroundColor White
