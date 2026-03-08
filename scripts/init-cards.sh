#!/usr/bin/env bash
# One-time: seed the Dojo world with default move cards (init_default_cards).
# Run after first deploy. Uses .env.sepolia in knock_order/ for Sepolia.
# Usage: ./scripts/init-cards.sh   (from repo root or knock_order)

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
KNOCK_ORDER="${ROOT_DIR}/knock_order"
ENV_FILE="${KNOCK_ORDER}/.env.sepolia"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE. Create it with STARKNET_RPC_URL, DOJO_ACCOUNT_ADDRESS, DOJO_PRIVATE_KEY."
  exit 1
fi

export $(grep -v '^#' "$ENV_FILE" | xargs)
cd "$KNOCK_ORDER"
echo "Initializing default cards on Sepolia..."
sozo execute dojo_starter-InitCards init_default_cards -P sepolia --wait
echo "Done. Default move cards are seeded."
