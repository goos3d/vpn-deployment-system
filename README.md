# VPN Deployment System

🛡️ **Comprehensive WireGuard VPN deployment and management system designed for dental software clients requiring HIPAA-compliant remote access.**

[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![WireGuard](https://img.shields.io/badge/VPN-WireGuard-orange.svg)](https://www.wireguard.com/)

## 🎯 Project Overview

This system provides automated VPN deployment for dental practices needing secure remote access to applications like Optima and Open Dental. Built specifically for HIPAA-conscious healthcare environments.

### ✨ Key Features

- 🔐 **Automated Key Generation** - Secure WireGuard key management with encryption
- 📱 **Client Config Generator** - Automated configurations with QR codes
- 🌐 **Web Management Dashboard** - Professional Flask-based interface
- 📜 **VPS Setup Scripts** - One-command Ubuntu server deployment
- 🧪 **Comprehensive Testing** - Built-in diagnostics and validation
- 📚 **Complete Documentation** - HIPAA-focused security guides

## 🚀 Quick Start

### Server Setup (Ubuntu VPS)
```bash
# Download and run automated setup
wget https://raw.githubusercontent.com/your-org/vpn-deployment-system/main/scripts/setup-server.sh
chmod +x setup-server.sh
sudo ./setup-server.sh
```

### Management Tools Installation
```bash
# Clone repository
git clone https://github.com/your-org/vpn-deployment-system.git
cd vpn-deployment-system

# Install dependencies
pip install -r requirements.txt
pip install -e .

# Launch web dashboard
python vpn.py dashboard
```

## 📋 Usage Examples

### Generate Client Configuration
```bash
# Using CLI
python vpn.py client --name "Dr-Smith-iPad" --server-ip 192.168.1.100

# Using shell script
./scripts/generate-client.sh -n "Dr-Kover-Laptop" -s 192.168.1.100
```

### Launch Web Dashboard
```bash
python vpn.py dashboard --host 0.0.0.0 --port 5000
# Access at: http://localhost:5000
```

### Run Diagnostics
```bash
python vpn.py test --output diagnostic_report.md
```

## 🏗️ Architecture

```
├── src/
│   ├── cli/              # Command-line interface tools
│   ├── core/             # Core VPN management logic
│   ├── web/              # Web dashboard components
│   └── utils/            # Testing and utility functions
├── scripts/              # Shell scripts for VPS setup
├── templates/            # Configuration file templates
├── docs/                 # Complete documentation
└── tests/                # Unit tests and validation
```

## � Security Features

- **HIPAA Compliance Ready** - Strong encryption suitable for healthcare
- **Automated Firewall Setup** - UFW configuration with secure defaults
- **Key Encryption Options** - Password-protected private keys
- **Secure Configuration Distribution** - QR codes and encrypted transfers
- **Access Monitoring** - Built-in connection logging and diagnostics

## � Documentation

- [**Complete Deployment Guide**](docs/DEPLOYMENT_GUIDE.md) - Comprehensive setup instructions
- [**Security Best Practices**](docs/DEPLOYMENT_GUIDE.md#security-best-practices) - HIPAA compliance guidelines
- [**Troubleshooting Guide**](docs/DEPLOYMENT_GUIDE.md#troubleshooting) - Common issues and solutions

## 🧪 Testing

```bash
# Run all diagnostic tests
python vpn.py test

# Test specific components
python -m src.utils.testing --test test_server_connectivity

# Generate detailed report
python -m src.utils.testing --output test_report.md
```

## 🛠️ CLI Commands

```bash
python vpn.py info        # Show system information
python vpn.py keygen      # Generate WireGuard keys  
python vpn.py client      # Create client configurations
python vpn.py dashboard   # Launch web management UI
python vpn.py test        # Run diagnostic tests
```

## 🎯 Current Client

**Dr. Jeff Kover** - ServerOptima VPS with WireGuard VPN
- Contract: $375 flat-rate via Thumbtack
- VPS Configuration: `/etc/wireguard/wg0.conf`
- Payment: ACH in progress

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏥 Healthcare Compliance

This system is designed with HIPAA requirements in mind:
- Strong encryption protocols (WireGuard)
- Secure key management practices
- Access logging and monitoring capabilities
- Documentation for compliance audits

*Note: While this system implements security best practices, organizations should conduct their own compliance assessments.*

---

**⚡ Built for Dr. Jeff Kover - ServerOptima VPS Deployment**  
*Secure, reliable, and HIPAA-focused VPN solutions for dental practices*
