#!/usr/bin/env bash
# Stop script on error
set -e

# Load environment variables from the appropriate file
ENV_FILE=".env.sepolia"

if [ -f "$ENV_FILE" ]; then
  echo "Loading environment variables from $ENV_FILE..."
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo "Environment file $ENV_FILE not found!"
  exit 1
fi

# Define a cleanup function to clear environment variables
cleanup_env() {
  echo "Cleaning up environment variables..."
  unset STARKNET_RPC_URL
  unset DOJO_ACCOUNT_ADDRESS
  unset DOJO_PRIVATE_KEY
  echo "Environment variables cleared."
}

# Set the trap to execute cleanup on script exit or error
trap cleanup_env EXIT

# Build the project
echo "Building the project..."
sozo -P sepolia build

# Deploy the project
echo "Deploying to Sepolia..."
sozo -P sepolia migrate

# Copy manifest to app so frontend uses the deployed world (Tyc pattern)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_MANIFEST="${SCRIPT_DIR}/../app/lib/dojo/manifest.json"
if [ -f "${SCRIPT_DIR}/manifest_sepolia.json" ]; then
  cp "${SCRIPT_DIR}/manifest_sepolia.json" "$APP_MANIFEST"
  echo "Copied manifest_sepolia.json to app/lib/dojo/manifest.json"
else
  echo "Note: manifest_sepolia.json not found; copy it manually to app/lib/dojo/manifest.json or set NEXT_PUBLIC_DOJO_WORLD_ADDRESS in .env.local"
fi

# Deployment succeeded message
echo "Deployment completed successfully."
