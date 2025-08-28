#!/bin/sh
# Fail on any error
set -e

# Fail when using undeclared variables
set -u

# Source shared logging utility
. /usr/local/lib/logging.sh

# Build start flags array
log "INFO" "Building startup configuration flags"
default_flags=""

# Get sequencer node id
log "NETWORK" "Fetching sequencer P2P information from ev-reth-sequencer:30303"
RESPONSE=$(curl -sX POST \
	-H 'Content-Type: application/json' \
	-d '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' \
	http://ev-reth-sequencer:8545 | \
    jq -r '.result.enode')

if [ $? -eq 0 ] && [ -n "${RESPONSE}" ]; then
	log "SUCCESS" "Received response from ev-rethsequencer"
	SEQUENCER_P2P_INFO=$(echo "${RESPONSE}" | sed 's|@127\.0\.0\.1|@ev-reth-sequencer|')

	# Validate the format of SEQUENCER_P2P_INFO
    if ! echo "${SEQUENCER_P2P_INFO}" | \
        grep -E '^enode://[a-fA-F0-9]{128}@[^:]+:[0-9]{1,5}$' >/dev/null; then
        log "ERROR" "SEQUENCER_P2P_INFO is not in the expected enode format. Got: ${SEQUENCER_P2P_INFO}"
        exit 1
    else
        log "SUCCESS" "SEQUENCER_P2P_INFO is valid: ${SEQUENCER_P2P_INFO}"
    fi
else
	log "ERROR" "Failed to fetch sequencer P2P information"
	exit 1
fi

if [ -n "${SEQUENCER_P2P_INFO:-}" ]; then
	default_flags="${default_flags} --trusted-peers ${SEQUENCER_P2P_INFO}"
	log "DEBUG" "Added genesis hash flag"
fi

# If no arguments passed, show help
if [ $# -eq 0 ]; then
	log "INFO" "No arguments provided, showing help"
	exec ev-reth
fi

# If first argument is "node", apply default flags
if [ "$1" = "node" ]; then
	shift
	log "INIT" "Starting Ev-reth with command: ev-reth node $default_flags $*"
	log "INFO" "Ev-reth is now starting up..."
	eval "exec ev-reth node $default_flags \"\$@\""
else
	# For any other command/subcommand, pass through directly
	log "INFO" "Executing command: ev-reth $*"
	exec ev-reth "$@"
fi
