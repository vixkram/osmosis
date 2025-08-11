# Osmosis Spot-Only Fork Deployment Guide

This guide provides instructions for deploying the Osmosis Spot-Only Fork, which removes all perpetuals and margin trading functionality while maintaining core DEX operations.

## Overview

The Osmosis Spot-Only Fork is a modified version of Osmosis that:
- Removes all perpetuals and margin trading functionality
- Maintains all core DEX features (AMM pools, liquidity provision, swapping)
- Implements governance safeguards to prevent future leverage modules
- Focuses exclusively on spot trading

## Prerequisites

### Hardware Requirements
- **CPU**: Minimum 4 cores (8 cores recommended)
- **RAM**: Minimum 16 GB (32 GB recommended)
- **Storage**: Minimum 500 GB SSD (1 TB recommended)
- **Network**: Stable internet connection with sufficient bandwidth

### Software Requirements
- **Operating System**: Linux (Ubuntu 20.04+ recommended)
- **Go**: Version 1.23 or higher
- **Git**: Latest version
- **Docker**: Latest version (optional, for containerized deployment)

## Configuration

### 1. Spot-Only Configuration

The fork includes a spot-only configuration file at `config/spot-only-fork.toml`. Key settings include:

```toml
[chain]
chain_id = "osmosis-spot-1"
chain_name = "Osmosis Spot-Only DEX"

[governance-safeguards]
enabled = true
disable_leverage_modules = true

[trading]
spot_only = true
max_leverage = 0
margin_trading_enabled = false
perpetual_contracts_enabled = false
```

### 2. Application Configuration

The application configuration in `app/config.go` includes:
- Governance safeguards enabled by default
- Spot-only mode enforced
- Leverage modules disabled

## Deployment Methods

### Method 1: Binary Deployment

#### 1. Clone and Build

```bash
# Clone the repository
git clone https://github.com/your-org/osmosis-spot-fork.git
cd osmosis-spot-fork

# Build the binary
make build

# Install the binary
make install
```

#### 2. Initialize the Node

```bash
# Initialize the node
osmosisd init <node-name> --chain-id osmosis-spot-1

# Create or import a key
osmosisd keys add <key-name>
# OR import existing key
osmosisd keys add <key-name> --recover
```

#### 3. Configure Genesis

```bash
# Download genesis file (if available) or create custom genesis
# For testnet:
osmosisd prepare-genesis testnet osmosis-spot-testnet-1

# For mainnet:
osmosisd prepare-genesis mainnet osmosis-spot-1
```

#### 4. Configure Node

Edit `~/.osmosisd/config/config.toml`:
```toml
# P2P Configuration
[p2p]
laddr = "tcp://0.0.0.0:26656"
persistent_peers = "<peer-list>"
seeds = "<seed-list>"

# RPC Configuration
[rpc]
laddr = "tcp://0.0.0.0:26657"
```

Edit `~/.osmosisd/config/app.toml`:
```toml
# API Configuration
[api]
enable = true
address = "tcp://0.0.0.0:1317"

# gRPC Configuration
[grpc]
enable = true
address = "0.0.0.0:9090"

# Spot-Only Configuration
[spot-only]
enabled = true
chain_id = "osmosis-spot-1"
max_leverage = "0"
disable_margin_trading = true
disable_perpetual_contracts = true

# Governance Safeguards
[governance-safeguards]
enabled = true
disable_leverage_modules = true
```

#### 5. Start the Node

```bash
# Start the node
osmosisd start

# Or run as a service (see systemd section below)
```

### Method 2: Docker Deployment

#### 1. Build Docker Image

```bash
# Build the Docker image
docker build -t osmosis-spot:latest .

# Or use the cosmovisor image
docker build -f Dockerfile.cosmovisor -t osmosis-spot-cosmovisor:latest .
```

#### 2. Run Container

```bash
# Create data directory
mkdir -p ~/.osmosisd

# Run the container
docker run -d \
  --name osmosis-spot \
  -p 26656:26656 \
  -p 26657:26657 \
  -p 1317:1317 \
  -p 9090:9090 \
  -v ~/.osmosisd:/osmosis/.osmosisd \
  osmosis-spot:latest start
```

#### 3. Docker Compose (Recommended)

Create `docker-compose.yml`:
```yaml
version: '3.8'

services:
  osmosis-spot:
    build: .
    container_name: osmosis-spot
    ports:
      - "26656:26656"
      - "26657:26657"
      - "1317:1317"
      - "9090:9090"
    volumes:
      - ~/.osmosisd:/osmosis/.osmosisd
      - ./config/spot-only-fork.toml:/osmosis/config/spot-only-fork.toml
    environment:
      - DAEMON_NAME=osmosisd
      - DAEMON_HOME=/osmosis/.osmosisd
    command: ["start"]
    restart: unless-stopped
```

Run with:
```bash
docker-compose up -d
```

### Method 3: Systemd Service

#### 1. Create Service File

Create `/etc/systemd/system/osmosis-spot.service`:
```ini
[Unit]
Description=Osmosis Spot-Only DEX
After=network-online.target

[Service]
Type=simple
User=osmosis
WorkingDirectory=/home/osmosis
ExecStart=/usr/local/bin/osmosisd start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

#### 2. Enable and Start Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable the service
sudo systemctl enable osmosis-spot

# Start the service
sudo systemctl start osmosis-spot

# Check status
sudo systemctl status osmosis-spot

# View logs
sudo journalctl -u osmosis-spot -f
```

## Network Configuration

### Testnet Deployment

For testnet deployment:
1. Use chain ID: `osmosis-spot-testnet-1`
2. Configure shorter governance voting periods
3. Use testnet genesis parameters
4. Connect to testnet peers

### Mainnet Deployment

For mainnet deployment:
1. Use chain ID: `osmosis-spot-1`
2. Use production genesis parameters
3. Configure proper security settings
4. Connect to mainnet peers

## Security Considerations

### 1. Firewall Configuration

```bash
# Allow SSH
sudo ufw allow 22

# Allow P2P port
sudo ufw allow 26656

# Allow RPC port (restrict to trusted IPs)
sudo ufw allow from <trusted-ip> to any port 26657

# Allow API port (restrict to trusted IPs)
sudo ufw allow from <trusted-ip> to any port 1317

# Enable firewall
sudo ufw enable
```

### 2. Key Management

- Store validator keys securely
- Use hardware security modules (HSM) for production
- Implement proper backup procedures
- Use key rotation policies

### 3. Monitoring

Set up monitoring for:
- Node health and uptime
- Block height synchronization
- Memory and CPU usage
- Disk space usage
- Network connectivity

## Validation and Testing

### 1. Verify Spot-Only Mode

```bash
# Check that leverage modules are disabled
osmosisd query gov params

# Verify governance safeguards are active
osmosisd query governance-safeguards config

# Test spot trading functionality
osmosisd tx gamm swap-exact-amount-in <params>
```

### 2. Test Core DEX Functions

- Liquidity provision
- Token swapping
- Reward claiming
- Pool creation
- Governance participation

### 3. Verify Restrictions

Ensure that:
- Leveraged trading is blocked
- Margin positions cannot be created
- Perpetual contracts are disabled
- Governance proposals for leverage modules are rejected

## Maintenance

### 1. Updates and Upgrades

- Monitor for security updates
- Test upgrades on testnet first
- Follow proper upgrade procedures
- Maintain backup procedures

### 2. Backup Procedures

```bash
# Backup validator key
cp ~/.osmosisd/config/priv_validator_key.json ~/backup/

# Backup node key
cp ~/.osmosisd/config/node_key.json ~/backup/

# Backup configuration
cp -r ~/.osmosisd/config ~/backup/
```

### 3. Log Management

```bash
# Rotate logs
sudo logrotate /etc/logrotate.d/osmosis-spot

# Monitor log size
du -sh ~/.osmosisd/data/
```

## Troubleshooting

### Common Issues

1. **Node not syncing**: Check peers and network connectivity
2. **High memory usage**: Adjust pruning settings
3. **Disk space issues**: Implement log rotation and pruning
4. **Port conflicts**: Ensure ports are not in use by other services

### Support

For support and issues:
- Check the GitHub repository issues
- Join the community Discord/Telegram
- Review the documentation
- Contact the development team

## Conclusion

This deployment guide provides comprehensive instructions for setting up the Osmosis Spot-Only Fork. The fork maintains all core DEX functionality while removing leveraged trading features and implementing governance safeguards to ensure the platform remains focused on spot trading.

Remember to:
- Test thoroughly before mainnet deployment
- Implement proper security measures
- Monitor the node continuously
- Keep backups of critical data
- Stay updated with the latest releases