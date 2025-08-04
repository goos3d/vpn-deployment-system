@echo off
REM Enable NAT for WireGuard VPN
echo Configuring NAT for WireGuard VPN traffic...

REM Delete existing routes if they exist
route delete 0.0.0.0 mask 0.0.0.0 10.0.0.1 >nul 2>&1

REM Add route for VPN traffic to go through default gateway
for /f "tokens=3" %%i in ('route print 0.0.0.0 ^| findstr "0.0.0.0.*0.0.0.0"') do set GATEWAY=%%i
echo Default Gateway: %GATEWAY%

REM Configure routing for VPN clients
netsh interface ipv4 set interface "server" forwarding=enabled
netsh interface ipv4 set interface "Ethernet" forwarding=enabled

REM Add specific routes for internet access through VPN
netsh interface ipv4 add route 0.0.0.0/1 "server" %GATEWAY% metric=1
netsh interface ipv4 add route 128.0.0.0/1 "server" %GATEWAY% metric=1

echo NAT configuration complete!
echo VPN clients should now have internet access through the server.
