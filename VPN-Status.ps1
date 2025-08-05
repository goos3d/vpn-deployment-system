# Dr. Kover VPN Status Checker (Windows PowerShell)

Clear-Host
Write-Host "Dr. Kover VPN Status" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green
Write-Host ""

# Check WireGuard service status
Write-Host "VPN Service Status:" -ForegroundColor Cyan
$wgService = Get-Service -Name "WireGuardTunnel*" -ErrorAction SilentlyContinue
if ($wgService -and $wgService.Status -eq "Running") {
    Write-Host "  WireGuard VPN is RUNNING" -ForegroundColor Green
} else {
    Write-Host "  WireGuard VPN status unknown - Check WireGuard app" -ForegroundColor Yellow
}
Write-Host ""

# Show server information
Write-Host "Server Information:" -ForegroundColor Cyan
Write-Host "  Server IP: 184.105.7.112" -ForegroundColor White
Write-Host "  VPN Port: 51820" -ForegroundColor White
Write-Host "  Network: 10.0.0.x" -ForegroundColor White
Write-Host ""

# Show configured devices
Write-Host "Configured Devices:" -ForegroundColor Cyan
$serverConfig = "C:\Program Files\WireGuard\Configurations\server.conf"
if (Test-Path $serverConfig) {
    $devices = Select-String -Path $serverConfig -Pattern "# DrKover -" -AllMatches
    if ($devices) {
        $devices | ForEach-Object { Write-Host "  + $($_.Line -replace '# DrKover - ', '')" -ForegroundColor Green }
        Write-Host "  Total: $($devices.Count) devices configured" -ForegroundColor Cyan
    } else {
        Write-Host "  No devices configured yet" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Server configuration not found" -ForegroundColor Red
}
Write-Host ""

# Show currently connected devices
Write-Host "Currently Connected:" -ForegroundColor Cyan
try {
    $wgShow = & "C:\Program Files\WireGuard\wg.exe" show 2>$null
    if ($wgShow) {
        $peerCount = ($wgShow | Select-String "peer:").Count
        Write-Host "  $peerCount devices connected" -ForegroundColor Green
        $wgShow | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
    } else {
        Write-Host "  No devices currently connected" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Connection status: Check WireGuard app" -ForegroundColor Yellow
}
Write-Host ""

# Show system resources
Write-Host "System Resources:" -ForegroundColor Cyan
$uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptimeSpan = (Get-Date) - $uptime
Write-Host "  Uptime: $($uptimeSpan.Days) days, $($uptimeSpan.Hours) hours" -ForegroundColor White

$memory = Get-CimInstance Win32_OperatingSystem
$memUsed = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 1)
$memTotal = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 1)
Write-Host "  Memory: $memUsed GB / $memTotal GB" -ForegroundColor White

$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$diskUsed = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 1)
$diskTotal = [math]::Round($disk.Size / 1GB, 1)  
$diskPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)
Write-Host "  Disk: $diskUsed GB / $diskTotal GB ($diskPercent% used)" -ForegroundColor White
Write-Host ""

Write-Host "Need help? Contact thomas@eastbayav.com or (510) 666-5915" -ForegroundColor Yellow
