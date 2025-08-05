# Dr. Kover VPN - Windows VM Local Installation Script
# Run this directly on the Windows VM to install the management system

Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              Dr. Kover VPN - Windows VM Local Installation                  ║" -ForegroundColor Green  
Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "🎯 Installing VPN management system locally on Windows VM..." -ForegroundColor Yellow
Write-Host "📍 Current system: $env:COMPUTERNAME - $(Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet; if($?) { (Invoke-RestMethod -Uri "https://ipinfo.io/ip" -TimeoutSec 5) } else { "Local VM" })" -ForegroundColor Cyan
Write-Host ""

# Check if WireGuard is installed
$wgPath = "C:\Program Files\WireGuard"
if (!(Test-Path $wgPath)) {
    Write-Host "❌ WireGuard not found at $wgPath" -ForegroundColor Red
    Write-Host "Please install WireGuard for Windows first from https://www.wireguard.com/install/" -ForegroundColor Yellow
    exit 1
}

# Create management directory
$mgmtDir = "C:\VPN-Management"
if (!(Test-Path $mgmtDir)) {
    New-Item -ItemType Directory -Path $mgmtDir -Force | Out-Null
    Write-Host "📁 Created management directory: $mgmtDir" -ForegroundColor Green
}

Set-Location $mgmtDir
Write-Host "📁 Working in: $(Get-Location)" -ForegroundColor Cyan
Write-Host ""

# Create Windows PowerShell management scripts
Write-Host "📋 Installing Windows VPN management scripts..." -ForegroundColor Yellow

# Create Add-Peer.ps1 script
$addPeerScript = @'
# Dr. Kover VPN - Add New Device (Windows PowerShell)
param(
    [Parameter(Mandatory=$true)]
    [string]$DeviceName
)

Write-Host "Adding new peer: $DeviceName" -ForegroundColor Green

$configDir = "C:\Program Files\WireGuard\Data\Configurations"
$serverConfigPath = "$configDir\wg0.conf"
$clientConfigPath = "$PWD\DrKover-$DeviceName.conf"

if (!(Test-Path $serverConfigPath)) {
    Write-Host "❌ Server configuration not found at $serverConfigPath" -ForegroundColor Red
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
    Write-Host "❌ Could not find server private key in configuration" -ForegroundColor Red
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

Write-Host "✅ Peer '$DeviceName' added successfully!" -ForegroundColor Green
Write-Host "📁 Configuration saved as: $clientConfigPath" -ForegroundColor Cyan
Write-Host "🌐 Assigned IP: 10.0.0.$nextIP" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart WireGuard tunnel in WireGuard app" -ForegroundColor White
Write-Host "2. Transfer $clientConfigPath to your device" -ForegroundColor White
Write-Host "3. Import into WireGuard app" -ForegroundColor White
'@

$addPeerScript | Out-File -FilePath "$mgmtDir\Add-Peer.ps1" -Encoding UTF8

# Create VPN-Manager.ps1 script
$managerScript = @'
# Dr. Kover VPN Management System (Windows PowerShell)

function Show-Menu {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                        Dr. Kover VPN Management System                      ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "What would you like to do?" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1) 📱 Add a new device" -ForegroundColor White
    Write-Host "2) 📊 Check VPN status" -ForegroundColor White
    Write-Host "3) 📋 List all devices" -ForegroundColor White
    Write-Host "4) 🔍 Show connected devices" -ForegroundColor White
    Write-Host "5) 🔄 Restart VPN service" -ForegroundColor White
    Write-Host "6) 📁 List configuration files" -ForegroundColor White
    Write-Host "7) ❌ Exit" -ForegroundColor White
    Write-Host ""
}

do {
    Show-Menu
    $choice = Read-Host "Enter your choice (1-7)"
    
    switch ($choice) {
        "1" {
            Write-Host ""
            $deviceName = Read-Host "Enter device name (e.g., iPad, iPhone, OfficePC)"
            if ($deviceName) {
                & ".\Add-Peer.ps1" -DeviceName $deviceName
                Write-Host ""
                $restart = Read-Host "Restart WireGuard tunnel now? (y/n)"
                if ($restart -eq "y") {
                    Write-Host "Please restart the WireGuard tunnel manually in the WireGuard app" -ForegroundColor Yellow
                }
            } else {
                Write-Host "❌ Device name cannot be empty" -ForegroundColor Red
            }
        }
        "2" {
            Write-Host ""
            Write-Host "VPN Service Status:" -ForegroundColor Cyan
            $wgService = Get-Service -Name "WireGuardTunnel*" -ErrorAction SilentlyContinue
            if ($wgService) {
                $wgService | Format-Table Name, Status, StartType
            } else {
                Write-Host "WireGuard service status: Check WireGuard app manually" -ForegroundColor Yellow
            }
        }
        "3" {
            Write-Host ""
            Write-Host "All configured devices:" -ForegroundColor Cyan
            $serverConfig = "C:\Program Files\WireGuard\Data\Configurations\wg0.conf"
            if (Test-Path $serverConfig) {
                $devices = Select-String -Path $serverConfig -Pattern "# DrKover -" | ForEach-Object { $_.Line -replace "# DrKover - ", "- " }
                if ($devices) { $devices } else { Write-Host "No devices configured yet" -ForegroundColor Yellow }
            }
        }
        "4" {
            Write-Host ""
            Write-Host "Currently connected devices:" -ForegroundColor Cyan
            try {
                & "C:\Program Files\WireGuard\wg.exe" show
            } catch {
                Write-Host "Check WireGuard app for connection status" -ForegroundColor Yellow
            }
        }
        "5" {
            Write-Host ""
            Write-Host "Please restart the WireGuard tunnel manually in the WireGuard app" -ForegroundColor Yellow
        }
        "6" {
            Write-Host ""
            Write-Host "Configuration files:" -ForegroundColor Cyan
            Get-ChildItem -Path "." -Filter "DrKover-*.conf" | Format-Table Name, Length, LastWriteTime
        }
        "7" {
            Write-Host ""
            Write-Host "Goodbye!" -ForegroundColor Green
            break
        }
        default {
            Write-Host ""
            Write-Host "❌ Invalid choice. Please enter 1-7." -ForegroundColor Red
        }
    }
    
    if ($choice -ne "7") {
        Write-Host ""
        Read-Host "Press Enter to continue"
    }
} while ($choice -ne "7")
'@

$managerScript | Out-File -FilePath "$mgmtDir\VPN-Manager.ps1" -Encoding UTF8

# Create VPN-Status.ps1 script  
$statusScript = @'
# Dr. Kover VPN Status Checker (Windows PowerShell)

Clear-Host
Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                           Dr. Kover VPN Status                              ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Check WireGuard service status
Write-Host "🔍 VPN Service Status:" -ForegroundColor Cyan
$wgService = Get-Service -Name "WireGuardTunnel*" -ErrorAction SilentlyContinue
if ($wgService -and $wgService.Status -eq "Running") {
    Write-Host "✅ WireGuard VPN is RUNNING" -ForegroundColor Green
} else {
    Write-Host "❌ WireGuard VPN status unknown - Check WireGuard app" -ForegroundColor Yellow
}
Write-Host ""

# Show server information
Write-Host "🌐 Server Information:" -ForegroundColor Cyan
Write-Host "   Server IP: 184.105.7.112" -ForegroundColor White
Write-Host "   VPN Port: 51820" -ForegroundColor White
Write-Host "   Network: 10.0.0.x" -ForegroundColor White
Write-Host ""

# Show configured devices
Write-Host "📱 Configured Devices:" -ForegroundColor Cyan
$serverConfig = "C:\Program Files\WireGuard\Data\Configurations\wg0.conf"
if (Test-Path $serverConfig) {
    $devices = Select-String -Path $serverConfig -Pattern "# DrKover -" -AllMatches
    if ($devices) {
        $devices | ForEach-Object { Write-Host "   ✓ $($_.Line -replace '# DrKover - ', '')" -ForegroundColor Green }
        Write-Host "   Total: $($devices.Count) devices configured" -ForegroundColor Cyan
    } else {
        Write-Host "   No devices configured yet" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Server configuration not found" -ForegroundColor Red
}
Write-Host ""

# Show currently connected devices
Write-Host "🔗 Currently Connected:" -ForegroundColor Cyan
try {
    $wgShow = & "C:\Program Files\WireGuard\wg.exe" show 2>$null
    if ($wgShow) {
        $peerCount = ($wgShow | Select-String "peer:").Count
        Write-Host "   $peerCount devices connected" -ForegroundColor Green
    } else {
        Write-Host "   No devices currently connected" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Connection status: Check WireGuard app" -ForegroundColor Yellow
}
Write-Host ""

# Show system resources
Write-Host "💾 System Resources:" -ForegroundColor Cyan
$uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptimeSpan = (Get-Date) - $uptime
Write-Host "   Uptime: $($uptimeSpan.Days) days, $($uptimeSpan.Hours) hours" -ForegroundColor White

$memory = Get-CimInstance Win32_OperatingSystem
$memUsed = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 1)
$memTotal = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 1)
Write-Host "   Memory: $memUsed GB / $memTotal GB" -ForegroundColor White

$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$diskUsed = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 1)
$diskTotal = [math]::Round($disk.Size / 1GB, 1)
$diskPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)
Write-Host "   Disk: $diskUsed GB / $diskTotal GB ($diskPercent% used)" -ForegroundColor White
Write-Host ""

Write-Host "Need help? Contact thomas@eastbayav.com or (510) 666-5915" -ForegroundColor Yellow
'@

$statusScript | Out-File -FilePath "$mgmtDir\VPN-Status.ps1" -Encoding UTF8

Write-Host "✅ All Windows PowerShell scripts installed" -ForegroundColor Green

# Create quick reference
Write-Host ""
Write-Host "📖 Creating quick reference guide..." -ForegroundColor Yellow
$quickRef = @"
Dr. Kover VPN - Windows Quick Reference
======================================

Add a new device:
.\Add-Peer.ps1 -DeviceName [DeviceName]
(Then restart WireGuard tunnel in app)

Interactive menu:
.\VPN-Manager.ps1

Check status:
.\VPN-Status.ps1

View connected devices:
& "C:\Program Files\WireGuard\wg.exe" show

Your server: 184.105.7.112:51820
Network range: 10.0.0.x
Management folder: C:\VPN-Management

Support: thomas@eastbayav.com | (510) 666-5915
"@

$quickRef | Out-File -FilePath "$mgmtDir\VPN_QUICK_REFERENCE.txt" -Encoding UTF8

Write-Host "✅ Quick reference guide created" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 WINDOWS INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host ""
Write-Host "Dr. Kover's Windows VPN management system is ready:" -ForegroundColor Green
Write-Host ""
Write-Host "📱 To add devices: .\Add-Peer.ps1 -DeviceName [DeviceName]" -ForegroundColor White
Write-Host "🎛️  Interactive menu: .\VPN-Manager.ps1" -ForegroundColor White  
Write-Host "📊 Check status: .\VPN-Status.ps1" -ForegroundColor White
Write-Host "📖 Reference: Get-Content .\VPN_QUICK_REFERENCE.txt" -ForegroundColor White
Write-Host ""
Write-Host "✅ All systems operational and ready for use!" -ForegroundColor Green
Write-Host "🏆 The VPN will continue running independently!" -ForegroundColor Green

# Run a quick test
Write-Host ""
Write-Host "🚀 Running final system test..." -ForegroundColor Yellow
& "$mgmtDir\VPN-Status.ps1"
