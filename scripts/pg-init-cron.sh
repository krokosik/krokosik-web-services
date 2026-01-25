#!/bin/bash
set -e

# Detect POSTGRES_MAJOR if not set
if [ -z "$POSTGRES_MAJOR" ]; then
    POSTGRES_MAJOR=$(pg_config --version | awk '{print $2}' | cut -d. -f1)
fi

# Update package list
apt update

# Install pg_cron for the detected PostgreSQL major version
apt install -y postgresql-${POSTGRES_MAJOR}-cron

# Clean up apt cache
rm -rf /var/lib/apt/lists/*