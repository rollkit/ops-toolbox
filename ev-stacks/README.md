# EV-Stacks: Easy Evolve deployments

A collection of Docker-based deployment stacks for Evolve chains.

## Overview

EV-Stacks provides pre-configured deployment stacks for running Evolve chains with different configurations:

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
  - Get testnet tokens from the [Celestia Discord faucet](https://discord.gg/celestiacommunity) or the [Celenium web faucet](https://mocha.celenium.io/faucet)
  - The deployment will show you the address to fund after setup

### Ethereum Addresses

Ethereum addresses that will receive initial token balances in the genesis block. You must possess the private keys for these addresses to make transactions on your chain

**Creating Ethereum Wallets with Foundry:**

If you don't have an Ethereum address, you can create one using Foundry's `cast` tool:

```bash
# Install Foundry (if you haven't already)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Create a new wallet
cast wallet new

# Example output:
# Successfully created new keypair.
# Address:     0x742d35Cc6634C0532925a3b8D4C9db96590c6C87
# Private key: 0x1234567890abcdef...
```

## Quick Start

Deploy a complete EVM stack with one command:

```bash
# One-liner deployment (interactive)
bash -c "bash -i <(curl -s https://raw.githubusercontent.com/evstack/ev-toolbox/refs/heads/main/ev-stacks/deploy-evolve.sh)"

# Or download and run locally
wget https://raw.githubusercontent.com/evstack/ev-toolbox/refs/heads/main/ev-stacks/deploy-evolve.sh
chmod +x deploy-evolve.sh
./deploy-evolve.sh
```

The deployment script will guide you through:

1. Selecting a data availability layer (Celestia)
2. Choosing sequencer topology (single-sequencer)
3. Optional fullnode deployment
4. Automatic configuration and setup

### Starting the Services

**IMPORTANT**: Services must be started in the correct order to ensure proper initialization and connectivity.

#### 1. Start the Data Availability Layer First

```bash
cd $HOME/evolve-deployment/stacks/da-celestia
docker compose up -d
```

Wait for the Celestia services to be fully initialized before proceeding. You can monitor the logs:

```bash
docker compose logs -f
```

**Fund your Celestia account**: After the DA layer is running, you need to fund the default account with testnet TIA tokens:

```bash
# Get the account address to fund
docker exec -it celestia-node cel-key list --node.type=light

# Fund this address using the Celestia Discord faucet (https://discord.gg/celestiacommunity) or the Celenium web faucet (https://mocha.celenium.io/faucet)
```

#### 2. Start the Single Sequencer

```bash
cd $HOME/evolve-deployment/stacks/single-sequencer
docker compose up -d
```

Monitor the sequencer startup:

```bash
docker compose logs -f
```

#### 3. Start the Fullnode (if deployed)

```bash
cd $HOME/evolve-deployment/stacks/fullnode
docker compose up -d
```

Monitor the fullnode startup:

```bash
docker compose logs -f
```

### Deployment Structure

The deployment script organizes files in the following structure:

```
$HOME/evolve-deployment/
├── lib/
│   └── logging.sh              # Centralized logging functions
└── stacks/
    ├── single-sequencer/       # Single sequencer stack
    ├── fullnode/              # Full node stack (optional)
    └── da-celestia/           # Celestia DA stack
```

### Verifying the Deployment

After all services are running, verify the deployment:

```bash
# Check all services are running
cd $HOME/evolve-deployment/stacks/da-celestia && docker compose ps
cd $HOME/evolve-deployment/stacks/single-sequencer && docker compose ps
cd $HOME/evolve-deployment/stacks/fullnode && docker compose ps  # if deployed

# Test the RPC endpoints
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545

# Test fullnode RPC (if deployed)
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545  # or the configured fullnode RPC port
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

- **Ev-reth**: EVM execution layer (Reth fork)
- **Ev-node**: Consensus and block production

**Services:**

- Ev-reth Prometheus Metrics: `http://localhost:9000`
- Ev-node Prometheus Metrics: `http://localhost:26660/metrics`

### 🌐 Full Node (`stacks/fullnode/`)

Additional full node deployment for enhanced network connectivity:

- Provides redundancy and additional RPC endpoints
- Can be deployed alongside sequencer for production setups

**Services:**

- Ev-reth RPC: `http://localhost:8545`
- Ev-reth Prometheus Metrics: `http://localhost:9002`
- Ev-node RPC: `http://localhost:7331`
- Ev-node Prometheus Metrics: `http://localhost:26662/metrics`

## Configuration

The script automatically configures:

#### Chain ID

- **What it is**: A unique identifier for your chain
- **Example**: `1234` for development, or your custom ID
- **Why needed**: Prevents transaction replay attacks between different chains

#### EVM Signer Passphrase

- **What it is**: A password that protects the sequencer's signing key
- **Generation**: Automatically generated using `openssl rand -base64 32`
- **Purpose**: Secures the private key used to sign blocks

#### DA Namespace

- **What it is**: A unique identifier for your data on Celestia
- **Format**: 58-character hex string representing a 29-byte identifier (e.g., `000000000000000000000000000000000000002737d4d967c7ca526dd5`)
- **Purpose**: Separates your chain's data from other chains using Celestia

#### JWT Tokens

- **What they are**: Secure tokens for communication between Ev-Reth and Ev-node
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
  - `sequencer-data`: Ev-node configuration and keys
  - `celestia-node-data`: Celestia light node data
  - `celestia-node-export`: Shared authentication tokens

### 3. Docker Services

#### Single Sequencer Stack

1. **jwt-init-sequencer**: Creates JWT tokens for secure communication
2. **reth-sequencer**: EVM execution layer (Ev-reth)
3. **single-sequencer**: Ev-node consensus layer
   - **Entrypoint automation**:
     - Initializes sequencer configuration with signer passphrase if not present
     - Exports genesis.json to shared volume for fullnode access
     - Auto-retrieves genesis hash from reth-sequencer via JSON-RPC
     - Imports JWT tokens and DA auth tokens from shared volumes

#### Celestia DA Stack

1. **da-permission-fix**: Fixes file permissions for shared volumes
2. **celestia-app**: Celestia consensus node (connects to mocha-4 network)
   - **Entrypoint automation**:
     - Initializes celestia-appd with proper moniker and chain-id
     - Downloads genesis file for the specified network (mocha-4)
     - Fetches and configures network seeds
     - Downloads and extracts latest network snapshot for quick sync
     - Configures gRPC server to be accessible externally (0.0.0.0:9090)
3. **celestia-node**: Celestia light node (provides DA services)
   - **Entrypoint automation**:
     - Initializes light node with core IP and network configuration
     - Configures node to synchronize from a specific block instead of genesis block (default values can be overriden by environment variables `DA_TRUSTED_HEIGHT` and `DA_TRUSTED_HASH`)
     - Generates and exports auth token to shared volume

#### Full Node Stack (Optional)

1. **jwt-init-fullnode**: Creates JWT tokens for full node
2. **reth-fullnode**: EVM execution layer for full node
3. **fullnode**: Ev-node full node (follows the sequencer)
   - **Entrypoint automation**:
     - Initializes fullnode configuration if not present
     - Imports genesis.json from sequencer's shared volume
     - Fetches sequencer P2P information
     - Auto-retrieves genesis hash from reth-sequencer
     - Imports JWT tokens and DA auth tokens from shared volumes

### 4. Configuration Files

#### Environment Variables (`.env` files)

Each stack has its own `.env` file with specific configuration:

**Single Sequencer**:

```bash
CHAIN_ID="1234"                                  # Your chain's unique ID
EVM_SIGNER_PASSPHRASE="secure_password"          # Sequencer signing key protection
DA_HEADER_NAMESPACE="your_header_namespace_hex"  # Celestia header namespace
DA_DATA_NAMESPACE="your_data_namespace_hex"      # Celestia data namespace
DA_START_HEIGHT="6853148"                        # Starting block on Celestia
DA_RPC_PORT="26658"                              # Celestia RPC port
SEQUENCER_EV_RETH_PROMETHEUS_PORT="9000"         # Metrics port for Ev-reth
SEQUENCER_EV_NODE_PROMETHEUS_PORT="26660"        # Metrics port for Ev-node
```

**Celestia DA**:

```bash
DA_HEADER_NAMESPACE="your_header_namespace_hex"  # Must match sequencer header namespace
DA_DATA_NAMESPACE="your_data_namespace_hex"      # Must match sequencer data namespace
CELESTIA_NETWORK="mocha-4"                       # Celestia testnet
CELESTIA_NODE_TAG="latest"                       # Docker image version
DA_CORE_IP="celestia-app"                        # Celestia consensus endpoint
DA_CORE_PORT="26657"                             # Celestia consensus port
DA_RPC_PORT="26658"                              # Light node RPC port
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

- **Ev-reth JSON-RPC**: `http://localhost:8545`
  - Standard Ethereum JSON-RPC interface
  - Use for sending transactions, querying state
- **Ev-reth Metrics**: `http://localhost:9000`
  - Prometheus metrics for monitoring
- **Ev-node Metrics**: `http://localhost:26660/metrics`
  - Consensus layer metrics

### Full Node Stack (if deployed)

- **Ev-reth RPC**: `http://localhost:8545` (different port mapping)
- **Ev-reth Metrics**: `http://localhost:9002`
- **Ev-node RPC**: `http://localhost:7331`
- **Ev-node Metrics**: `http://localhost:26662/metrics`

### Celestia DA

- **Light Node RPC**: `http://localhost:26658`
  - Data availability queries
  - Blob submission and retrieval

## Customizing the Deployment

### 1. Modifying Configuration

You can edit the `.env` files to change:

- **Chain ID**: Change `CHAIN_ID` to your desired value
- **Block time**: Modify `EVM_BLOCK_TIME` (default: 500ms)
- **DA settings**: Update `DA_START_HEIGHT`, `DA_HEADER_NAMESPACE`, or `DA_DATA_NAMESPACE`
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
docker run --rm -v ev-reth-sequencer-data:/data -v $(pwd):/backup alpine tar czf /backup/ev-reth-sequencer-data-backup.tar.gz -C /data .
docker run --rm -v sequencer-data:/data -v $(pwd):/backup alpine tar czf /backup/sequencer-data-backup.tar.gz -C /data .

# Backup Full Node volumes (if deployed)
docker run --rm -v ev-reth-fullnode-data:/data -v $(pwd):/backup alpine tar czf /backup/ev-reth-fullnode-data-backup.tar.gz -C /data .
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

- **Issues**: [GitHub Issues](https://github.com/evstack/ev-toolbox/issues)
- **Documentation**: See the guides above for detailed information
- **Community**: Join the Evolve community for support
