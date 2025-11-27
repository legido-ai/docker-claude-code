# Docker Network Troubleshooting for Claude Code

This guide helps diagnose Docker networking issues that prevent Claude Code from connecting to Anthropic's API.

## Symptoms

- `claude` commands hang and timeout (typically after 30-40 seconds)
- Commands like `/bug` timeout
- `/doctor` command works (doesn't require network)
- Issue resolves when using `network_mode: host` in docker-compose.yml

## Quick Fix (Workaround)

If you're experiencing timeouts, add `network_mode: host` to your `docker-compose.yml`:

```yaml
services:
  claude-code:
    image: ghcr.io/legido-ai/docker-claude-code:latest
    network_mode: host  # Add this line
    # ... rest of configuration
```

**Note:** This is a workaround, not a proper fix. It bypasses Docker's bridge network but has security implications.

## Diagnostic Script

We provide a comprehensive diagnostic script to identify the root cause:

### Running the Diagnostic

```bash
# Run on the problematic host
./diagnose-network.sh > network-diagnostic-broken.log 2>&1

# Run on a working host (if available)
./diagnose-network.sh > network-diagnostic-working.log 2>&1

# Compare the outputs to identify differences
diff network-diagnostic-broken.log network-diagnostic-working.log
```

### What the Script Checks

The diagnostic script gathers information about:

1. **System Information**
   - OS version and kernel
   - Recent system updates/changes
   - System uptime

2. **Docker Configuration**
   - Docker version and daemon config
   - Docker networks and bridge settings
   - Container network namespaces

3. **Network Configuration**
   - Network interfaces and routes
   - DNS configuration
   - Default gateway settings

4. **Firewall Rules**
   - IPTables rules (filter, nat, mangle tables)
   - UFW/firewalld status
   - Docker-specific firewall rules

5. **Connectivity Tests**
   - DNS resolution from host and containers
   - Direct connectivity to api.anthropic.com
   - Comparison: bridge network vs host network

6. **Docker Networking Details**
   - Bridge MTU settings
   - IP forwarding status
   - IP masquerading rules

7. **Proxy Configuration**
   - Environment variables
   - Docker daemon proxy settings

8. **Performance Tests**
   - Ping statistics
   - Traceroute to Anthropic API

## Common Issues and Solutions

### 1. DNS Resolution Failure

**Symptom:** Container cannot resolve `api.anthropic.com`

**Check:**
```bash
# From inside container
docker run --rm alpine nslookup api.anthropic.com
```

**Solutions:**
- Check `/etc/resolv.conf` in the container
- Configure Docker to use specific DNS:
  ```json
  // /etc/docker/daemon.json
  {
    "dns": ["8.8.8.8", "8.8.4.4"]
  }
  ```
- Restart Docker: `sudo systemctl restart docker`

### 2. Firewall Blocking Container Traffic

**Symptom:** Host can reach Anthropic API, but containers cannot

**Check:**
```bash
# Check if FORWARD chain is blocking
sudo iptables -L FORWARD -n -v

# Check Docker NAT rules
sudo iptables -t nat -L -n -v
```

**Solutions:**
- Allow Docker bridge forwarding:
  ```bash
  sudo iptables -A FORWARD -i docker0 -o eth0 -j ACCEPT
  sudo iptables -A FORWARD -i eth0 -o docker0 -j ACCEPT
  ```
- Check if firewalld/UFW is interfering:
  ```bash
  # UFW
  sudo ufw status verbose
  sudo ufw allow from 172.17.0.0/16  # Docker default subnet

  # firewalld
  sudo firewall-cmd --permanent --zone=trusted --add-interface=docker0
  sudo firewall-cmd --reload
  ```

### 3. IP Forwarding Disabled

**Symptom:** Containers can't reach external networks

**Check:**
```bash
cat /proc/sys/net/ipv4/ip_forward
# Should return 1
```

**Solution:**
```bash
# Enable temporarily
sudo sysctl -w net.ipv4.ip_forward=1

# Enable permanently
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 4. MTU Mismatch

**Symptom:** Small packets work, but larger requests timeout

**Check:**
```bash
# Check host interface MTU
ip link show eth0 | grep mtu

# Check docker0 MTU
ip link show docker0 | grep mtu
```

**Solution:**
```json
// /etc/docker/daemon.json
{
  "mtu": 1450
}
```

Then restart Docker: `sudo systemctl restart docker`

### 5. Proxy Configuration Issues

**Symptom:** Containers can't reach external HTTPS endpoints

**Check:**
```bash
# Check environment
env | grep -i proxy

# Check Docker daemon proxy
systemctl show docker --property Environment
```

**Solution:**

Create `/etc/systemd/system/docker.service.d/http-proxy.conf`:
```ini
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:8080"
Environment="HTTPS_PROXY=http://proxy.example.com:8080"
Environment="NO_PROXY=localhost,127.0.0.1,docker-registry.example.com"
```

Then:
```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 6. Docker Bridge Network Corruption

**Symptom:** Docker networking suddenly stops working

**Solution:**
```bash
# Stop Docker
sudo systemctl stop docker

# Remove the bridge
sudo ip link delete docker0

# Restart Docker (it will recreate the bridge)
sudo systemctl start docker
```

### 7. Recent System Updates

**Check what changed:**
```bash
# Check recent package updates (Ubuntu/Debian)
cat /var/log/apt/history.log | grep "2025-11-2[56]"

# Check recent package updates (RHEL/CentOS)
rpm -qa --last | head -50

# Check recent system changes
journalctl --since "2025-11-25" | grep -i "network\|docker\|firewall"
```

Common culprits:
- Kernel updates changing network behavior
- firewalld/UFW updates changing default policies
- Docker updates changing default bridge configuration
- systemd updates affecting service dependencies

## Understanding network_mode: host

When you use `network_mode: host`, the container shares the host's network namespace:

**Advantages:**
- ✅ Bypasses Docker bridge networking entirely
- ✅ Container uses host's DNS directly
- ✅ No NAT overhead
- ✅ Works around bridge network issues

**Disadvantages:**
- ❌ Reduced isolation (container can see all host network interfaces)
- ❌ Port conflicts with host services
- ❌ Less secure (container has more network access)
- ❌ Doesn't work well with port mapping

**When to use it:**
- Temporary workaround while diagnosing the real issue
- Development environments where security is less critical
- Cases where maximum network performance is needed

**Better long-term solution:**
Fix the underlying Docker bridge networking issue rather than using host mode.

## Step-by-Step Diagnosis Process

1. **Verify the problem exists:**
   ```bash
   docker run --rm alpine:latest wget -O- --timeout=10 https://api.anthropic.com
   ```
   If this times out, you have a container networking issue.

2. **Test with host network:**
   ```bash
   docker run --rm --network host alpine:latest wget -O- --timeout=10 https://api.anthropic.com
   ```
   If this works, the issue is specific to bridge networking.

3. **Run the diagnostic script:**
   ```bash
   ./diagnose-network.sh > diagnostic.log 2>&1
   ```

4. **Check DNS resolution:**
   ```bash
   docker run --rm alpine:latest nslookup api.anthropic.com
   ```

5. **Check firewall rules:**
   ```bash
   sudo iptables -L -n -v
   sudo iptables -t nat -L -n -v
   ```

6. **Test with different Docker network:**
   ```bash
   # Create a custom network
   docker network create test-net

   # Test with it
   docker run --rm --network test-net alpine:latest wget -O- --timeout=10 https://api.anthropic.com
   ```

7. **Check for recent system changes:**
   ```bash
   journalctl --since "7 days ago" | grep -i "network\|docker"
   ```

## Comparing Working vs Broken Hosts

If you have access to both a working and broken host, focus on these differences:

1. **IPTables rules** - Different FORWARD chain policies?
2. **DNS configuration** - Different nameservers?
3. **Docker daemon.json** - Different settings?
4. **Kernel version** - Recent kernel update on broken host?
5. **Firewall software** - Different UFW/firewalld rules?
6. **System updates** - What was updated on the broken host?

## Getting Help

When asking for help, include:
1. Output from `diagnose-network.sh`
2. Your `docker-compose.yml`
3. Output from `docker version` and `docker info`
4. Description of when the issue started
5. What changed on the system around that time

## References

- [Docker networking documentation](https://docs.docker.com/network/)
- [Docker bridge network troubleshooting](https://docs.docker.com/network/bridge/)
- [IPTables and Docker](https://docs.docker.com/network/iptables/)
