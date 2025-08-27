#!/bin/bash

set -e

echo ">>> Tworzenie konfiguracji vmbr1 w /etc/network/interfaces..."

# Dodaj konfigurację mostka vmbr1
cat << 'EOF' >> /etc/network/interfaces

auto vmbr1
iface vmbr1 inet static
    address 10.0.0.1
    netmask 255.255.255.0
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    post-up echo 1 > /proc/sys/net/ipv4/ip_forward
    post-up iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o vmbr0 -j MASQUERADE
    post-down iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -o vmbr0 -j MASQUERADE
EOF

echo ">>> Włączanie IP forwarding w /etc/sysctl.conf..."

# Ustaw ip_forward na stałe
if grep -q "^net.ipv4.ip_forward=" /etc/sysctl.conf; then
    sed -i 's/^net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
else
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi

echo ">>> Przeładowanie ustawień sysctl..."
sysctl -p

echo ">>> Restartowanie vmbr1..."
ifdown vmbr1 || true
ifup vmbr1

echo ">>> Gotowe!"
