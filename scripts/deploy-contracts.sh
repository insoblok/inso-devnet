#!/usr/bin/env bash
# deploy-contracts.sh — Deploy all InSoBlok contracts and verify deployment
# Usage: ./deploy-contracts.sh [rpc_url] [private_key]

set -e

RPC_URL="${1:-http://localhost:8545}"
PRIVATE_KEY="${2:-0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80}"

echo "═══════════════════════════════════════════════════════════"
echo "  InSoBlok Contract Deployment"
echo "  RPC: $RPC_URL"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Wait for RPC to be available
echo "Waiting for RPC endpoint..."
for i in $(seq 1 30); do
  if cast block-number --rpc-url "$RPC_URL" >/dev/null 2>&1; then
    echo "  RPC is available (block $(cast block-number --rpc-url "$RPC_URL"))"
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "  ERROR: RPC not available after 30 attempts"
    exit 1
  fi
  sleep 2
done
echo ""

# Deploy
echo "Running Deploy.s.sol..."
cd "$(dirname "$0")/../inso-contracts"

forge script script/Deploy.s.sol \
  --rpc-url "$RPC_URL" \
  --broadcast \
  --private-key "$PRIVATE_KEY" \
  --skip-simulation \
  2>&1 | tee /tmp/deploy-output.log

echo ""
echo "Verifying deployment..."

# Extract deployed addresses from broadcast log
BROADCAST_DIR="broadcast/Deploy.s.sol"
if [ -d "$BROADCAST_DIR" ]; then
  LATEST=$(ls -t "$BROADCAST_DIR"/*/run-latest.json 2>/dev/null | head -1)
  if [ -n "$LATEST" ]; then
    echo "  Broadcast log: $LATEST"
    # Count deployed contracts
    COUNT=$(jq '.transactions | length' "$LATEST" 2>/dev/null || echo "0")
    echo "  Transactions: $COUNT"
    
    # List deployed contract addresses
    echo ""
    echo "  Deployed Contracts:"
    jq -r '.transactions[] | select(.transactionType == "CREATE") | "    \(.contractName): \(.contractAddress)"' "$LATEST" 2>/dev/null || true
  fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Deployment complete!"
echo "═══════════════════════════════════════════════════════════"
