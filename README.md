# ansible-patroni
Ansible playbook for deploying PostgreSQL Patroni cluster

⚠️ **WARNING: This configuration is for testing/development purposes only. DO NOT use in production without proper security hardening!**

## Overview
This Ansible playbook automates the deployment of a PostgreSQL high-availability cluster using Patroni and etcd. The setup includes the following components for connection management and high availability:
- `Keepalived` creates a Virtual IP (VIP) for failover.
- `HAProxy` acts as a proxy layer for distributing requests.
- `PgBouncer` operates as a connection pooler.
  
The connection path:
```
Keepalived VIP -> HAProxy -> PgBouncer -> PostgreSQL
```

## Prerequisites
- Ubuntu/Debian-based system
- Ansible installed on the control node
- Network connectivity between all nodes

## Components
- PostgreSQL 16
- Patroni
- etcd (for distributed configuration)
- PgBouncer (for connection pooling)
- Keepalived (for VIP)
- HAProxy (for load balancing)
- Python 3 and pip
- Node Exporter (system metrics)
- Postgres Exporter (PostgreSQL metrics)

## Quick Start
1. Clone this repository:
2. Create config files with the command `make init`
3. Update `inventory.ini` with your servers:
```ini
[promoters]
patroni1 ansible_host=192.168.64.2 node_id=1
patroni2 ansible_host=192.168.64.3 node_id=2
patroni3 ansible_host=192.168.64.4 node_id=3 
```
4. Update `ansible.cfg` with your user (root by default).
5. Run the playbooks:
```shell
# Deploy Patroni cluster
make up
```

## Default Configuration

### Network Ports
- PostgreSQL: 5432
- Patroni API: 8008
- etcd client: 2379
- etcd peer: 2380
- HAProxy PostgreSQL (master): 5000
- HAProxy PostgreSQL (replica): 5001
- HAProxy Statistics: 7000
- PgBouncer: 6432
- Node Exporter: 9100
- Postgres Exporter: 9187

### Keepalived Configuration
- VIP: Used for automatic failover between HAProxy instances.
- Configured to determine the `MASTER` node based on its `node_id` in the cluster.

### PgBouncer Configuration
- Connection pooling for PostgreSQL to reduce the overhead of establishing frequent connections.
- Default port: `6432`.
- Authentication method: Userlist file.
- Configurations stored in `/etc/pgbouncer/pgbouncer.ini`.

### PostgreSQL Settings
- Version: 16
- Encoding: UTF8
- Max Connections: 100
- Shared Buffers: 256MB
- WAL Level: replica
- Shared Preload Libraries: pg_stat_statements, auto_explain

### Patroni Settings
- TTL: 30
- Loop Wait: 10
- Retry Timeout: 10
- Max Lag: 1048576
- Uses pg_rewind: true
- Uses replication slots: true

### Authentication (Default)
⚠️ Change these values:
- PostgreSQL superuser: postgres/password
- Replication user: replicator/password

### Monitoring Components
#### Node Exporter
- Version: 1.9.1
- Metrics Port: 9100
- Systemd Service: node_exporter.service
- User: node_exporter

#### Postgres Exporter
- Version: 0.17.1
- Metrics Port: 9187
- Systemd Service: postgres_exporter.service
- User: postgres
- Config Path: /etc/postgres_exporter/postgres_exporter.yaml

## Important Security Notes
This deployment includes several configurations that are NOT suitable for production:
- Basic default passwords
- Non-encrypted connections
- Root SSH access
- No SSL/TLS configuration
- No firewall setup
- Basic authentication methods

## Logging
- Patroni logs: /var/log/patroni/patroni.log
- etcd logs: /var/log/etcd.log
- PgBouncer logs: /var/log/pgbouncer/pgbouncer.log
- Log rotation is configured for Patroni logs (7 days retention)
- Node Exporter logs: journalctl -u node_exporter
- Postgres Exporter logs: journalctl -u postgres_exporter
- Keepalived logs: journalctl -u keepalived

## Service Management
``` bash
# Patroni service
systemctl status patroni
systemctl start patroni
systemctl stop patroni

# etcd service
systemctl status etcd
systemctl start etcd
systemctl stop etcd

# HAProxy service
systemctl status haproxy
systemctl start haproxy
systemctl stop haproxy

# PgBouncer service
systemctl status pgbouncer
systemctl start pgbouncer
systemctl stop pgbouncer

# Keepalived service
systemctl status keepalived
systemctl start keepalived
systemctl stop keepalived

# Monitoring services
systemctl status node_exporter
systemctl status postgres_exporter
```

## Monitoring
### Available Metrics
- System metrics (via node_exporter): http://host:9100/metrics
- PostgreSQL metrics (via postgres_exporter): http://host:9187/metrics

### PostgreSQL Exporter Metrics
Postgres Exporter provides the following metric groups:

#### PostgreSQL Settings
- Monitors PostgreSQL configuration parameters
- Collects values from all pg_settings entries
- Includes parameter name, value, unit, and a short description
- Exposed as GAUGE metrics

#### Replication Status
- Instance replication status monitoring:
  - Master/replica state detection
  - Master status monitoring (is_master metric)
  - Replica status monitoring (is_replica metric)
  - Replication lag monitoring in seconds (lag_seconds metric)
  - All metrics are exposed as a GAUGE type

#### Connection Statistics
- Detailed connection statistics:
  - Number of connections by state (active, idle, etc.)
  - Grouped by wait event types
  - Total connection count monitoring by different states
  - Exposed as GAUGE metrics with state and wait_event_type labels
