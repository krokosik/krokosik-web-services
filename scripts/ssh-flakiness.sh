# Solve common flakiness with SSH and help with large lists
sudo tee /etc/docker/daemon.json >/dev/null <<'EOF'
net.ipv4.tcp_mtu_probing=1
vm.swappiness=10
vm.vfs_cache_pressure = 50
fs.inotify.max_user_watches=262144
EOF