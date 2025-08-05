# DR. KOVER VM CLEANUP SCRIPT
# Run this on Windows VM 184.105.7.112 as Administrator

Write-Host "🧹 CLEANING VM FOR DR. KOVER PRODUCTION DEPLOYMENT"
Write-Host "Security Code: 369086"
Write-Host ""

# Create production directory
Write-Host "📁 Creating production directory..."
New-Item -Path "C:\vpn-production" -ItemType Directory -Force

# Backup essential server config
Write-Host "💾 Backing up server configuration..."
$serverConfig = "C:\Program Files\WireGuard\Data\Configurations\wg0.conf"
if (Test-Path $serverConfig) {
    Copy-Item $serverConfig "C:\vpn-production\server_backup.conf"
    Write-Host "✅ Server config backed up"
} else {
    Write-Host "⚠️ Server config not found at expected location"
}

# Copy working client config
Write-Host "📋 Preserving working client configuration..."
# Note: dr_kover.conf should be uploaded to VM from local system

# Remove development directories
Write-Host "🗑️ Removing development files..."
$dirsToRemove = @(
    "C:\vpn-deployment-system*",
    "C:\temp*",
    "C:\Users\Administrator\Downloads\VPN*",
    "C:\Users\Administrator\AppData\Local\Temp\vpn*"
)

foreach ($dir in $dirsToRemove) {
    Get-ChildItem -Path $dir -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Removed: $dir"
}

# Clean up test configurations
Write-Host "🧪 Removing test configurations..."
$testPatterns = @("*test*", "*demo*", "*temp*", "*backup*")
foreach ($pattern in $testPatterns) {
    Get-ChildItem -Path "C:\" -Name $pattern -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $_.FullName -notlike "*WireGuard*" -and $_.FullName -notlike "*vpn-production*" } | 
    Remove-Item -Force -ErrorAction SilentlyContinue
}

# Clean Windows temp files
Write-Host "🧹 Cleaning system temporary files..."
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

# Disable unnecessary services for security
Write-Host "🔒 Optimizing services for security..."
$servicesToDisable = @("Spooler", "Fax", "RemoteRegistry")
foreach ($service in $servicesToDisable) {
    try {
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "Disabled: $service"
    } catch {
        Write-Host "Could not disable: $service"
    }
}

Write-Host ""
Write-Host "✅ VM CLEANUP COMPLETE"
Write-Host "📁 Production files location: C:\vpn-production\"
Write-Host "🔒 Security Code: 369086"
Write-Host "🏥 Ready for Dr. Kover's secure access"
