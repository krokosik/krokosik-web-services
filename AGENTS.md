# AGENTS.md

> Guidelines for AI agents working in this Docker Compose homelab infrastructure repository.

## Project Overview

This repository manages a self-hosted homelab infrastructure using Docker Compose. Services are organized into modular compose files under `compose/kwsd/` and orchestrated via the main `docker-compose-kwsd.yml` file.

### Service Categories

| Category | Services |
|----------|----------|
| **Core** | Traefik, Authentik, Socket-proxy, Watchtower, Gluetun, CrowdSec |
| **Media (Starr)** | Sonarr, Radarr, Bazarr, Prowlarr, Jellyfin, Seerr, Tdarr, qBittorrent |
| **Databases** | PostgreSQL, Redis, Immich-DB (Postgres+pgvector) |
| **Monitoring** | Grafana, Prometheus, Loki, Alloy, Dozzle |
| **Apps** | Immich, Firefly III, Shlink |

## Commands

### Docker Compose Operations

```bash
# Start all services (uses HOSTNAME from .env to find compose files)
docker compose -f docker-compose-kwsd.yml up -d

# Start specific profile
docker compose -f docker-compose-kwsd.yml --profile core up -d
docker compose -f docker-compose-kwsd.yml --profile media up -d
docker compose -f docker-compose-kwsd.yml --profile all up -d

# Stop all services
docker compose -f docker-compose-kwsd.yml down

# View logs for a service
docker compose -f docker-compose-kwsd.yml logs -f <service-name>

# Restart a single service
docker compose -f docker-compose-kwsd.yml restart <service-name>

# Pull latest images and recreate
docker compose -f docker-compose-kwsd.yml pull
docker compose -f docker-compose-kwsd.yml up -d --force-recreate
```

### Single Service Operations

```bash
# Restart just one service (e.g., sonarr)
docker compose -f docker-compose-kwsd.yml restart sonarr

# View logs for one service
docker compose -f docker-compose-kwsd.yml logs -f traefik

# Rebuild/recreate single service
docker compose -f docker-compose-kwsd.yml up -d --force-recreate sonarr
```

### Utility Scripts

```bash
# Create new PostgreSQL database
./scripts/pg_add_db.sh <postgres_user> <db_name> <db_user> <password>

# Configure Docker daemon (run once during setup)
./scripts/docker.sh

# Setup UFW firewall rules
./scripts/firewall.sh
```

## Directory Structure

```
├── docker-compose-kwsd.yml    # Main orchestration file
├── compose/kwsd/              # Individual service compose files (*.yml)
├── appdata/                   # Persistent service data (gitignored)
├── scripts/                   # Setup and utility shell scripts
├── secrets/                   # Docker secrets files (gitignored)
├── logs/kwsd/                 # Service logs (gitignored)
└── .env                       # Environment variables (gitignored)
```

## Docker Compose Conventions

### Service Template

When adding or modifying services, follow this structure:

```yaml
services:
  # ServiceName - Brief description
  service-name:
    image: registry/image:$SERVICE_VERSION  # Use version var from .env
    container_name: service-name
    security_opt:
      - no-new-privileges:true              # REQUIRED on all containers
    restart: unless-stopped                  # Or "no" for non-critical
    profiles: ["category", "all"]           # core, media, starr, apps, all
    networks:
      - traefik_proxy                       # For web-accessible services
      - default                             # For internal communication
    ports:
      - "$SERVICE_PORT:8080"                # Use port var from .env
    volumes:
      - $DOCKERDIR/appdata/service:/config
      - /etc/localtime:/etc/localtime:ro
    environment:
      TZ: $TZ
      PUID: $PUID
      PGID: $PGID
    secrets:
      - service_secret
    labels:
      - "traefik.enable=true"
      # See Traefik Labels section below
```

### Traefik Labels Pattern

```yaml
labels:
  - "traefik.enable=true"
  # HTTP Routers
  - "traefik.http.routers.service-rtr.entrypoints=websecure"
  - "traefik.http.routers.service-rtr.rule=Host(`service.$DOMAIN_NAME`)"
  # Middlewares (choose one)
  - "traefik.http.routers.service-rtr.middlewares=chain-no-auth@file"      # No auth
  - "traefik.http.routers.service-rtr.middlewares=chain-authentik@file"    # SSO auth
  # HTTP Services
  - "traefik.http.routers.service-rtr.service=service-svc"
  - "traefik.http.services.service-svc.loadbalancer.server.port=8080"
  # Watchtower (for version-pinned images)
  - "com.centurylinklabs.watchtower.enable=false"
```

### Profiles

| Profile | Purpose |
|---------|---------|
| `core` | Essential infrastructure (Traefik, Authentik, databases) |
| `media` | Media server services (Jellyfin, Seerr) |
| `starr` | *arr stack (Sonarr, Radarr, Prowlarr, etc.) |
| `apps` | Application services (Immich, Firefly III) |
| `all` | All services |

## Network Architecture

| Network | Subnet | Purpose |
|---------|--------|---------|
| `traefik_proxy` | 192.168.90.0/24 | External-facing services behind reverse proxy |
| `socket_proxy` | 192.168.91.0/24 | Secure Docker socket access |
| `default` | auto | Internal service-to-service communication |

- Services exposed via Traefik must join `traefik_proxy`
- Services needing Docker API use `socket_proxy` (never mount socket directly)
- Database connections use `default` network

## Secrets Management

### Declaring Secrets (in main compose file)

```yaml
secrets:
  service_secret:
    file: $DOCKERDIR/secrets/service_secret
```

### Using Secrets in Services

```yaml
environment:
  DB_PASSWORD_FILE: /run/secrets/service_db_password  # _FILE suffix pattern
secrets:
  - service_db_password
```

### Secret Files Location

All secrets stored in `$DOCKERDIR/secrets/` as plain text files (gitignored).

## Security Guidelines

1. **Always set** `security_opt: no-new-privileges:true` on every container
2. **Never mount** `/var/run/docker.sock` directly - use socket-proxy
3. **Use Docker secrets** for sensitive data, not environment variables
4. **Disable Watchtower** for version-pinned images: `com.centurylinklabs.watchtower.enable=false`
5. **Pin image versions** using `$SERVICE_VERSION` vars for critical services
6. **Use internal networks** for database connections (don't expose ports)

## Adding a New Service

1. Create `compose/kwsd/servicename.yml` following the template above
2. Add version variable to `.env`: `SERVICENAME_VERSION=latest`
3. Add port variable to `.env`: `SERVICENAME_PORT=xxxx`
4. If service needs secrets, create file in `secrets/` and declare in main compose
5. Add include line to `docker-compose-kwsd.yml`:
   ```yaml
   - compose/$HOSTNAME/servicename.yml
   ```
6. Create data directory: `mkdir -p appdata/servicename`
7. Start service: `docker compose -f docker-compose-kwsd.yml up -d servicename`

## Environment Variables

Key variables expected in `.env`:

| Variable | Purpose |
|----------|---------|
| `HOSTNAME` | Server hostname (e.g., `kwsd`) |
| `DOCKERDIR` | Base path for Docker files |
| `DOMAIN_NAME` | Public domain for services |
| `TAILSCALE_DOMAIN_NAME` | Internal Tailscale domain |
| `TZ` | Timezone (e.g., `Europe/Warsaw`) |
| `PUID` / `PGID` | User/Group ID for file permissions |
| `POSTGRES_USER` | Default PostgreSQL admin user |
| `*_VERSION` | Image version tags per service |
| `*_PORT` | Port mappings per service |

## Infrastructure Notes

### Docker Daemon

Configured via `scripts/docker.sh`:
- JSON logging with 10MB rotation
- Uses host DNS resolver at 172.17.0.1
- Docker bridge at 172.17.0.0/16

### Firewall (UFW)

Configured via `scripts/firewall.sh`:
- Default deny incoming/outgoing
- Allows DNS, NTP, HTTP/S, SMTP outbound
- Cloudflare QUIC (7844/udp) for tunnel
- Tailscale interface allowed inbound, denied outbound
- Uses `ufw-docker` for container network protection

### VPN (Gluetun)

- qBittorrent routes through Gluetun container
- ProtonVPN WireGuard connection
- Port forwarding enabled for torrents
- *arr apps do NOT use VPN (connect directly)
