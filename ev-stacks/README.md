# EV-Stacks: Easy Rollkit deployments

A collection of Docker-based deployment stacks for Rollkit chains.

## Overview

EV-Stacks provides pre-configured deployment stacks for running EVM-compatible blockchain infrastructure with different configurations:

- **Single Sequencer**: A single-node sequencer setup for development and testing
- **Full Node**: Additional network connectivity and redundancy
- **Data Availability**: Modular DA layer integration (currently supports Celestia)

## Prerequisites

Before deploying EV-Stacks, ensure your system meets the following requirements:

### Required Software
- **Docker and Docker Compose**: Version 20.10 or later
  ```bash
  # Install Docker (Ubuntu/Debian)
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh

  # Add user to docker group
  sudo usermod -aG docker $USER
  newgrp docker
  ```

### System Requirements
- **Operating System**: Linux (Ubuntu 20.04+ recommended), macOS, or Windows with WSL2
- **Memory**: 24GB RAM
- **Storage**: At least 500GB free disk space
- **Network**: Stable internet connection with 1Gbps

### Celestia DA Requirements
If deploying with Celestia as the Data Availability layer, additional configuration is required:

- **BBR Congestion Control**: Must be enabled on the server for optimal Celestia network performance
  ```bash
  # Check if BBR is available
  sysctl net.ipv4.tcp_available_congestion_control

  # Enable BBR (requires root privileges)
  echo 'net.core.default_qdisc=fq' | sudo tee -a /etc/sysctl.conf
  echo 'net.ipv4.tcp_congestion_control=bbr' | sudo tee -a /etc/sysctl.conf
  sudo sysctl -p

  # Verify BBR is active
  sysctl net.ipv4.tcp_congestion_control
  ```

- **TIA Tokens**: You'll need testnet mocha-4 TIA tokens to fund your Celestia light node
  - Get testnet tokens from the [Celestia Discord faucet](https://discord.gg/celestiacommunity)
  - The deployment will show you the address to fund after setup

## Quick Start

Deploy a complete EVM stack with one command:

```bash
# One-liner deployment (interactive)
bash -c "bash -i <(curl -s https://raw.githubusercontent.com/rollkit/ops-toolbox/main/ev-stack/deploy-rollkit.sh)"

# Or download and run locally
wget https://raw.githubusercontent.com/rollkit/ops-toolbox/main/ev-stack/deploy-rollkit.sh
chmod +x deploy-rollkit.sh
./deploy-rollkit.sh
```

The deployment script will guide you through:

1. Selecting a data availability layer (Celestia)
2. Choosing sequencer topology (single-sequencer)
3. Optional fullnode deployment
4. Automatic configuration and setup

### Deployment Structure

The deployment script organizes files in the following structure:

```
$HOME/rollkit-deployment/
├── lib/
│   └── logging.sh              # Centralized logging functions
└── stacks/
    ├── single-sequencer/       # Single sequencer stack
    ├── fullnode/              # Full node stack (optional)
    └── da-celestia/           # Celestia DA stack
```

## Available Stacks

### 🌌 Data Availability - Celestia (`stacks/da-celestia/`)

Celestia modular data availability layer integration:

- **Celestia App**: Consensus node for the Celestia network
- **Celestia Light Node**: Data availability light client

**Services:**

- Celestia Light Node RPC: `http://localhost:26658`


### 🔗 Single Sequencer (`stacks/single-sequencer/`)

A complete single-node EVM sequencer stack including:

- **Reth Sequencer**: EVM execution layer using Lumen (Reth fork)
- **Rollkit Sequencer**: Consensus and block production

**Services:**

- Reth Prometheus Metrics: `http://localhost:9000`
- Rollkit Prometheus Metrics: `http://localhost:26660`

### 🌐 Full Node (`stacks/fullnode/`)

Additional full node deployment for enhanced network connectivity:

- Provides redundancy and additional RPC endpoints
- Can be deployed alongside sequencer for production setups

**Services:**

- Reth RPC: `http://localhost:8545`
- Reth Prometheus Metrics: `http://localhost:9002`
- Rollkit RPC: `http://localhost:7331`
- Rollkit Prometheus Metrics: `http://localhost:26662`

## Configuration

The script automatically configures:

#### Chain ID
- **What it is**: A unique identifier for your blockchain
- **Example**: `1234` for development, or your custom ID
- **Why needed**: Prevents transaction replay attacks between different chains

#### EVM Signer Passphrase
- **What it is**: A password that protects the sequencer's signing key
- **Generation**: Automatically generated using `openssl rand -base64 32`
- **Purpose**: Secures the private key used to sign blocks

#### DA Namespace
- **What it is**: A unique identifier for your data on Celestia
- **Format**: 28-byte hex string (e.g., `000000000000000000000000000000000000002737d4d967c7ca526dd5`)
- **Purpose**: Separates your blockchain's data from other chains using Celestia

#### JWT Tokens
- **What they are**: Secure tokens for communication between Reth and Rollkit
- **Generation**: Automatically created using `openssl rand -hex 32`
- **Purpose**: Authenticates internal API calls between components

## What Gets Created

### 1. Docker Networks
- **evstack_shared**: A bridge network connecting all components
- **Purpose**: Allows containers to communicate using service names

### 2. Docker Volumes
- **Persistent storage** for blockchain data, configuration, and keys
- **Shared volumes** for passing authentication tokens between services
- **Examples**:
  - `reth-sequencer-data`: Blockchain state and transaction data
  - `sequencer-data`: Rollkit configuration and keys
  - `celestia-node-data`: Celestia light node data
  - `celestia-node-export`: Shared authentication tokens

### 3. Docker Services

#### Single Sequencer Stack
1. **jwt-init-sequencer**: Creates JWT tokens for secure communication
2. **reth-sequencer**: EVM execution layer (Lumen/Reth)
3. **single-sequencer**: Rollkit consensus layer

#### Celestia DA Stack
1. **da-permission-fix**: Fixes file permissions for shared volumes
2. **celestia-app**: Celestia consensus node (connects to mocha-4 network)
3. **celestia-node**: Celestia light node (provides DA services)

#### Full Node Stack (Optional)
1. **jwt-init-fullnode**: Creates JWT tokens for full node
2. **reth-fullnode**: EVM execution layer for full node
3. **fullnode**: Rollkit full node (follows the sequencer)

### 4. Configuration Files

#### Environment Variables (`.env` files)
Each stack has its own `.env` file with specific configuration:

**Single Sequencer**:
```bash
CHAIN_ID="1234"                           # Your blockchain's unique ID
EVM_SIGNER_PASSPHRASE="secure_password"   # Sequencer signing key protection
DA_NAMESPACE="your_namespace_hex"         # Celestia namespace
DA_START_HEIGHT="6853148"                 # Starting block on Celestia
DA_RPC_PORT="26658"                       # Celestia RPC port
SEQUENCER_RETH_PROMETHEUS_PORT="9000"     # Metrics port for Reth
SEQUENCER_ROLLKIT_PROMETHEUS_PORT="26660" # Metrics port for Rollkit
```

**Celestia DA**:
```bash
DA_NAMESPACE="your_namespace_hex"         # Must match sequencer namespace
CELESTIA_NETWORK="mocha-4"                # Celestia testnet
CELESTIA_NODE_TAG="latest"                # Docker image version
DA_CORE_IP="consensus.mocha-4.celestia-mocha.com"  # Celestia consensus endpoint
DA_CORE_PORT="26657"                      # Celestia consensus port
DA_RPC_PORT="26658"                       # Light node RPC port
```

#### Docker Compose Files
Define how services are connected, what ports they expose, and how they depend on each other.

#### Entrypoint Scripts
Smart startup scripts that:
- Initialize services if needed
- Configure connections between components
- Handle authentication token sharing
- Provide detailed logging

## Network Endpoints and RPCs

After deployment, you'll have access to these endpoints:

### Sequencer Stack
- **Reth JSON-RPC**: `http://localhost:8545`
  - Standard Ethereum JSON-RPC interface
  - Use for sending transactions, querying state
- **Reth Metrics**: `http://localhost:9000`
  - Prometheus metrics for monitoring
- **Rollkit Metrics**: `http://localhost:26660`
  - Consensus layer metrics

### Full Node Stack (if deployed)
- **Full Node RPC**: `http://localhost:8545` (different port mapping)
- **Full Node Metrics**: `http://localhost:9002`
- **Rollkit Full Node RPC**: `http://localhost:7331`
- **Rollkit Full Node Metrics**: `http://localhost:26662`

### Celestia DA
- **Light Node RPC**: `http://localhost:26658`
  - Data availability queries
  - Blob submission and retrieval

## Customizing the Deployment

### 1. Modifying Configuration

You can edit the `.env` files to change:
- **Chain ID**: Change `CHAIN_ID` to your desired value
- **Block time**: Modify `EVM_BLOCK_TIME` (default: 500ms)
- **DA settings**: Update `DA_START_HEIGHT` or `DA_NAMESPACE`
- **Ports**: Change port mappings to avoid conflicts

### 2. Adding Custom Genesis

Replace `genesis.json` in the sequencer directory with your custom genesis block.

### 3. Scaling the Deployment

#### Adding More Full Nodes
1. Copy the `fullnode` directory
2. Modify port mappings in the new `docker-compose.yml`
3. Update the `.env` file with different ports
4. Start the new full node stack

## Service Management

### Health Monitoring

```bash
# Check all services
docker compose ps

# View logs
docker compose logs -f [service-name]

# Test RPC endpoints
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545
```

### Maintenance Commands

```bash
# Stop services
docker compose down

# Update images
docker compose pull
docker compose up -d

# Clean restart
docker compose down
docker system prune -f
docker compose up -d
```

### Backup and Recovery

```bash
# Backup Single Sequencer volumes
docker run --rm -v reth-sequencer-data:/data -v $(pwd):/backup alpine tar czf /backup/reth-sequencer-data-backup.tar.gz -C /data .
docker run --rm -v sequencer-data:/data -v $(pwd):/backup alpine tar czf /backup/sequencer-data-backup.tar.gz -C /data .

# Backup Full Node volumes (if deployed)
docker run --rm -v reth-fullnode-data:/data -v $(pwd):/backup alpine tar czf /backup/reth-fullnode-data-backup.tar.gz -C /data .
docker run --rm -v fullnode-data:/data -v $(pwd):/backup alpine tar czf /backup/fullnode-data-backup.tar.gz -C /data .

# Backup Celestia DA volumes (if deployed)
docker run --rm -v celestia-appd-data:/data -v $(pwd):/backup alpine tar czf /backup/celestia-appd-data-backup.tar.gz -C /data .
docker run --rm -v celestia-node-data:/data -v $(pwd):/backup alpine tar czf /backup/celestia-node-data-backup.tar.gz -C /data .

# Restore volumes (example for sequencer data)
docker run --rm -v sequencer-data:/data -v $(pwd):/backup alpine tar xzf /backup/sequencer-data-backup.tar.gz -C /data
```

## License

This project is released into the public domain under the Unlicense - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/rollkit/ops-toolbox/issues)
- **Documentation**: See the guides above for detailed information
- **Community**: Join the Rollkit community for support
