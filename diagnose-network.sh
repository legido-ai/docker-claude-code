#!/bin/bash
#
# Docker Network Diagnostic Script for Claude Code
# Diagnoses network connectivity issues between Docker containers and Anthropic API
#
# Usage: ./diagnose-network.sh > network-diagnostic.log 2>&1
#

set -e

echo "======================================================================"
echo "Docker Network Diagnostic for Claude Code"
echo "======================================================================"
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

section() {
    echo ""
    echo "======================================================================"
    echo "$1"
    echo "======================================================================"
}

subsection() {
    echo ""
    echo "----------------------------------------------------------------------"
    echo "$1"
    echo "----------------------------------------------------------------------"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

section "SYSTEM INFORMATION"

subsection "OS Information"
if [ -f /etc/os-release ]; then
    cat /etc/os-release
else
    uname -a
fi

subsection "Kernel Version"
uname -r

subsection "System Uptime"
uptime

subsection "Last System Updates/Changes (if available)"
if command_exists journalctl; then
    echo "Recent system changes from journal (last 7 days):"
    journalctl --since "7 days ago" | grep -i "network\|docker\|firewall\|iptables" | tail -50 || echo "No relevant journal entries found"
fi

section "DOCKER CONFIGURATION"

subsection "Docker Version"
docker version || echo "ERROR: Docker not available"

subsection "Docker Info"
docker info || echo "ERROR: Docker info failed"

subsection "Docker Daemon Configuration"
if [ -f /etc/docker/daemon.json ]; then
    echo "Contents of /etc/docker/daemon.json:"
    cat /etc/docker/daemon.json
else
    echo "No /etc/docker/daemon.json found (using defaults)"
fi

subsection "Docker Systemd Service Status"
if command_exists systemctl; then
    systemctl status docker --no-pager || echo "Cannot get Docker systemd status"
fi

subsection "Docker Networks"
docker network ls

subsection "Docker Bridge Network Inspection"
docker network inspect bridge || echo "ERROR: Cannot inspect bridge network"

subsection "Docker Default Bridge Configuration"
ip addr show docker0 2>/dev/null || echo "docker0 bridge not found"
brctl show docker0 2>/dev/null || echo "Cannot show docker0 bridge details (brctl may not be installed)"

section "NETWORK CONFIGURATION"

subsection "Network Interfaces"
ip addr show

subsection "Network Routes"
ip route show

subsection "Default Gateway"
ip route | grep default

subsection "Routing Tables"
ip route show table all

subsection "DNS Configuration"
echo "Contents of /etc/resolv.conf:"
cat /etc/resolv.conf

subsection "DNS Servers in Use"
if command_exists resolvectl; then
    resolvectl status
elif command_exists systemd-resolve; then
    systemd-resolve --status
fi

section "FIREWALL CONFIGURATION"

subsection "IPTables Rules - Filter Table"
sudo iptables -L -n -v --line-numbers || iptables -L -n -v --line-numbers 2>/dev/null || echo "Cannot list iptables rules (need sudo)"

subsection "IPTables Rules - NAT Table"
sudo iptables -t nat -L -n -v --line-numbers || iptables -t nat -L -n -v --line-numbers 2>/dev/null || echo "Cannot list NAT rules (need sudo)"

subsection "IPTables Rules - Mangle Table"
sudo iptables -t mangle -L -n -v --line-numbers || iptables -t mangle -L -n -v --line-numbers 2>/dev/null || echo "Cannot list mangle rules (need sudo)"

subsection "UFW Status (if installed)"
if command_exists ufw; then
    sudo ufw status verbose || ufw status verbose 2>/dev/null || echo "Cannot check UFW status"
else
    echo "UFW not installed"
fi

subsection "Firewalld Status (if installed)"
if command_exists firewall-cmd; then
    sudo firewall-cmd --list-all || firewall-cmd --list-all 2>/dev/null || echo "Cannot check firewalld status"
else
    echo "firewalld not installed"
fi

section "DOCKER CONTAINER NETWORKING"

subsection "Running Containers"
docker ps -a

subsection "Container Network Namespaces"
for container in $(docker ps -q); do
    echo "Container: $(docker inspect --format='{{.Name}}' $container)"
    echo "Network Mode: $(docker inspect --format='{{.HostConfig.NetworkMode}}' $container)"
    echo "Networks: $(docker inspect --format='{{json .NetworkSettings.Networks}}' $container | python3 -m json.tool 2>/dev/null || cat)"
    echo ""
done

section "CONNECTIVITY TESTS"

subsection "Host DNS Resolution to Anthropic Domains"
for domain in api.anthropic.com claude.ai; do
    echo "Resolving $domain:"
    nslookup $domain || echo "nslookup failed for $domain"
    dig $domain +short || echo "dig failed (may not be installed)"
    echo ""
done

subsection "Host Direct Connectivity to Anthropic API"
echo "Testing HTTPS connectivity to api.anthropic.com:443"
timeout 5 bash -c "cat < /dev/null > /dev/tcp/api.anthropic.com/443" 2>/dev/null && echo "SUCCESS: Can connect to api.anthropic.com:443" || echo "FAILED: Cannot connect to api.anthropic.com:443"

echo ""
echo "Testing with curl (if available):"
if command_exists curl; then
    curl -v -m 10 https://api.anthropic.com 2>&1 | head -20 || echo "curl failed"
else
    echo "curl not installed"
fi

subsection "Test from Docker Container (bridge network)"
echo "Creating test container with bridge network..."
docker run --rm --network bridge alpine:latest sh -c "
echo 'DNS Configuration in container:';
cat /etc/resolv.conf;
echo '';
echo 'Resolving api.anthropic.com:';
nslookup api.anthropic.com || echo 'nslookup failed';
echo '';
echo 'Testing connectivity to api.anthropic.com:443';
timeout 5 sh -c 'cat < /dev/null > /dev/tcp/api.anthropic.com/443' 2>/dev/null && echo 'SUCCESS' || echo 'FAILED';
echo '';
echo 'Testing with wget:';
wget -O- --timeout=10 https://api.anthropic.com 2>&1 | head -20 || echo 'wget failed';
" 2>&1 || echo "ERROR: Test container failed"

subsection "Test from Docker Container (host network)"
echo "Creating test container with host network..."
docker run --rm --network host alpine:latest sh -c "
echo 'DNS Configuration in container:';
cat /etc/resolv.conf;
echo '';
echo 'Resolving api.anthropic.com:';
nslookup api.anthropic.com || echo 'nslookup failed';
echo '';
echo 'Testing connectivity to api.anthropic.com:443';
timeout 5 sh -c 'cat < /dev/null > /dev/tcp/api.anthropic.com/443' 2>/dev/null && echo 'SUCCESS' || echo 'FAILED';
echo '';
echo 'Testing with wget:';
wget -O- --timeout=10 https://api.anthropic.com 2>&1 | head -20 || echo 'wget failed';
" 2>&1 || echo "ERROR: Test container with host network failed"

section "DOCKER BRIDGE NETWORK DETAILS"

subsection "Bridge Network MTU"
ip link show docker0 | grep mtu || echo "Cannot get docker0 MTU"

subsection "IP Forwarding Status"
echo "IP Forwarding enabled: $(cat /proc/sys/net/ipv4/ip_forward)"

subsection "Docker IP Masquerading"
iptables -t nat -L POSTROUTING -n -v 2>/dev/null | grep MASQUERADE || echo "No MASQUERADE rules found"

section "PROXY CONFIGURATION"

subsection "Environment Proxy Variables"
echo "HTTP_PROXY: ${HTTP_PROXY:-not set}"
echo "HTTPS_PROXY: ${HTTPS_PROXY:-not set}"
echo "NO_PROXY: ${NO_PROXY:-not set}"
echo "http_proxy: ${http_proxy:-not set}"
echo "https_proxy: ${https_proxy:-not set}"
echo "no_proxy: ${no_proxy:-not set}"

subsection "Docker Daemon Proxy Configuration"
if [ -d /etc/systemd/system/docker.service.d ]; then
    echo "Docker systemd drop-in files:"
    ls -la /etc/systemd/system/docker.service.d/
    for file in /etc/systemd/system/docker.service.d/*.conf; do
        if [ -f "$file" ]; then
            echo ""
            echo "Contents of $file:"
            cat "$file"
        fi
    done
else
    echo "No systemd drop-in configuration for Docker found"
fi

section "NETWORK PERFORMANCE"

subsection "Ping Statistics to Google DNS"
ping -c 4 8.8.8.8 || echo "Cannot ping 8.8.8.8"

subsection "Ping Statistics to Anthropic API"
ping -c 4 api.anthropic.com || echo "Cannot ping api.anthropic.com"

subsection "Traceroute to Anthropic API"
if command_exists traceroute; then
    traceroute -m 15 -w 2 api.anthropic.com || echo "traceroute failed"
elif command_exists tracepath; then
    tracepath -m 15 api.anthropic.com || echo "tracepath failed"
else
    echo "Neither traceroute nor tracepath available"
fi

section "RECENT LOG ANALYSIS"

subsection "Docker Daemon Logs (last 100 lines)"
if command_exists journalctl; then
    journalctl -u docker --no-pager -n 100 || echo "Cannot access docker logs"
else
    tail -100 /var/log/docker.log 2>/dev/null || echo "Cannot access docker logs"
fi

subsection "Kernel Network Messages (last 50 lines)"
if command_exists journalctl; then
    journalctl -k --no-pager -n 50 | grep -i "network\|docker\|bridge" || echo "No relevant kernel messages"
fi

section "DOCKER COMPOSE CONFIGURATION"

if [ -f docker-compose.yml ]; then
    subsection "Current docker-compose.yml"
    cat docker-compose.yml
elif [ -f ../docker-compose.yml ]; then
    subsection "Current docker-compose.yml"
    cat ../docker-compose.yml
else
    echo "No docker-compose.yml found in current or parent directory"
fi

section "SUMMARY AND RECOMMENDATIONS"

echo ""
echo "Diagnostic complete. Review the output above for:"
echo "  1. DNS resolution failures in bridge network vs host network"
echo "  2. Firewall rules blocking Docker container traffic"
echo "  3. MTU mismatches between docker0 and host interfaces"
echo "  4. Recent system updates that changed network configuration"
echo "  5. Proxy settings interfering with container networking"
echo "  6. IP forwarding disabled on the host"
echo "  7. IPTables MASQUERADE rules missing or incorrect"
echo ""
echo "Compare this output with a working host to identify differences."
echo ""
echo "======================================================================"
echo "Diagnostic Complete - $(date)"
echo "======================================================================"
