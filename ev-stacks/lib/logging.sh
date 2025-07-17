#!/bin/sh
# Shared logging utility for ev-stacks
# This file provides a common logging function that can be sourced by multiple scripts

# Logging function for clear, verbose output
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        "INFO")
            echo "ℹ️  [$timestamp] INFO: $message"
            ;;
        "SUCCESS")
            echo "✅ [$timestamp] SUCCESS: $message"
            ;;
        "WARNING"|"WARN")
            echo "⚠️  [$timestamp] WARNING: $message"
            ;;
        "ERROR")
            echo "❌ [$timestamp] ERROR: $message"
            ;;
        "DEBUG")
            echo "🔍 [$timestamp] DEBUG: $message"
            ;;
        "INIT")
            echo "🚀 [$timestamp] INIT: $message"
            ;;
        "NETWORK")
            echo "🌐 [$timestamp] NETWORK: $message"
            ;;
        "DOWNLOAD")
            echo "⬇️  [$timestamp] DOWNLOAD: $message"
            ;;
        "CONFIG")
            echo "⚙️  [$timestamp] CONFIG: $message"
            ;;
        "DEPLOY")
            echo "🚢 [$timestamp] DEPLOY: $message"
            ;;
        "AUTH")
            echo "🔐 [$timestamp] AUTH: $message"
            ;;
        *)
            echo "📝 [$timestamp] $level: $message"
            ;;
    esac
}
