# Dr. Kover VPN - Add New Device (Windows PowerShell)
param(
    [Parameter(Mandatory=$true)]
    [string]$DeviceName
)

Write-Host "Adding new peer: $DeviceName" -ForegroundColor Green

$configDir = "C:\Program Files\WireGuard\Configurations"
$serverConfigPath = "$configDir\server.conf"
$clientConfigPath = "C:\VPN-Management\DrKover-$DeviceName.conf"

if (!(Test-Path $serverConfigPath)) {
    Write-Host "ERROR: Server configuration not found at $serverConfigPath" -ForegroundColor Red
    exit 1
}

# Generate client keys using WireGuard
$privateKey = & "C:\Program Files\WireGuard\wg.exe" genkey
$publicKey = $privateKey | & "C:\Program Files\WireGuard\wg.exe" pubkey

# Get server public key from config
$serverConfig = Get-Content $serverConfigPath -Raw
$serverPrivateKeyMatch = [regex]::Match($serverConfig, "PrivateKey\s*=\s*(.+)")
if ($serverPrivateKeyMatch.Success) {
    $serverPrivateKey = $serverPrivateKeyMatch.Groups[1].Value.Trim()
    $serverPublicKey = $serverPrivateKey | & "C:\Program Files\WireGuard\wg.exe" pubkey
} else {
    Write-Host "ERROR: Could not find server private key in configuration" -ForegroundColor Red
    exit 1  
}

# Find next available IP
$usedIPs = [regex]::Matches($serverConfig, "AllowedIPs\s*=\s*10\.0\.0\.(\d+)") | ForEach-Object { [int]$_.Groups[1].Value }
$nextIP = if ($usedIPs) { ($usedIPs | Sort-Object)[-1] + 1 } else { 2 }

# Create client configuration
$clientConfig = @"
[Interface]
PrivateKey = $privateKey
Address = 10.0.0.$nextIP/32
DNS = 1.1.1.1, 8.8.8.8

[Peer]  
PublicKey = $serverPublicKey
AllowedIPs = 0.0.0.0/0
Endpoint = 184.105.7.112:51820
PersistentKeepalive = 25
"@

# Save client configuration
$clientConfig | Out-File -FilePath $clientConfigPath -Encoding UTF8

# Add peer to server configuration
$peerConfig = @"

# DrKover - $DeviceName
[Peer]
PublicKey = $publicKey
AllowedIPs = 10.0.0.$nextIP/32
"@

Add-Content -Path $serverConfigPath -Value $peerConfig

Write-Host "SUCCESS: Peer '$DeviceName' added successfully!" -ForegroundColor Green
Write-Host "Configuration saved as: $clientConfigPath" -ForegroundColor Cyan
Write-Host "Assigned IP: 10.0.0.$nextIP" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart WireGuard tunnel in WireGuard app" -ForegroundColor White
Write-Host "2. Transfer $clientConfigPath to your device" -ForegroundColor White
Write-Host "3. Import into WireGuard app" -ForegroundColor White
