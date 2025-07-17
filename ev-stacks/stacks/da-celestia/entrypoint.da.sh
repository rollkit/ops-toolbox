#!/bin/bash
# Fail on any error
set -e

# Fail on any error in a pipeline
set -o pipefail

# Fail when using undeclared variables
set -u

# Source shared logging utility
. /usr/local/lib/logging.sh

LIGHT_NODE_CONFIG_PATH=/home/celestia/config.toml
TOKEN_PATH=${VOLUME_EXPORT_PATH}/auth_token

# Configure trusted height and hash with defaults
DA_TRUSTED_HEIGHT=${DA_TRUSTED_HEIGHT:-6850000}
DA_TRUSTED_HASH=${DA_TRUSTED_HASH:-E6D437C5F411B3E6388BA2A3D84F958EC2B05CBE815F33B412A4DF9157EFCE37}

log "INIT" "Starting Celestia Light Node initialization"
log "INFO" "Light node config path: $LIGHT_NODE_CONFIG_PATH"
log "INFO" "Token export path: $TOKEN_PATH"
log "INFO" "DA Core IP: ${DA_CORE_IP}"
log "INFO" "DA Core Port: ${DA_CORE_PORT}"
log "INFO" "DA Network: ${DA_NETWORK}"
log "INFO" "DA RPC Port: ${DA_RPC_PORT}"
log "INFO" "Default trusted height: $DA_TRUSTED_HEIGHT"
log "INFO" "Default trusted hash: $DA_TRUSTED_HASH"

# Initializing the light node
if [ ! -f "$LIGHT_NODE_CONFIG_PATH" ]; then
    log "INFO" "Config file does not exist. Initializing the light node"

    log "INIT" "Initializing celestia light node with network: ${DA_NETWORK}"
    if ! celestia light init \
        "--core.ip=${DA_CORE_IP}" \
        "--core.port=${DA_CORE_PORT}" \
        "--p2p.network=${DA_NETWORK}"; then
        log "ERROR" "Failed to initialize celestia light node"
        exit 1
    fi
    log "SUCCESS" "Celestia light node initialization completed"
else
    log "INFO" "Config file already exists at $LIGHT_NODE_CONFIG_PATH"
    log "INFO" "Skipping initialization - light node already configured"
fi

# Get latest block and update trusted hash
log "CONFIG" "Setting up trusted hash from latest block"
consensus_url="https://full.consensus.mocha-4.celestia-mocha.com/block"
log "DOWNLOAD" "Fetching latest block information from: $consensus_url"

if ! block_response=$(curl -s "$consensus_url" --max-time 30); then
    log "ERROR" "Failed to fetch latest block information from consensus endpoint"
    log "WARNING" "Falling back to default trusted values"
    latest_block=$DA_TRUSTED_HEIGHT
    latest_hash=$DA_TRUSTED_HASH
else
    log "SUCCESS" "Latest block information fetched successfully"

    log "INFO" "Parsing block response for height and hash"
    if ! latest_block=$(echo "$block_response" | jq -r '.result.block.header.height' 2>/dev/null); then
        log "ERROR" "Failed to parse block height from response"
        latest_block=$DA_TRUSTED_HEIGHT
    fi

    if ! latest_hash=$(echo "$block_response" | jq -r '.result.block_id.hash' 2>/dev/null); then
        log "ERROR" "Failed to parse block hash from response"
        latest_hash=$DA_TRUSTED_HASH
    fi

    log "SUCCESS" "Parsed latest block - Height: $latest_block, Hash: $latest_hash"
fi

# Update config with trusted hash
if [ -f "$LIGHT_NODE_CONFIG_PATH" ]; then
    log "CONFIG" "Updating configuration with latest trusted state"

    # Escape special characters for sed
    latest_hash_escaped=$(printf '%s\n' "$latest_hash" | sed 's/[[\.*^$()+?{|]/\\&/g')
    latest_block_escaped=$(printf '%s\n' "$latest_block" | sed 's/[[\.*^$()+?{|]/\\&/g')

    if ! sed -i.bak \
        -e "s/\(TrustedHash[[:space:]]*=[[:space:]]*\).*/\1\"$latest_hash_escaped\"/" \
        -e "s/\(SampleFrom[[:space:]]*=[[:space:]]*\).*/\1$latest_block_escaped/" \
        "$LIGHT_NODE_CONFIG_PATH"; then
        log "ERROR" "Failed to update config with latest trusted state"
        exit 1
    fi
    log "SUCCESS" "Config updated with latest trusted state"
else
    log "WARNING" "Config file not found, cannot update trusted state"
fi

# Update DASer.SampleFrom
log "CONFIG" "Updating DASer.SampleFrom to: ${DA_TRUSTED_HEIGHT}"
if ! sed -i 's/^[[:space:]]*SampleFrom = .*/  SampleFrom = '${DA_TRUSTED_HEIGHT}'/' "$LIGHT_NODE_CONFIG_PATH"; then
    log "ERROR" "Failed to update DASer.SampleFrom"
    exit 1
fi
log "SUCCESS" "DASer.SampleFrom updated successfully"

# Update Header.TrustedHash
log "CONFIG" "Updating Header.TrustedHash to: ${DA_TRUSTED_HASH}"
# Escape special characters for sed
DA_TRUSTED_HASH_ESCAPED=$(printf '%s\n' "$DA_TRUSTED_HASH" | sed 's/[[\.*^$()+?{|]/\\&/g')
if ! sed -i 's/^[[:space:]]*TrustedHash = .*/  TrustedHash = "'"$DA_TRUSTED_HASH_ESCAPED"'"/' "$LIGHT_NODE_CONFIG_PATH"; then
    log "ERROR" "Failed to update Header.TrustedHash"
    exit 1
fi
log "SUCCESS" "Header.TrustedHash updated successfully"

log "SUCCESS" "Configuration completed - Trusted height: ${DA_TRUSTED_HEIGHT}, Trusted hash: ${DA_TRUSTED_HASH}"

# Export AUTH_TOKEN to shared volume
log "AUTH" "Generating and exporting auth token to: $TOKEN_PATH"

if ! TOKEN=$(celestia light auth write "--p2p.network=${DA_NETWORK}"); then
    log "ERROR" "Failed to generate auth token"
    exit 1
fi
log "SUCCESS" "Auth token generated successfully"

log "INFO" "Writing auth token to shared volume"
if ! echo "${TOKEN}" > ${TOKEN_PATH}; then
    log "ERROR" "Failed to write auth token to $TOKEN_PATH"
    exit 1
fi
log "SUCCESS" "Auth token exported to $TOKEN_PATH"

log "INIT" "Starting Celestia light node"
log "INFO" "Light node will be accessible on RPC port: ${DA_RPC_PORT}"
log "INFO" "Starting with skip-auth enabled for RPC access"

celestia light start \
    "--core.ip=${DA_CORE_IP}" \
    "--core.port=${DA_CORE_PORT}" \
    "--p2p.network=${DA_NETWORK}" \
    --rpc.addr=0.0.0.0 \
    "--rpc.port=${DA_RPC_PORT}" \
    --rpc.skip-auth
