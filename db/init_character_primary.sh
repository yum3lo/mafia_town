#!/bin/bash
set -e

echo "Creating replicator user..."
psql -v ON_ERROR_STOP=1 --username "$PG_CHARACTER_USER" --dbname "$PG_CHARACTER_DB" <<-EOSQL
    CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD '$POSTGRES_REPLICATION_PASSWORD';
    SELECT pg_create_physical_replication_slot('replica_1_slot');
    SELECT pg_create_physical_replication_slot('replica_2_slot');
EOSQL

echo "Configuring pg_hba.conf for replication..."
echo "host replication replicator 0.0.0.0/0 scram-sha-256" >> "$PGDATA/pg_hba.conf"
