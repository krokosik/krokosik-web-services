#!/usr/bin/bash

# Check if required arguments are provided
if [ $# -ne 4 ]; then
    echo "Usage: $0 <postgres_user> <db_name> <db_user> <password>"
    exit 1
fi

POSTGRES_USER="$1"
DB_NAME="$2"
DB_USER="$3"
PASSWORD="$4"

# Function to execute SQL queries in PostgreSQL container
run_psql() {
    local query="$1"
    docker exec -it postgresql psql -U "$POSTGRES_USER" -c "$query"
}

# Create a new database and user for $DB_NAME
run_psql "CREATE DATABASE $DB_NAME;"
run_psql "CREATE USER $DB_USER WITH PASSWORD '$PASSWORD';"

# Grant privileges to the new user on the new database
run_psql "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# Change the owner of the database and grant additional privileges
run_psql "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"
run_psql "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;"
run_psql "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;"
run_psql "GRANT CREATE ON SCHEMA public TO $DB_USER;"