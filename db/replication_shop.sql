ALTER SYSTEM SET listen_addresses = '*';
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replica_pass';
