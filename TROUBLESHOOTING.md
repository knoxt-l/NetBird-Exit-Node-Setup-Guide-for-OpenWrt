# NetBird OpenWrt Troubleshooting Guide

This comprehensive guide helps you diagnose and fix common issues when setting up NetBird as an exit node on OpenWrt.

## Table of Contents

1. [Quick Diagnostics](#quick-diagnostics)
2. [Service Issues](#service-issues)
3. [Network Configuration Issues](#network-configuration-issues)
4. [Firewall Issues](#firewall-issues)
5. [Interface Issues](#interface-issues)
6. [Connectivity Issues](#connectivity-issues)
7. [Performance Issues](#performance-issues)
8. [Advanced Debugging](#advanced-debugging)

---

## Quick Diagnostics

Run this command to get a full health report:

```bash
echo "=== NetBird Status ===" && netbird status && \
echo "" && echo "=== Interface IP ===" && ip addr show wt0 && \
echo "" && echo "=== Routing ===" && ip route && \
echo "" && echo "=== Firewall ===" && uci show firewall | grep netbird
```

---

## Service Issues

### Problem: NetBird Service Won't Start

**Symptoms:**
- `netbird status` returns "disconnected"
- Service doesn't appear in process list
- Error message when starting service

**Diagnosis:**

```bash
# Check if NetBird binary exists
which netbird

# Check service status
/etc/init.d/netbird status

# Check recent logs
logread | grep -i netbird | tail -20
```

**Solutions:**

**Solution 1: Reinstall NetBird**
```bash
# Remove and reinstall
apk del netbird
apk add netbird

# Enable and start
/etc/init.d/netbird enable
/etc/init.d/netbird start
```

**Solution 2: Check Disk Space**
```bash
# OpenWrt may not have started if disk is full
df -h

# Clear cache if needed
apk cache clean
```

**Solution 3: Increase Init.d Timeout**

If NetBird takes too long to start, add timeout to init script:
```bash
# Edit the init script
vi /etc/init.d/netbird

# Find: start() and add
sleep 5
```

### Problem: NetBird Crashes Frequently

**Symptoms:**
- NetBird stops running randomly
- `dmesg` shows OOM (Out of Memory) errors
- Router becomes unresponsive

**Diagnosis:**

```bash
# Check available memory
free -m

# Check if process is killed due to OOM
dmesg | grep -i "killed\|oom"

# Monitor in real-time
top -d 1 -n 10 | grep netbird
```

**Solutions:**

**Solution 1: Reduce Memory Usage**
```bash
# Limit number of concurrent peers in dashboard settings
# Restart NetBird
/etc/init.d/netbird restart
```

**Solution 2: Increase System Memory**

If your router supports it, upgrade RAM or use USB swap:
```bash
# Create swap (if you have external storage)
dd if=/dev/zero of=/mnt/swap bs=1M count=512
mkswap /mnt/swap
swapon /mnt/swap

# Add to fstab for persistence:
echo "/mnt/swap swap swap default 0 0" >> /etc/fstab
```

**Solution 3: Reboot Regularly**

Create a cron job to reboot daily:
```bash
# Edit crontab
crontab -e

# Add this line for 4 AM reboot
0 4 * * * /sbin/reboot
```

---

## Network Configuration Issues

### Problem: IP Forwarding Not Enabled

**Symptoms:**
- Remote peers can't access internet through exit node
- Packets reach the router but don't leave
- Local network works fine

**Diagnosis:**

```bash
# Check IP forwarding status
sysctl net.ipv4.ip_forward

# Check IPv6 forwarding too
sysctl net.ipv6.conf.all.forwarding
```

**Expected:** Both should return `1`

**Solution:**

```bash
# Enable IPv4 forwarding
sysctl -w net.ipv4.ip_forward=1

# Enable IPv6 forwarding (if using IPv6)
sysctl -w net.ipv6.conf.all.forwarding=1

# Make persistent
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
```

### Problem: NetBird Interface Not Getting IP

**Symptoms:**
- `ip addr show wt0` shows no inet address
- Interface exists but no `100.x.x.x` address
- `ip link show wt0` might not exist at all

**Diagnosis:**

```bash
# Check if interface exists
ip link show | grep wt0

# Check if NetBird daemon is running
ps aux | grep netbird

# Check NetBird logs for interface errors
logread | grep -i "interface\|wt0" | tail -20
```

**Solutions:**

**Solution 1: Wait for Initialization**
```bash
# NetBird needs time to create interface
sleep 15 && ip addr show wt0
```

**Solution 2: Restart NetBird Daemon**
```bash
# Full restart
/etc/init.d/netbird stop
sleep 3
/etc/init.d/netbird start
sleep 10

# Verify
ip addr show wt0
```

**Solution 3: Check UCI Configuration**
```bash
# Verify interface is configured
uci show network.netbird

# Should output:
# network.netbird=interface
# network.netbird.proto=none
# network.netbird.device=wt0

# If missing, recreate:
uci set network.netbird='interface'
uci set network.netbird.proto='none'
uci set network.netbird.device='wt0'
uci commit network
```

### Problem: Routes Not Appearing

**Symptoms:**
- `ip route` doesn't show `100.99.0.0/16 dev wt0`
- Traffic routing doesn't work
- Firewall is configured but traffic doesn't flow

**Diagnosis:**

```bash
# Check current routing table
ip route

# Check if route is in interface config
uci show network.netbird

# Check NetBird's internal routes
netbird status -d | grep -i route
```

**Solutions:**

**Solution 1: Reload Network**
```bash
/etc/init.d/network reload
sleep 5
ip route
```

**Solution 2: Recreate Routes Manually**
```bash
# If automatic routing fails, add manually
ip route add 100.99.0.0/16 dev wt0

# Make persistent by adding to network config:
uci set network.netbird_route='route'
uci set network.netbird_route.interface='netbird'
uci set network.netbird_route.target='100.99.0.0'
uci set network.netbird_route.netmask='255.255.0.0'
uci commit network
/etc/init.d/network reload
```

---

## Firewall Issues

### Problem: Firewall Blocks NetBird Traffic

**Symptoms:**
- NetBird interface exists and has IP
- Local connectivity works (can ping wt0 from router)
- Remote peers can't access internet
- `logread` shows firewall drops

**Diagnosis:**

```bash
# Check firewall zones
uci show firewall.zone

# Check netbird zone specifically
uci show firewall.@zone | grep -A 5 "name='netbird'"

# Check forwarding rules
uci show firewall.@forwarding

# Monitor dropped packets
logread | tail -100 | grep -i "drop\|reject"
```

**Solutions:**

**Solution 1: Verify Zone Configuration**
```bash
# Check if netbird zone exists
uci show firewall | grep "name='netbird'"

# If missing, recreate:
uci add firewall zone
uci set firewall.@zone[-1].name='netbird'
uci set firewall.@zone[-1].network='netbird'
uci set firewall.@zone[-1].input='ACCEPT'
uci set firewall.@zone[-1].output='ACCEPT'
uci set firewall.@zone[-1].forward='ACCEPT'
uci set firewall.@zone[-1].masq='1'
uci commit firewall
/etc/init.d/firewall reload
```

**Solution 2: Enable Masquerading**
```bash
# Check if masquerading is enabled
uci show firewall.@zone[-1] | grep masq

# If not set to 1:
uci set firewall.@zone[-1].masq='1'
uci commit firewall
/etc/init.d/firewall reload
```

**Solution 3: Check Forwarding Rules**
```bash
# List all forwarding rules
uci show firewall.@forwarding

# Should have netbird→wan rule
# If missing:
uci add firewall forwarding
uci set firewall.@forwarding[-1].src='netbird'
uci set firewall.@forwarding[-1].dest='wan'
uci commit firewall
/etc/init.d/firewall reload
```

**Solution 4: Disable Firewall Temporarily (Testing Only)**
```bash
# WARNING: Only for testing!
/etc/init.d/firewall stop

# Test connectivity
# If it works, firewall is the issue
# Don't forget to re-enable:
/etc/init.d/firewall start
```

### Problem: Wrong WAN Interface

**Symptoms:**
- Firewall forwarding rule doesn't work
- Traffic doesn't leave through internet
- Rule shows wrong interface name

**Diagnosis:**

```bash
# Find your actual WAN interface
ip link show | grep -E "eth|ppp|wwan"

# Check current forwarding rules
uci show firewall.@forwarding

# Check WAN zone
uci show firewall | grep -A 5 "name='wan'"
```

**Solution:**

```bash
# Identify your WAN interface (common examples):
# eth0, eth1 (Ethernet)
# pppoe-wan (PPPoE connection)
# wwan0, wwan1 (Mobile/4G)
# atm0, atm_0_35 (ADSL/VDSL)

# Update the forwarding rule with correct interface:
uci set firewall.@forwarding[-1].dest='YOUR_WAN_INTERFACE'
uci commit firewall
/etc/init.d/firewall reload

# Verify
uci show firewall.@forwarding | grep dest
```

---

## Interface Issues

### Problem: wt0 Interface Disappears After Reboot

**Symptoms:**
- Interface exists until you reboot
- After reboot, `ip addr show wt0` fails
- NetBird status shows disconnected

**Diagnosis:**

```bash
# Check if interface config is persistent
uci show network.netbird

# Check NetBird is enabled to auto-start
ls -la /etc/rc.d/*netbird* | grep S
```

**Solution:**

```bash
# Ensure UCI config exists
uci show network.netbird

# If missing, recreate:
uci set network.netbird='interface'
uci set network.netbird.proto='none'
uci set network.netbird.device='wt0'
uci commit network

# Ensure NetBird is enabled
/etc/init.d/netbird enable

# Verify both are set to auto-start
ls -la /etc/rc.d/S*/netbird
uci show network.netbird
```

### Problem: MTU Issues (Packet Fragmentation)

**Symptoms:**
- Connection works but is slow
- Large file transfers fail
- `ping` works but `curl` doesn't

**Diagnosis:**

```bash
# Check current MTU
ip link show wt0 | grep mtu

# Test different MTU sizes
ping -M do -s 1472 8.8.8.8  # Should work
ping -M do -s 1473 8.8.8.8  # Might fail
```

**Normal NetBird MTU:** 1280 bytes

**Solution:**

```bash
# Set MTU manually (if needed)
ip link set dev wt0 mtu 1280

# Make persistent - add to network config:
uci set network.netbird.mtu='1280'
uci commit network
/etc/init.d/network reload
```

---

## Connectivity Issues

### Problem: Can't Ping Exit Node from Remote Peer

**Symptoms:**
- Can ping other peers but not exit node
- Dashboard shows exit node connected
- Local routing works fine

**Diagnosis:**

```bash
# On remote peer, check if exit node is reachable
ping 100.99.5.103  # Replace with your exit node IP

# On exit node, check if routes are correct
ip route | grep 100

# Check if NetBird is actually listening
netbird status -d
```

**Solutions:**

**Solution 1: Verify Exit Node Assignment**
In NetBird Dashboard:
1. Go to Network Routing → Routes
2. Find your router
3. Toggle "Exit node" ON
4. Set "Distribution group" to "All"
5. Wait 30 seconds for config to propagate

**Solution 2: Restart NetBird**
```bash
netbird down
sleep 3
netbird up --setup-key YOUR_SETUP_KEY

# If that doesn't work:
/etc/init.d/netbird restart
sleep 10
netbird status
```

**Solution 3: Check Firewall Rules**
```bash
# Make sure traffic through exit node is allowed
uci show firewall | grep -E "(netbird|masq)"

# Verify masquerading is enabled
uci get firewall.@zone[-1].masq
# Should return: 1
```

### Problem: Traffic Goes Through Exit Node But No Internet

**Symptoms:**
- Peers can reach exit node IP (100.x.x.x)
- Can't access external websites
- `ping 8.8.8.8` fails from remote peer

**Diagnosis:**

```bash
# On exit node, test internet access locally
ping 8.8.8.8
curl https://api.netbird.io/  # Test NetBird API

# Check if traffic is actually being forwarded
iptables -t nat -L -n -v | grep -i forward

# Check routing on exit node
ip route | grep default
```

**Solutions:**

**Solution 1: Enable IP Forwarding**
```bash
# Check if enabled
sysctl net.ipv4.ip_forward
# Should return: 1

# If not:
sysctl -w net.ipv4.ip_forward=1

# Make permanent:
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
```

**Solution 2: Check Default Route**
```bash
# Your exit node needs a default route to internet
ip route | grep default

# Example output:
# default via 192.168.1.1 dev eth0  metric 100

# If missing, add it:
ip route add default via YOUR_GATEWAY_IP dev YOUR_WAN_IFACE
```

**Solution 3: Enable Masquerading**
```bash
# Verify masquerading is enabled
uci get firewall.@zone[-1].masq

# If not 1:
uci set firewall.@zone[-1].masq='1'
uci commit firewall
/etc/init.d/firewall reload
```

---

## Performance Issues

### Problem: Slow Internet Speed Through Exit Node

**Symptoms:**
- Speed test shows 10% of normal speed
- Download is throttled
- Upload seems normal

**Diagnosis:**

```bash
# Check router CPU usage
top

# Check memory usage
free -m

# Check network stats
vnstat -h

# Check if packet loss
mtr -c 10 8.8.8.8
```

**Solutions:**

**Solution 1: Reduce Peer Load**
- In NetBird Dashboard, reduce number of peers using this exit node
- Implement QoS limits per peer

**Solution 2: Upgrade Router Resources**
- Check if router is hitting CPU/memory limits
- Consider upgrading to router with more RAM
- Look for hardware with better processor

**Solution 3: Enable Hardware Offloading (If Available)**
```bash
# Check available offloading features
ethtool -k eth0 | grep -i offload

# Enable if available (router-specific)
ethtool -K eth0 gso on
ethtool -K eth0 gro on
ethtool -K eth0 tso on
```

### Problem: High Latency / Packet Loss

**Symptoms:**
- High ping times (>200ms)
- Intermittent packet loss
- Connection feels unstable

**Diagnosis:**

```bash
# Check latency to various points
ping -c 10 100.99.5.103           # Exit node
ping -c 10 8.8.8.8                 # Internet
mtr -c 100 8.8.8.8| grep Loss

# Check if router is overloaded
top -b -n 1 | head -10
```

**Solutions:**

**Solution 1: Check Wi-Fi If Applicable**
```bash
# If using Wi-Fi connection to NetBird:
# Use wired Ethernet for more stable connection
# Move closer to router
# Check for interference: WiFi Analyzer app
```

**Solution 2: Limit Concurrent Peers**
```bash
# Reduce number of peers using this exit node
# In NetBird Dashboard, adjust distribution groups
```

**Solution 3: Check ISP Connection**
```bash
# Test direct internet speed (not through NetBird)
speedtest-cli

# Check ISP connection quality
ping -c 100 8.8.8.8 | grep -E "min|avg|max"

# Contact ISP if high packet loss (>1%)
```

---

## Advanced Debugging

### Enable Debug Logging

```bash
# Set NetBird to debug mode
GOLOG_LEVEL=debug netbird up

# Or in daemon:
# Edit /etc/init.d/netbird and add GOLOG_LEVEL=debug
```

### Check NetBird Version Compatibility

```bash
# Check installed version
netbird version

# Visit GitHub to see if there are known issues:
# https://github.com/netbirdio/netbird/releases

# Update if needed:
apk update
apk upgrade netbird
```

### Monitor Active Connections

```bash
# See all established connections
netstat -tlnp | grep netbird

# Monitor bandwidth in real-time
iftop -i wt0

# Check packet statistics
ip -s link show wt0
```

### Test Specific Routes

```bash
# Trace route to exit node
traceroute 100.99.5.103

# Trace route to external host through exit node
mtr 8.8.8.8
```

### Collect Debug Information

Create debug information bundle:

```bash
# Create temporary directory
mkdir -p /tmp/netbird-debug

# Collect logs
logread > /tmp/netbird-debug/logs.txt
logread | grep netbird > /tmp/netbird-debug/netbird-logs.txt

# Collect config
uci show network > /tmp/netbird-debug/network.txt
uci show firewall > /tmp/netbird-debug/firewall.txt

# Collect system info
netbird status -d > /tmp/netbird-debug/netbird-status.txt
ip addr show > /tmp/netbird-debug/ip-addr.txt
ip route > /tmp/netbird-debug/ip-route.txt
iptables -t nat -L > /tmp/netbird-debug/iptables-nat.txt

# Compress
cd /tmp
tar czf netbird-debug.tar.gz netbird-debug/

# Now you can copy and share this for support:
# scp root@router:/tmp/netbird-debug.tar.gz .
```

---

## Getting Help

If these troubleshooting steps don't resolve your issue:

1. **Collect debug info** using the commands above
2. **Check GitHub Issues**: https://github.com/netbirdio/netbird/issues
3. **Report to NetBird Support**: https://support.netbird.io/
4. **Post in OpenWrt Forum**: https://forum.openwrt.org/

When reporting:
- Include your OpenWrt version
- Include NetBird version
- Attach debug bundle
- Describe exactly what you've tried
- Include any error messages

---

**Last Updated:** 2026-09-08  
**For latest troubleshooting: Check GitHub Issues**
