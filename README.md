# NetBird Exit Node Setup Guide for OpenWrt



![GitHub](https://img.shields.io/badge/Platform-OpenWrt-blue)




![NetBird](https://img.shields.io/badge/NetBird-VPN%20Setup-green)




![License](https://img.shields.io/badge/License-MIT-yellow)



A comprehensive step-by-step guide to set up NetBird as an exit node on your OpenWrt router, allowing remote peers to route their internet traffic through your connection.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Dashboard Configuration](#dashboard-configuration)
- [Network Configuration](#network-configuration)
- [Firewall Configuration](#firewall-configuration)
- [Verification](#verification)
- [Testing & Troubleshooting](#testing--troubleshooting)
- [Performance Tips](#performance-tips)
- [FAQ](#faq)

---

## Overview

An **exit node** on your OpenWrt router allows remote NetBird peers to route their internet traffic through your connection. Essentially, anyone in your NetBird network can use your home/office bandwidth from anywhere in the world through a secure, encrypted tunnel.

### What You'll Achieve

✅ Secure private VPN overlay network  
✅ Remote access to your internet connection  
✅ Encrypted peer-to-peer connectivity  
✅ Complete network isolation from public internet  
✅ Access your internal network remotely  

---

## Prerequisites

- **OpenWrt router** with working internet connection
- **SSH access** to your router (admin credentials)
- **NetBird account** (free tier available at [app.netbird.io](https://app.netbird.io/))
- **Basic Linux knowledge** (command-line comfort level)
- **IP forwarding support** on your router (most modern routers support this)

### Supported Architectures

- ARM (ARMv7, ARMv8)
- x86 / x64
- MIPS (some variants)

---

## Installation

### Step 1️⃣ Update Package Manager

SSH into your OpenWrt router and update the package lists:

```bash
apk update
```

This refreshes the package lists from Alpine Linux repositories.

### Step 2️⃣ Install NetBird

```bash
apk add netbird
```

This installs the NetBird client on your router.

### Step 3️⃣ Enable & Start NetBird Service

```bash
/etc/init.d/netbird enable
/etc/init.d/netbird start
```

| Command | Purpose |
|---------|---------|
| `enable` | Starts NetBird automatically on router boot |
| `start` | Starts NetBird immediately |

Verify installation:
```bash
netbird version
```

---

## Dashboard Configuration

### Step 1️⃣ Generate Setup Key

1. Visit [https://app.netbird.io/](https://app.netbird.io/)
2. Log in with your NetBird account (or create a free account)
3. Navigate to: **Dashboard → Peers → Add agent**
4. Click **"Create a New Setup Key"**
5. Copy the generated key (format: `NBSK_XXXXXXXXXXXXXXXXXXXXXXXX`)

<details>
<summary>💡 Setup Key Tips</summary>

- Setup keys are one-time use by default
- You can make a key reusable for multiple devices
- Keys can be deleted or revoked anytime
- Treat keys like passwords—don't share publicly

</details>

### Step 2️⃣ Register Your Router

Back on your OpenWrt terminal, run:

```bash
netbird up --setup-key NBSK_XXXXXXXXXXXXXXXXXXXXXXXX
```

Replace `NBSK_XXXXXXXXXXXXXXXXXXXXXXXX` with your actual setup key.

Expected output:
```
Bring UP NetBird interface...
```

### Step 3️⃣ Configure as Exit Node

In the NetBird Dashboard:

1. Go to **Network Routing** → **Routes**
2. Find your OpenWrt router in the peers list
3. Enable the **"Exit node"** toggle
4. Set **"Distribution group"** to **"All"** for auto-apply to all peers

> **Note:** Distribution groups allow you to selectively assign exit nodes to specific peer groups.

---

## Network Configuration

### Step 1️⃣ Enable IP Forwarding

Check your current IP forwarding setting:

```bash
sysctl net.ipv4.ip_forward
```

**Expected output:**
```
net.ipv4.ip_forward = 1
```

If it shows `0`, enable IP forwarding:

```bash
sysctl -w net.ipv4.ip_forward=1
```

**What this does:** Allows your router to forward packets between networks (essential for exit node functionality).

### Step 2️⃣ Verify NetBird Interface

Check if the NetBird interface (wt0) exists and has an IP:

```bash
ip addr show wt0
```

**Expected output:**
```
2: wt0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1280 qdisc pfifo_fast state UNKNOWN qlen 500
    inet 100.99.5.103/16 scope global wt0
       valid_lft forever preferred_lft forever
```

> **Note:** The `100.x.x.x` address is your NetBird private IP. If you don't see this, wait 10-15 seconds for NetBird to initialize and create the interface.

### Step 3️⃣ Create NetBird Interface in UCI

Configure OpenWrt's unified configuration to recognize the NetBird interface:

```bash
uci set network.netbird='interface'
uci set network.netbird.proto='none'
uci set network.netbird.device='wt0'
```

This tells OpenWrt's configuration system to manage the NetBird virtual interface.

---

## Firewall Configuration

This is the **most critical part** for traffic to flow through your exit node.

### Step 1️⃣ Create NetBird Firewall Zone

```bash
uci add firewall zone
uci set firewall.@zone[-1].name='netbird'
uci set firewall.@zone[-1].network='netbird'
uci set firewall.@zone[-1].input='ACCEPT'
uci set firewall.@zone[-1].output='ACCEPT'
uci set firewall.@zone[-1].forward='ACCEPT'
```

**Explanation:**
- `name='netbird'` — Zone identifier
- `network='netbird'` — Associated network interface
- `input/output/forward='ACCEPT'` — Allow all traffic directions

### Step 2️⃣ Enable Masquerading

```bash
uci set firewall.@zone[-1].masq='1'
```

**What this does:** Network Address Translation (NAT). Makes traffic from NetBird peers appear to originate from your router's public IP.

### Step 3️⃣ Add Forwarding Rule (NetBird → WAN)

Allow traffic to flow from NetBird peers to the internet:

```bash
uci add firewall forwarding
uci set firewall.@forwarding[-1].src='netbird'
uci set firewall.@forwarding[-1].dest='wan'
```

> **Important:** Replace `wan` with your actual WAN interface name if different (e.g., `pppoe-wan`, `eth1`, etc.). Check with `ip link show`.

### Step 4️⃣ Commit & Reload Configuration

Save your changes and apply them:

```bash
uci commit network
uci commit firewall
/etc/init.d/network reload
/etc/init.d/firewall reload
```

---

## Verification

Follow these steps to confirm everything is working correctly.

### Step 1️⃣ Restart NetBird

```bash
/etc/init.d/netbird restart
sleep 10
```

Wait 10 seconds for NetBird to fully reinitialize.

### Step 2️⃣ Check NetBird Status

```bash
netbird status
```

**Expected output:**
```
NetBird daemon is running
Interface wt0 status: Connected
Your IP: 100.99.5.103/16
```

For detailed diagnostic info:
```bash
netbird status -d
```

### Step 3️⃣ Verify Interface Assignment

```bash
ip addr show wt0
```

Should display your `100.x.x.x` NetBird address.

### Step 4️⃣ Check Routing Table

```bash
ip route
```

**You should see both:**

```
100.99.0.0/16 dev wt0           ← NetBird network route
default via 192.168.1.1 dev pppoe-wan  ← Your internet gateway
```

✅ **If you see both routes, you're good to go!**

### Verification Checklist

- [ ] `netbird status` shows "Connected"
- [ ] `ip addr show wt0` displays `100.x.x.x/16`
- [ ] `ip route` shows both NetBird and WAN routes
- [ ] No errors in `logread`
- [ ] Firewall is reloaded without errors

---

## Testing & Troubleshooting

### 🧪 Connectivity Test

From another NetBird peer (laptop, phone, etc.):

```bash
ping 100.99.5.103
```

Replace with your actual NetBird IP. If it responds, your exit node is reachable!

### ❌ Common Issues & Solutions

#### Issue: Traffic Not Flowing

**Symptoms:** Peers can't access internet through exit node

**Solutions:**
```bash
# Check firewall configuration
uci show firewall | grep -E "(netbird|masq)"

# Verify masquerading is enabled
uci show firewall.@zone[-1]
# Should show: masq=1

# Check forwarding rules
uci show firewall.@forwarding
```

#### Issue: NetBird Daemon Not Running

**Symptoms:** `netbird status` shows "disconnected"

**Solutions:**
```bash
# Check logs
logread | grep -i netbird

# Restart service
/etc/init.d/netbird restart

# Verify binary exists
which netbird
```

#### Issue: Interface wt0 Missing or No IP

**Symptoms:** `ip addr show wt0` returns "Device not found"

**Solutions:**
```bash
# Wait longer for NetBird to initialize
sleep 15 && ip addr show wt0

# Check NetBird status
netbird status -d

# Restart NetBird
/etc/init.d/netbird restart
```

#### Issue: Wrong WAN Interface Name

**Symptoms:** Firewall forwarding rule doesn't work

**Solutions:**
```bash
# Find your actual WAN interface
ip link show

# Common names:
# - eth0, eth1 (ethernet)
# - pppoe-wan (PPPoE)
# - wwan0 (mobile)
# - wan (generic)

# Update firewall rule if needed
uci set firewall.@forwarding[-1].dest='your_wan_interface'
uci commit firewall
/etc/init.d/firewall reload
```

### 🔍 Debug Commands Reference

| Command | Purpose |
|---------|---------|
| `netbird status -d` | Detailed NetBird diagnostics |
| `logread \| tail -20` | Last 20 system log lines |
| `logread \| grep netbird` | NetBird-specific logs |
| `uci show network` | All network configuration |
| `uci show firewall` | All firewall configuration |
| `ss -tlnp \| grep netbird` | Check if NetBird is listening |
| `ip route` | Show routing table |
| `iptables -t nat -L -n -v` | Show NAT rules |

---

## Performance Tips

### 📊 Monitor Router Resources

During heavy use, check system load:

```bash
# Interactive monitoring
top

# Memory usage
free -m

# Disk usage
df -h

# Network interface stats
vnstat -h
```

**Expected behavior:** NetBird adds 5-15% CPU load on modern routers. Heavy usage may spike higher.

### ⚡ Quality of Service (QoS)

Prevent single peers from consuming all bandwidth:

1. OpenWrt Web Interface (LuCI): **Network → QoS**
2. Create traffic control rules for NetBird interface
3. Set bandwidth limits per peer if needed

### 🔄 Keep NetBird Updated

```bash
# Update package lists
apk update

# Upgrade NetBird
apk upgrade netbird

# Check version
netbird version
```

Updates include performance improvements and security patches.

### 📈 Monitor Bandwidth Usage

```bash
# Per-process bandwidth (requires nethogs)
apk add nethogs
nethogs

# Overall stats
vnstat -h

# Real-time interface bandwidth
apk add iftop
iftop -i wt0
```

### 💡 Optimization Tips

| Tip | Benefit |
|-----|---------|
| Upgrade router RAM | Handles more concurrent peers |
| Use wired connection | Better stability than WiFi |
| Separate exit node | Dedicated hardware = better performance |
| Enable hardware offloading | Some routers can offload encryption |
| Limit peer count | Fewer peers = less CPU usage |

---

## FAQ

<details>
<summary><b>Q: Can I have multiple exit nodes?</b></summary>

**A:** Yes! Set up multiple routers as exit nodes. In the NetBird Dashboard, configure different distribution groups to route specific peers through different exit nodes.

</details>

<details>
<summary><b>Q: Is my traffic encrypted?</b></summary>

**A:** Yes. All NetBird traffic uses WireGuard protocol with end-to-end encryption. Even your ISP can't see what data you're transmitting.

</details>

<details>
<summary><b>Q: Will this slow down my home network?</b></summary>

**A:** Minimally on modern routers. NetBird uses efficient routing. You'll notice impact only if many peers simultaneously use the exit node for heavy downloads.

</details>

<details>
<summary><b>Q: What if I restart my router?</b></summary>

**A:** NetBird will automatically restart since you enabled it with `enable`. It will reconnect to the dashboard and function as exit node again.

</details>

<details>
<summary><b>Q: Can I use this on OpenWrt running on PC/VM?</b></summary>

**A:** Yes! The steps are identical. NetBird works on any OpenWrt installation.

</details>

<details>
<summary><b>Q: How do I disable exit node mode?</b></summary>

**A:** In NetBird Dashboard → Network Routing → Routes, toggle off the "Exit node" setting for your router.

</details>

<details>
<summary><b>Q: What's the bandwidth limit?</b></summary>

**A:** No built-in limit. Bandwidth is limited only by your router's processing power and internet connection speed.

</details>

---

## Quick Reference: One-Time Setup

Save this script to run all commands at once (after updating setup key):

```bash
#!/bin/bash

# Replace with your actual setup key
SETUP_KEY="NBSK_XXXXXXXXXXXXXXXXXXXXXXXX"

# Installation
echo "Installing NetBird..."
apk update
apk add netbird
/etc/init.d/netbird enable
/etc/init.d/netbird start

# Register with dashboard
echo "Registering with NetBird dashboard..."
netbird up --setup-key $SETUP_KEY

# Network config
echo "Configuring network..."
sysctl -w net.ipv4.ip_forward=1
uci set network.netbird='interface'
uci set network.netbird.proto='none'
uci set network.netbird.device='wt0'

# Firewall config
echo "Configuring firewall..."
uci add firewall zone
uci set firewall.@zone[-1].name='netbird'
uci set firewall.@zone[-1].network='netbird'
uci set firewall.@zone[-1].input='ACCEPT'
uci set firewall.@zone[-1].output='ACCEPT'
uci set firewall.@zone[-1].forward='ACCEPT'
uci set firewall.@zone[-1].masq='1'

uci add firewall forwarding
uci set firewall.@forwarding[-1].src='netbird'
uci set firewall.@forwarding[-1].dest='wan'

# Apply changes
echo "Applying configuration..."
uci commit network
uci commit firewall
/etc/init.d/network reload
/etc/init.d/firewall reload

# Restart and verify
echo "Restarting NetBird..."
/etc/init.d/netbird restart
sleep 10

echo ""
echo "✅ Setup complete! Verifying..."
echo ""
echo "NetBird Status:"
netbird status
echo ""
echo "Interface IP:"
ip addr show wt0
echo ""
echo "Routes:"
ip route
```

---

## Quick Verification Commands

```bash
# All-in-one verification
echo "=== NetBird Status ===" && netbird status && \
echo "" && echo "=== Interface IP ===" && ip addr show wt0 && \
echo "" && echo "=== Routing ===" && ip route && \
echo "" && echo "=== Firewall ===" && uci show firewall | grep netbird
```

---

## Related Resources

- 🌐 [NetBird Official Website](https://netbird.io/)
- 📊 [NetBird Dashboard](https://app.netbird.io/)
- 📚 [NetBird Documentation](https://docs.netbird.io/)
- 🔧 [OpenWrt Documentation](https://openwrt.org/docs)
- 💬 [OpenWrt Forum](https://forum.openwrt.org/)
- 🐛 [NetBird GitHub](https://github.com/netbirdio/netbird)

---

## Contributing

Found an issue or have improvements? Feel free to:
- Open an issue if you encounter problems
- Submit a pull request with fixes or enhancements
- Share your setup experiences in discussions

## License

This guide is provided as-is under the [MIT License](LICENSE).

---

## Support

- ❓ Having issues? Check the [Troubleshooting section](#testing--troubleshooting)
- 📧 NetBird support: [support.netbird.io](https://support.netbird.io/)
- 🐞 Found a bug in NetBird? [Report on GitHub](https://github.com/netbirdio/netbird/issues)

---

**Last Updated:** 2026-09-08  
**NetBird Version:** Latest (check with `netbird version`)  
**OpenWrt Version:** 21.x and newer

---

<div align="center">

**⭐ If this guide helped you, consider giving it a star! ⭐**

</div>
