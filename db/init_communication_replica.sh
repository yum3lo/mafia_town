#!/bin/bash
set -e

echo "Waiting for primary to be ready..."
until pg_isready -h postgres_communication_primary -p 5432 -U "$POSTGRES_USER"
do
  echo "Waiting for primary database to accept connections..."
  sleep 2
done

echo "Stopping PostgreSQL..."
pg_ctl -D "$PGDATA" -m fast -w stop || true

echo "Cleaning data directory..."
rm -rf "$PGDATA"/*

echo "Running pg_basebackup from primary..."
pg_basebackup -h postgres_communication_primary -D "$PGDATA" -U replicator -v -P -W

echo "Configuring standby settings..."
cat > "$PGDATA/postgresql.auto.conf" <<EOF
primary_conninfo = 'host=postgres_communication_primary port=5432 user=replicator password=$PG_REPLICATION_PASSWORD'
primary_slot_name = '$REPLICATION_SLOT'
hot_standby = on
EOF

touch "$PGDATA/standby.signal"

echo "Starting PostgreSQL in standby mode..."
pg_ctl -D "$PGDATA" -w start
