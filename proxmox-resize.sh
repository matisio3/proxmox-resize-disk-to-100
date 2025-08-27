#!/bin/bash

set -e  # Zatrzymaj skrypt przy pierwszym błędzie

echo ">>> Usuwanie logicznych wolumenów data..."
lvremove -y pve/data || echo "LV pve/data nie istnieje – pomijam"
lvremove -y pve/data_tmeta || echo "LV pve/data_tmeta nie istnieje – pomijam"
lvremove -y pve/data_tdata || echo "LV pve/data_tdata nie istnieje – pomijam"

echo ">>> Rozszerzanie partycji root o wolne miejsce..."
lvextend -l +100%FREE /dev/pve/root
resize2fs /dev/pve/root

echo ">>> Sprawdzanie rozmiaru partycji..."
df -h
df -hT /

echo ">>> Tworzenie katalogów..."
mkdir -p /mnt/pveroot-vm/images
mkdir -p /mnt/pveroot-vm/template/cache
mkdir -p /mnt/pveroot-vm/dump

echo ">>> Montowanie katalogu images do /mnt/pveroot-vm..."
mount --bind /mnt/pveroot-vm/images /mnt/pveroot-vm

echo ">>> Ustawianie uprawnień..."
chown -R root:root /mnt/pveroot-vm
chmod 755 /mnt/pveroot-vm

echo ">>> Dodawanie konfiguracji storage do /etc/pve/storage.cfg..."
STORAGE_CFG="/etc/pve/storage.cfg"
if ! grep -q "dir: root-vm" "$STORAGE_CFG"; then
cat <<EOF >> $STORAGE_CFG

dir: root-vm
    path /mnt/pveroot-vm
    content iso,vztmpl,backup,images,rootdir
    maxfiles 3
    shared 0
EOF
else
    echo "Konfiguracja root-vm już istnieje – pomijam"
fi

echo ">>> Restart pveproxy..."
systemctl restart pveproxy

echo ">>> Sprawdzanie statusu przestrzeni dyskowej..."
pvesm status

echo ">>> Gotowe!"

