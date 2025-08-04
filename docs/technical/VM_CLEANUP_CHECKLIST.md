# 🧹 VM Cleanup Checklist - Leave No Trace

Complete this checklist before disconnecting from the VM to ensure no personal traces remain while keeping the VPN fully functional.

## ✅ **Step-by-Step Cleanup Process**

### **1. Clear Command History**
```bash
# Clear bash history completely
history -c
history -w
rm ~/.bash_history

# Clear other shell histories if they exist
rm ~/.zsh_history 2>/dev/null
rm ~/.fish_history 2>/dev/null

# Disable history for current session
unset HISTFILE
export HISTSIZE=0
```

### **2. Remove Personal SSH Access**
```bash
# OPTION A: Remove all SSH keys (recommended)
rm ~/.ssh/authorized_keys
rm -rf ~/.ssh/

# OPTION B: Remove only your specific key (safer if client needs SSH)
# Edit ~/.ssh/authorized_keys and manually remove your key line
# nano ~/.ssh/authorized_keys
```

### **3. Clear Temporary Files**
```bash
# System temp files
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# User temp files
rm -rf ~/.cache/*
rm -rf ~/.local/share/Trash/* 2>/dev/null
rm -rf ~/.thumbnails/* 2>/dev/null
```

### **4. Remove Setup Scripts & Personal Files**
```bash
# Remove any setup scripts you uploaded
rm ~/setup-*.sh 2>/dev/null
rm ~/install-*.sh 2>/dev/null
rm ~/wg-*.sh 2>/dev/null
rm ~/*.py 2>/dev/null
rm ~/*.txt 2>/dev/null

# Clear common directories
rm -rf ~/Desktop/* 2>/dev/null
rm -rf ~/Downloads/* 2>/dev/null
rm -rf ~/Documents/* 2>/dev/null
```

### **5. Clear System Logs (Your Access Traces)**
```bash
# Clear authentication logs (your login history)
sudo truncate -s 0 /var/log/auth.log
sudo truncate -s 0 /var/log/btmp 2>/dev/null
sudo truncate -s 0 /var/log/wtmp 2>/dev/null

# Clear secure log (CentOS/RHEL)
sudo truncate -s 0 /var/log/secure 2>/dev/null

# Optional: Clear system logs (be careful - only if you know what you're doing)
# sudo truncate -s 0 /var/log/syslog
```

### **6. Remove Package Installation History**
```bash
# Clear apt history (Ubuntu/Debian)
sudo rm -f /var/log/apt/history.log*
sudo rm -f /var/log/apt/term.log*

# Clear yum/dnf history (CentOS/RHEL)
sudo rm -f /var/log/yum.log* 2>/dev/null
sudo yum history delete all 2>/dev/null
```

### **7. Clear Personal Configuration**
```bash
# Remove personal config files
rm ~/.bashrc.backup 2>/dev/null
rm ~/.vimrc 2>/dev/null
rm ~/.gitconfig 2>/dev/null
rm ~/.wget-hsts 2>/dev/null

# Reset bashrc to system default
sudo cp /etc/skel/.bashrc ~/.bashrc 2>/dev/null
```

### **8. Clear Recent File Access**
```bash
# Clear recently accessed files
rm ~/.recently-used* 2>/dev/null
rm ~/.local/share/recently-used.xbel 2>/dev/null

# Clear any GUI-related traces
rm -rf ~/.gconf* 2>/dev/null
rm -rf ~/.gnome* 2>/dev/null
```

## 🚨 **CRITICAL - Do NOT Delete These:**

### **Keep These Files/Services Intact:**
- `/etc/wireguard/` - Entire WireGuard configuration directory
- `/lib/systemd/system/wg-quick@.service` - WireGuard service files
- Firewall rules (`ufw` or `iptables` configurations)
- Network interface configurations
- System user accounts (don't delete the user you're logged in as)
- Any systemd services related to WireGuard

### **Services That Must Keep Running:**
- `wg-quick@wg0.service`
- `ufw.service` (if using UFW firewall)
- `ssh.service` (if client needs SSH access)

## ✅ **Final Verification Before Exit**

### **Test VPN Functionality:**
```bash
# Check WireGuard is running
sudo systemctl status wg-quick@wg0

# Verify peer configuration
sudo wg show

# Test internet connectivity
ping -c 3 8.8.8.8

# Check firewall rules are intact
sudo ufw status

# Verify server is listening on WireGuard port
sudo netstat -tulpn | grep :51820
```

### **Final Session Cleanup:**
```bash
# Clear current session history one more time
history -c
unset HISTFILE

# Clear any environment variables you may have set
unset CUSTOM_VAR_NAME  # Replace with any variables you set

# Exit cleanly
exit
```

## 🎯 **Post-Cleanup Verification**

After disconnecting, test from your local machine:

```bash
# Test VPN connection with client config
# Connect and verify internet access
# Ping test: ping 8.8.8.8
# IP check: curl ifconfig.me
```

## 📋 **What This Achieves:**

✅ **Removes all traces of your personal access**
✅ **Clears command history and login records**  
✅ **Removes temporary files and personal configs**
✅ **Maintains fully functional VPN service**
✅ **Preserves client's ability to use the system**
✅ **Professional, clean handoff**

---

**Remember:** The goal is to make it appear as if the VPN was set up by an automated deployment system with no human footprint, while maintaining 100% functionality for the client.

*Cleanup checklist - Use this systematically before disconnecting from any client VM*
