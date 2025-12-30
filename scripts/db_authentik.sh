#!/usr/bin/bash

# Check if required arguments are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <postgres_user> <authentik_db_user> <authentik_password>"
    exit 1
fi

POSTGRES_USER="$1"
AUTHENTIK_DB_USER="$2"
AUTHENTIK_PASSWORD="$3"

# Function to execute SQL queries in PostgreSQL container
run_psql() {
    local query="$1"
    docker exec -it postgresql psql -U "$POSTGRES_USER" -c "$query"
}

# Create a new database and user for Authentik
run_psql "CREATE DATABASE authentik;"
run_psql "CREATE USER $AUTHENTIK_DB_USER WITH PASSWORD '$AUTHENTIK_PASSWORD';"

# Grant privileges to the new user on the new database
run_psql "GRANT ALL PRIVILEGES ON DATABASE authentik TO $AUTHENTIK_DB_USER;"

# Change the owner of the database and grant additional privileges
run_psql "ALTER DATABASE authentik OWNER TO $AUTHENTIK_DB_USER;"
run_psql "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $AUTHENTIK_DB_USER;"
run_psql "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $AUTHENTIK_DB_USER;"
run_psql "GRANT CREATE ON SCHEMA public TO $AUTHENTIK_DB_USER;"