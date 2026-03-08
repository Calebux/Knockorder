#!/usr/bin/env bash
#
# Full EGS deployment: Dojo world + KnockOrderEGS adapter + config + auth.
# Run from repo root. Requires: sozo, scarb, sncast; .env.sepolia in knock_order/.
#
# Steps:
#   1. scarb build && sozo migrate (deploy Dojo world + systems, including EgsConfig)
#   2. Deploy KnockOrderEGS as a separate Starknet contract (sncast)
#   3. Call EgsConfig.set_adapter(adapter_address) via sozo
#   4. Call adapter.set_authorized_caller(EndMatch_address) via sncast
#
# After running: set NEXT_PUBLIC_EGS_ADAPTER_ADDRESS in Vercel and register with EGS Registry.
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
KNOCK_ORDER="${ROOT_DIR}/knock_order"
ENV_FILE="${KNOCK_ORDER}/.env.sepolia"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing ${ENV_FILE}. Create it with STARKNET_RPC_URL, DOJO_ACCOUNT_ADDRESS, DOJO_PRIVATE_KEY."
  exit 1
fi

export $(grep -v '^#' "$ENV_FILE" | xargs)

# Ensure required env vars
: "${STARKNET_RPC_URL:?Set STARKNET_RPC_URL in .env.sepolia}"
: "${DOJO_ACCOUNT_ADDRESS:?Set DOJO_ACCOUNT_ADDRESS in .env.sepolia}"
: "${DOJO_PRIVATE_KEY:?Set DOJO_PRIVATE_KEY in .env.sepolia}"

cd "$KNOCK_ORDER"

echo "=== 1. Build and migrate Dojo world (scarb build && sozo migrate) ==="
scarb build
sozo -P sepolia build
sozo -P sepolia migrate

# Copy manifest so frontend and scripts use the same world
if [ -f "${KNOCK_ORDER}/manifest_sepolia.json" ]; then
  cp "${KNOCK_ORDER}/manifest_sepolia.json" "${ROOT_DIR}/app/lib/dojo/manifest.json"
  echo "Copied manifest to app/lib/dojo/manifest.json"
fi

# Resolve EndMatch contract address from manifest for step 4
MANIFEST="${KNOCK_ORDER}/manifest_sepolia.json"
END_MATCH_ADDRESS=$(jq -r '.contracts[] | select(.tag == "dojo_starter-EndMatch") | .address' "$MANIFEST")
if [ -z "$END_MATCH_ADDRESS" ] || [ "$END_MATCH_ADDRESS" = "null" ]; then
  echo "Could not find dojo_starter-EndMatch in manifest. Aborting."
  exit 1
fi
echo "EndMatch contract address: $END_MATCH_ADDRESS"

echo ""
echo "=== 2. Deploy KnockOrderEGS adapter (Starknet contract) ==="

# Build with sepolia profile so artifact is in target/sepolia
sozo -P sepolia build
SIERRA_JSON="${KNOCK_ORDER}/target/sepolia/dojo_starter_KnockOrderEGS.contract_class.json"
if [ ! -f "$SIERRA_JSON" ]; then
  echo "Artifact not found: $SIERRA_JSON"
  exit 1
fi

# Use EGS_CLASS_HASH from env if already declared; otherwise declare
CLASS_HASH="${EGS_CLASS_HASH:-}"
if [ -z "$CLASS_HASH" ]; then
  if command -v starkli &>/dev/null; then
    echo "Using starkli to declare class..."
    DECLARE_JSON=$(starkli declare "$SIERRA_JSON" \
      --rpc "$STARKNET_RPC_URL" \
      --account "$DOJO_ACCOUNT_ADDRESS" \
      --private-key "$DOJO_PRIVATE_KEY" \
      --output-format json 2>/dev/null) || true
    CLASS_HASH=$(echo "$DECLARE_JSON" | jq -r '.class_hash // empty')
  else
    echo "Declaring with sncast (ensure account is configured: sncast account add / use default)..."
    DECLARE_OUT=$(cd "$KNOCK_ORDER" && sncast declare \
      --contract-name dojo_starter_KnockOrderEGS \
      --package dojo_starter \
      --network sepolia \
      -u "$STARKNET_RPC_URL" \
      --wait 2>&1) || true
    CLASS_HASH=$(echo "$DECLARE_OUT" | grep -oE '0x[a-fA-F0-9]{64}' | head -1)
    [ -z "$CLASS_HASH" ] && CLASS_HASH=$(echo "$DECLARE_OUT" | jq -r '.class_hash // empty' 2>/dev/null)
  fi
fi

if [ -z "$CLASS_HASH" ]; then
  echo "Failed to get class hash. Either:"
  echo "  - Install starkli and re-run (recommended): curl -L https://raw.githubusercontent.com/xJonathanLEI/starkli/main/install.sh | sh"
  echo "  - Or declare manually, then set EGS_CLASS_HASH=<class_hash> in .env.sepolia and re-run this script."
  exit 1
fi
echo "KnockOrderEGS class hash: $CLASS_HASH"

# Deploy: constructor(owner: ContractAddress) -> owner is deployer
# sncast needs account; use same env as sozo (DOJO_ACCOUNT_*) — ensure sncast account is configured for this address
DEPLOY_OUT=$(sncast deploy \
  --class-hash "$CLASS_HASH" \
  --constructor-calldata "$DOJO_ACCOUNT_ADDRESS" \
  --network sepolia \
  -u "$STARKNET_RPC_URL" \
  --wait 2>&1)
ADAPTER_ADDRESS=$(echo "$DEPLOY_OUT" | grep -oE '0x[a-fA-F0-9]{64}' | tail -1)
if [ -z "$ADAPTER_ADDRESS" ]; then
  ADAPTER_ADDRESS=$(echo "$DEPLOY_OUT" | jq -r '.contract_address // empty' 2>/dev/null)
fi
if [ -z "$ADAPTER_ADDRESS" ]; then
  echo "Deploy output: $DEPLOY_OUT"
  echo "Could not parse adapter address. Ensure sncast account is configured (same as DOJO_ACCOUNT_ADDRESS)."
  exit 1
fi
echo "KnockOrderEGS adapter deployed at: $ADAPTER_ADDRESS"

echo ""
echo "=== 3. EgsConfig.set_adapter(adapter_address) via sozo ==="
sozo execute dojo_starter-EgsConfig set_adapter "$ADAPTER_ADDRESS" -P sepolia --wait

echo ""
echo "=== 4. adapter.set_authorized_caller(EndMatch_address) via sncast ==="
sncast invoke \
  --contract-address "$ADAPTER_ADDRESS" \
  --function set_authorized_caller \
  --calldata "$END_MATCH_ADDRESS" \
  --network sepolia \
  -u "$STARKNET_RPC_URL" \
  --wait

echo ""
echo "=== EGS deployment complete ==="
echo "Adapter address: $ADAPTER_ADDRESS"
echo ""
echo "Next steps:"
echo "  5. Set in Vercel (or .env.local): NEXT_PUBLIC_EGS_ADAPTER_ADDRESS=$ADAPTER_ADDRESS"
echo "  6. Register with Provable Games EGS Registry to appear on EGS platforms."
echo "     See docs/EGS_DEPLOY.md for registry and verification details."
