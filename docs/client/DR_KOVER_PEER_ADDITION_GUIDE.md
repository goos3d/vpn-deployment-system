# 🚀 Dr. Kover VPN - Easy Peer Addition Guide

## 📱 **Adding New Devices to Your VPN**

Your VPN server is ready to add new devices anytime. Follow these simple steps when you're ready to connect additional devices.

---

## 🎯 **Quick Start - 3 Simple Steps**

### **Step 1: Access Your Server**
```bash
# SSH into your server
ssh root@184.105.7.112
```

### **Step 2: Add New Device**
```bash
# Run the peer addition script
cd /etc/wireguard
./add-peer.sh [DEVICE-NAME]

# Examples:
./add-peer.sh iPad
./add-peer.sh iPhone  
./add-peer.sh OfficePC
./add-peer.sh HomePC
```

### **Step 3: Restart VPN Service**
```bash
# Apply changes
systemctl restart wg-quick@wg0
```

**That's it!** Your new device config will be created as `DrKover-[DEVICE-NAME].conf`

---

## 📋 **Detailed Instructions**

### **Adding a Single Device**

1. **Connect to your server:**
   ```bash
   ssh root@184.105.7.112
   ```

2. **Navigate to WireGuard directory:**
   ```bash
   cd /etc/wireguard
   ```

3. **Add the new device:**
   ```bash
   ./add-peer.sh iPad
   ```
   
   This will:
   - Generate secure keys for the device
   - Assign it the next available IP address
   - Create the client configuration file
   - Add it to your server configuration

4. **Restart the VPN service:**
   ```bash
   systemctl restart wg-quick@wg0
   ```

5. **Download the config file:**
   The new config will be saved as `DrKover-iPad.conf`

### **Adding Multiple Devices at Once**

If you need to add several devices:

```bash
# Add multiple devices quickly
./add-peer.sh iPad
./add-peer.sh iPhone
./add-peer.sh OfficePC
./add-peer.sh HomePC

# Then restart once
systemctl restart wg-quick@wg0
```

---

## 📱 **Setting Up the Device**

### **For iOS/Android:**
1. Install **WireGuard** app from App Store/Play Store
2. Transfer the `.conf` file to your device
3. Import the configuration in WireGuard app
4. Toggle connection ON

### **For Windows/Mac/Linux:**
1. Install **WireGuard** from wireguard.com
2. Import the `.conf` file
3. Activate the connection

---

## 🔍 **Checking Your VPN Status**

### **See all connected devices:**
```bash
wg show
```

### **See all configured devices:**
```bash
cat wg0.conf
```

### **Check VPN service status:**
```bash
systemctl status wg-quick@wg0
```

---

## 📁 **Managing Configuration Files**

### **List all client configs:**
```bash
ls -la DrKover-*.conf
```

### **Download config to your computer:**
```bash
# From your local computer:
scp root@184.105.7.112:/etc/wireguard/DrKover-iPad.conf ./
```

### **View a config file:**
```bash
cat DrKover-iPad.conf
```

---

## 🚨 **Troubleshooting**

### **If a device won't connect:**

1. **Check server status:**
   ```bash
   systemctl status wg-quick@wg0
   wg show
   ```

2. **Restart the service:**
   ```bash
   systemctl restart wg-quick@wg0
   ```

3. **Check firewall:**
   ```bash
   ufw status
   ```

### **If you need to remove a device:**

1. **Edit the server config:**
   ```bash
   nano wg0.conf
   # Remove the [Peer] section for that device
   ```

2. **Restart the service:**
   ```bash
   systemctl restart wg-quick@wg0
   ```

3. **Delete the client config:**
   ```bash
   rm DrKover-[DEVICE-NAME].conf
   ```

---

## 📞 **Need Help?**

If you run into any issues:

1. **Check the status first:**
   ```bash
   ./vpn-status.sh
   ```

2. **Contact Thomas Rodriguez:**
   - Email: thomas@eastbayav.com
   - Phone: (510) 666-5915
   - Support rate: $150/hr for troubleshooting

---

## 🔐 **Security Notes**

- Each device gets unique keys and IP address
- Devices can only see the internet, not each other
- Server maintains all traffic logs for security
- Configurations are HIPAA-compliant

---

## 📊 **Current Setup**

- **Server IP:** 184.105.7.112
- **VPN Port:** 51820
- **Network Range:** 10.0.0.x
- **Encryption:** ChaCha20 (AES-256 equivalent)
- **DNS:** 1.1.1.1, 8.8.8.8

---

**Your VPN is ready for expansion whenever you need it!** 🚀

*Keep this guide handy for future device additions*
