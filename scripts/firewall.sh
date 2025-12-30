sudo ufw --force reset

# Allow nothing in, everything out
sudo ufw default deny incoming comment 'deny all incoming traffic'
sudo ufw default deny outgoing comment 'allow all outgoing traffic'

# Allow Docker containers to use DNS on host
sudo ufw allow in proto udp from 172.16.0.0/12 to 172.17.0.1 port 53 comment 'allow-docker-dns'

# allow traffic out to port 53 -- DNS
sudo ufw allow out DNS comment 'allow DNS calls out'
sudo ufw allow out 853 comment 'allow DNS over TLS'

# allow traffic out to port 123 -- NTP
sudo ufw allow out 123 comment 'allow NTP out'

# allow traffic out for HTTP, HTTPS, or FTP
# apt might needs these depending on which sources you're using
sudo ufw allow out http comment 'allow outgoing HTTP traffic'
sudo ufw allow out https comment 'allow outgoing HTTPS traffic'

# Incoming disabled while using CLoudflare Tunnel
# sudo ufw allow http comment 'allow HTTP traffic'
# sudo ufw allow https comment 'allow HTTPS traffic'
# sudo ufw allow out ftp comment 'allow FTP traffic out'
sudo ufw allow out 7844/udp comment 'allow cloudflare quic'

# allow whois
sudo ufw allow out whois comment 'allow whois'

# allow mails for status notifications -- choose port according to your provider
sudo ufw allow out SMTP

# allow traffic out to port 68 -- the DHCP client
# you only need this if you're using DHCP
sudo ufw allow out 67 comment 'allow the DHCP client to update'
sudo ufw allow out 68 comment 'allow the DHCP client to update'

# Allow all incoming connections for Tailscale
sudo ufw allow in on tailscale0
# Deny all outgoing connections for Tailscale in case the public node is compromised
sudo ufw deny out on tailscale0

# Turn on the firewall
sudo ufw --force enable

# Enable UFW systemd service to start on boot
sudo systemctl enable ufw

# Turn on Docker protections
sudo ufw-docker install
sudo ufw reload
