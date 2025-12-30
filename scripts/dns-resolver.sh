# https://wiki.archlinux.org/title/Systemd-resolved
echo "Symlink resolved stub-resolv to /etc/resolv.conf"

sudo systemctl enable systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
