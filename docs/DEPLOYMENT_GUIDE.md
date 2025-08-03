# 🛠️ VPN Deployment System - Complete Guide

## 📋 Table of Contents
- [Project Overview](#project-overview)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Server Setup](#server-setup)
- [Client Management](#client-management)
- [Web Dashboard](#web-dashboard)
- [Testing & Debugging](#testing--debugging)
- [Client Instructions](#client-instructions)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)

## 🎯 Project Overview

This VPN deployment system provides automated WireGuard VPN setup specifically designed for dental practices needing HIPAA-compliant remote access to applications like Optima and Open Dental.

### Key Features
- **One-click server setup** on Ubuntu VPS
- **Automated client configuration** with QR codes
- **Web management dashboard** for ongoing administration
- **Comprehensive testing tools** for troubleshooting
- **HIPAA-focused security** configurations

## ⚡ Quick Start

### For Server Setup (VPS)
```bash
# 1. Download and run server setup
wget https://your-repo.com/scripts/setup-server.sh
chmod +x setup-server.sh
sudo ./setup-server.sh

# 2. Create your first client
./scripts/generate-client.sh -n "Dr-Kover-iPad" -s YOUR_SERVER_IP
```

### For Client Management (Local)
```bash
# Install the management tools
pip install -r requirements.txt
pip install -e .

# Generate client configurations
python -m src.cli.client_config --name "Dr-Smith" --server-ip 192.168.1.100

# Launch web dashboard
python -m src.web.app --server-endpoint YOUR_SERVER_IP
```

## 🔧 Installation

### Prerequisites
- **Server**: Ubuntu 20.04+ VPS with root access
- **Management**: Python 3.8+ for CLI tools and dashboard
- **Client**: WireGuard app on target devices

### Server Installation
```bash
# Run the automated setup script
curl -fsSL https://your-repo.com/install.sh | sudo bash
```

### Management Tools Installation
```bash
# Clone repository
git clone https://github.com/your-org/vpn-deployment-system.git
cd vpn-deployment-system

# Install Python dependencies
pip install -r requirements.txt

# Install CLI tools
pip install -e .
```

## 🖥️ Server Setup

### Automated Setup (Recommended)
```bash
sudo ./scripts/setup-server.sh
```

This script will:
- ✅ Install WireGuard and dependencies
- ✅ Configure firewall (UFW)
- ✅ Generate server keys
- ✅ Create base configuration
- ✅ Enable IP forwarding
- ✅ Start WireGuard service

### Manual Setup
If you prefer manual setup or need customization:

1. **Install WireGuard**:
   ```bash
   sudo apt update
   sudo apt install wireguard wireguard-tools
   ```

2. **Generate Server Keys**:
   ```bash
   python -m src.cli.keygen --server --output /etc/wireguard --name production
   ```

3. **Configure Network**:
   ```bash
   echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
   sudo sysctl -p
   ```

4. **Set up Firewall**:
   ```bash
   sudo ufw allow 51820/udp
   sudo ufw allow ssh
   sudo ufw enable
   ```

### Server Configuration Files
- **Main config**: `/etc/wireguard/wg0.conf`
- **Server keys**: `/etc/wireguard/server_*.key`
- **Client configs**: `/etc/wireguard/clients/`

## 👥 Client Management

### Using CLI Tools

#### Generate New Client
```bash
# Basic client generation
python -m src.cli.client_config \
  --name "Dr-Kover-iPad" \
  --server-ip 192.168.1.100

# Advanced options
python -m src.cli.client_config \
  --name "Dr-Smith-Laptop" \
  --server-ip 192.168.1.100 \
  --dns "1.1.1.1" "8.8.8.8" \
  --allowed-ips "0.0.0.0/0" \
  --no-qr
```

#### Using Shell Scripts
```bash
# Quick client generation
./scripts/generate-client.sh -n "Dr-Jones-Phone" -s 192.168.1.100

# With custom options
./scripts/generate-client.sh \
  -n "Dr-Wilson-Tablet" \
  -s 192.168.1.100 \
  -p 51820 \
  -d "1.1.1.1, 8.8.8.8"
```

### Output Files
Each client generation creates:
- `client_name.conf` - Configuration file
- `client_name_qr.png` - QR code for easy setup
- `server_peer.conf` - Server-side peer configuration

## 🌐 Web Dashboard

### Starting the Dashboard
```bash
# Basic startup
python -m src.web.app

# Custom configuration
python -m src.web.app \
  --host 0.0.0.0 \
  --port 8080 \
  --keys-dir /etc/wireguard \
  --server-endpoint 192.168.1.100
```

### Dashboard Features
- **Real-time server status** monitoring
- **Client management** - add, remove, download configs
- **QR code generation** for mobile devices
- **Connection monitoring** - see active peers
- **Configuration download** - easy client distribution

### Accessing the Dashboard
- **Local**: http://localhost:5000
- **Remote**: http://YOUR_SERVER_IP:5000
- **Secure**: Set up nginx proxy with SSL for production

## 🧪 Testing & Debugging

### Comprehensive Testing
```bash
# Run all tests
python -m src.utils.testing

# Test specific component
python -m src.utils.testing --test test_server_connectivity

# Generate detailed report
python -m src.utils.testing --output vpn_test_report.md
```

### Manual Testing Commands

#### Server-side Testing
```bash
# Check WireGuard status
sudo wg show

# Check service status
sudo systemctl status wg-quick@wg0

# View logs
sudo journalctl -u wg-quick@wg0 -f

# Test connectivity
ping 10.0.0.1  # VPN server IP
```

#### Client-side Testing
```bash
# Check connection
ping 10.0.0.1  # Server VPN IP
ping 8.8.8.8   # Internet connectivity

# Check public IP (should show server IP when connected)
curl ifconfig.me

# DNS leak test
nslookup google.com
```

### Common Debug Commands
```bash
# Check firewall
sudo ufw status verbose

# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward

# Check routing
ip route show

# Check iptables rules
sudo iptables -L -n -v
sudo iptables -t nat -L -n -v
```

## 📱 Client Instructions

### For iOS/Android
1. Install WireGuard app from App Store/Play Store
2. Scan the QR code provided by your IT administrator
3. Toggle the connection ON

### For Windows/Mac/Linux
1. Download WireGuard from https://www.wireguard.com/install/
2. Import the `.conf` file provided by your IT administrator
3. Activate the tunnel

### Client Configuration Delivery
**Secure Methods**:
- Email encrypted ZIP file (password shared separately)
- Secure file sharing service (Box, OneDrive Business)
- In-person QR code scan
- USB drive for on-site setup

**Never Use**:
- Unencrypted email
- SMS/text messages
- Public file sharing services

## 🔍 Troubleshooting

### Common Issues

#### Server Won't Start
```bash
# Check configuration syntax
sudo wg-quick up wg0

# Check for port conflicts
sudo netstat -ulnp | grep 51820

# Check permissions
sudo ls -la /etc/wireguard/
```

#### Clients Can't Connect
```bash
# Verify firewall allows WireGuard port
sudo ufw status | grep 51820

# Check if service is running
sudo systemctl status wg-quick@wg0

# Verify public IP/endpoint
curl ifconfig.me
```

#### No Internet Access Through VPN
```bash
# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward

# Check NAT rules
sudo iptables -t nat -L POSTROUTING -n -v

# Verify network interface
ip route show default
```

#### DNS Not Working
```bash
# Check DNS configuration in client
# Verify server can resolve DNS
nslookup google.com

# Check if DNS is being routed through VPN
dig @1.1.1.1 google.com
```

### Log Analysis
```bash
# WireGuard service logs
sudo journalctl -u wg-quick@wg0 --since "1 hour ago"

# Kernel logs for WireGuard
dmesg | grep wireguard

# UFW logs (if enabled)
sudo tail -f /var/log/ufw.log
```

## 🔒 Security Best Practices

### Server Security
- **Regular Updates**: Keep Ubuntu and WireGuard updated
- **Firewall**: Only allow necessary ports (SSH, WireGuard)
- **SSH Security**: Use key-based authentication, disable password login
- **Monitoring**: Set up log monitoring and alerts
- **Backups**: Regular backup of configuration and keys

### Key Management
- **Private Key Protection**: Never share or transmit private keys in plain text
- **Key Rotation**: Regularly rotate client keys for maximum security
- **Preshared Keys**: Use preshared keys for additional quantum resistance
- **Access Control**: Remove unused client configurations promptly

### Client Security
- **Secure Distribution**: Use encrypted channels for configuration sharing
- **Device Security**: Ensure client devices have screen locks and encryption
- **App Updates**: Keep WireGuard apps updated on all devices
- **Connection Awareness**: Train users to verify VPN connection before accessing sensitive data

### HIPAA Compliance Notes
- **Encryption**: WireGuard provides strong encryption suitable for HIPAA
- **Access Logging**: Monitor and log all VPN connections
- **User Training**: Provide security awareness training
- **Documentation**: Maintain documentation of security measures
- **Incident Response**: Have procedures for security incidents

### Network Segmentation
```bash
# Restrict VPN clients to specific networks only
# Example: Only allow access to practice management system
iptables -A FORWARD -i wg0 -d 192.168.1.100 -j ACCEPT
iptables -A FORWARD -i wg0 -j DROP
```

## 📞 Support

### For Technical Issues
1. Run diagnostic tests: `python -m src.utils.testing`
2. Check server logs: `sudo journalctl -u wg-quick@wg0`
3. Review this troubleshooting guide
4. Contact your IT administrator with test results

### For New Client Setup
1. Request configuration from IT administrator
2. Install WireGuard on your device
3. Import configuration or scan QR code
4. Test connection and report any issues

---

**Generated for Dr. Jeff Kover - ServerOptima VPS Deployment**  
*Contract: $375 flat-rate via Thumbtack*
