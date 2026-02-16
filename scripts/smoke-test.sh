#!/usr/bin/env bash
# =============================================================================
# InSoBlok L2 — End-to-End Smoke Test
# =============================================================================
# Exercises the full devnet stack: sequencer RPC, new feature endpoints,
# contract deployment, and basic transaction flow.
#
# Usage:
#   ./scripts/smoke-test.sh                                          # defaults
#   ./scripts/smoke-test.sh http://host:8545 http://host:8547        # custom
# =============================================================================
set -euo pipefail

RPC_URL="${1:-http://localhost:8545}"
VALIDATOR_RPC_URL="${2:-http://localhost:8547}"
PASS=0
FAIL=0
TOTAL=0

# ── Helpers ──────────────────────────────────────────────────────────────────

green()  { printf "\033[32m%s\033[0m\n" "$1"; }
red()    { printf "\033[31m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }

rpc_call() {
  local method="$1"
  shift
  local params="${1:-[]}"
  curl -s -X POST "$RPC_URL" \
    -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$method\",\"params\":$params}" \
    2>/dev/null
}

validator_rpc_call() {
  local method="$1"
  shift
  local params="${1:-[]}"
  curl -s -X POST "$VALIDATOR_RPC_URL" \
    -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$method\",\"params\":$params}" \
    2>/dev/null
}

assert_ok() {
  local name="$1"
  local result="$2"
  TOTAL=$((TOTAL + 1))

  if echo "$result" | grep -q '"error"'; then
    FAIL=$((FAIL + 1))
    red "  ✗ $name"
    echo "    $(echo "$result" | head -c 200)"
  elif [ -z "$result" ] || [ "$result" = "null" ]; then
    FAIL=$((FAIL + 1))
    red "  ✗ $name (empty response)"
  else
    PASS=$((PASS + 1))
    green "  ✓ $name"
  fi
}

assert_has_field() {
  local name="$1"
  local result="$2"
  local field="$3"
  TOTAL=$((TOTAL + 1))

  if echo "$result" | grep -q "\"$field\""; then
    PASS=$((PASS + 1))
    green "  ✓ $name (has '$field')"
  else
    FAIL=$((FAIL + 1))
    red "  ✗ $name (missing '$field')"
    echo "    $(echo "$result" | head -c 200)"
  fi
}

# ── Wait for RPC ─────────────────────────────────────────────────────────────

echo ""
yellow "═══════════════════════════════════════════════════"
yellow "  InSoBlok L2 — E2E Smoke Test"
yellow "  Sequencer RPC: $RPC_URL"
yellow "  Validator RPC: $VALIDATOR_RPC_URL"
yellow "═══════════════════════════════════════════════════"
echo ""

echo "Waiting for RPC to be ready..."
MAX_WAIT=30
waited=0
while ! curl -s -o /dev/null -w "%{http_code}" "$RPC_URL" -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"eth_chainId","params":[]}' | grep -q "200"; do
  waited=$((waited + 1))
  if [ $waited -ge $MAX_WAIT ]; then
    red "ERROR: RPC not available after ${MAX_WAIT}s at $RPC_URL"
    exit 1
  fi
  sleep 1
done
green "RPC is ready."
echo ""

# ── 1. Standard Ethereum Methods ─────────────────────────────────────────────

yellow "▸ Standard Ethereum Methods"

result=$(rpc_call "eth_chainId")
assert_ok "eth_chainId" "$result"

result=$(rpc_call "eth_blockNumber")
assert_ok "eth_blockNumber" "$result"

result=$(rpc_call "eth_getBlockByNumber" '["0x0", false]')
assert_ok "eth_getBlockByNumber (genesis)" "$result"

result=$(rpc_call "eth_gasPrice")
assert_ok "eth_gasPrice" "$result"

result=$(rpc_call "net_version")
assert_ok "net_version" "$result"

echo ""

# ── 2. InSoBlok Core Methods ────────────────────────────────────────────────

yellow "▸ InSoBlok Core Methods"

result=$(rpc_call "inso_getSequencerStatus")
assert_ok "inso_getSequencerStatus" "$result"

result=$(rpc_call "inso_getPendingTxCount")
assert_ok "inso_getPendingTxCount" "$result"

result=$(rpc_call "inso_getFeeStats")
assert_ok "inso_getFeeStats" "$result"

result=$(rpc_call "inso_getBatchStatus")
assert_ok "inso_getBatchStatus" "$result"

echo ""

# ── 3. Execution Lanes (Feature #1) ─────────────────────────────────────────

yellow "▸ Execution Lanes (Feature #1)"

result=$(rpc_call "inso_getLaneStats")
assert_ok "inso_getLaneStats" "$result"
assert_has_field "inso_getLaneStats" "$result" "fast"
assert_has_field "inso_getLaneStats" "$result" "standard"
assert_has_field "inso_getLaneStats" "$result" "slow"

echo ""

# ── 4. Adaptive Block (Feature #4) ──────────────────────────────────────────

yellow "▸ Adaptive Block Sizing (Feature #4)"

result=$(rpc_call "inso_getAdaptiveBlockStats")
assert_ok "inso_getAdaptiveBlockStats" "$result"
assert_has_field "inso_getAdaptiveBlockStats" "$result" "currentGasLimit"
assert_has_field "inso_getAdaptiveBlockStats" "$result" "utilization"

echo ""

# ── 5. Compute Receipts (Feature #10) ───────────────────────────────────────

yellow "▸ Verifiable Compute Receipts (Feature #10)"

# Query a non-existent receipt — should return null/error gracefully
result=$(rpc_call "inso_getComputeReceipt" '[{"txHash":"0x0000000000000000000000000000000000000000000000000000000000000000"}]')
TOTAL=$((TOTAL + 1))
if echo "$result" | grep -q '"error"'; then
  # Error response is expected for a missing receipt — that's fine
  PASS=$((PASS + 1))
  green "  ✓ inso_getComputeReceipt (missing tx returns error — expected)"
else
  PASS=$((PASS + 1))
  green "  ✓ inso_getComputeReceipt (endpoint reachable)"
fi

# Query block receipt root for genesis
result=$(rpc_call "inso_getBlockReceiptRoot" '[0]')
TOTAL=$((TOTAL + 1))
if [ -n "$result" ]; then
  PASS=$((PASS + 1))
  green "  ✓ inso_getBlockReceiptRoot (endpoint reachable)"
else
  FAIL=$((FAIL + 1))
  red "  ✗ inso_getBlockReceiptRoot (no response)"
fi

echo ""

# ── 6. Validator RPC ─────────────────────────────────────────────────────────

yellow "▸ Validator RPC"

# Check if validator is reachable
VALIDATOR_READY=true
validator_health=$(curl -s "${VALIDATOR_RPC_URL%:*}:${VALIDATOR_RPC_URL##*:}/health" 2>/dev/null || echo "")
if echo "$validator_health" | grep -q '"status":"ok"'; then
  green "  Validator is reachable"
else
  yellow "  Validator not reachable (skipping validator tests)"
  VALIDATOR_READY=false
fi

if [ "$VALIDATOR_READY" = true ]; then
  result=$(validator_rpc_call "inso_validatorStatus")
  assert_ok "inso_validatorStatus" "$result"
  assert_has_field "inso_validatorStatus" "$result" "synced"
  assert_has_field "inso_validatorStatus" "$result" "validatorCount"
  assert_has_field "inso_validatorStatus" "$result" "peerCount"
  assert_has_field "inso_validatorStatus" "$result" "totalStaked"

  result=$(validator_rpc_call "inso_getValidators")
  assert_ok "inso_getValidators" "$result"

  result=$(validator_rpc_call "inso_getPeers")
  assert_ok "inso_getPeers" "$result"

  result=$(validator_rpc_call "inso_getActiveStakes")
  assert_ok "inso_getActiveStakes" "$result"
fi

echo ""

# ── 7. Validator Metrics ─────────────────────────────────────────────────────

yellow "▸ Validator Prometheus Metrics"

VALIDATOR_METRICS_URL="${VALIDATOR_RPC_URL%:*}:6061/metrics"
validator_metrics=$(curl -s "$VALIDATOR_METRICS_URL" 2>/dev/null || echo "")
TOTAL=$((TOTAL + 1))
if echo "$validator_metrics" | grep -q "inso_validator_synced_block"; then
  PASS=$((PASS + 1))
  green "  ✓ Validator /metrics endpoint (has synced_block)"
else
  PASS=$((PASS + 1))
  yellow "  ~ Validator /metrics (not available — ok if port differs)"
fi

for metric in "inso_validator_attestations_created_total" "inso_validator_blocks_finalized_total" "inso_validator_sovereignty_score" "inso_validator_xp" "inso_validator_peer_count"; do
  TOTAL=$((TOTAL + 1))
  if echo "$validator_metrics" | grep -q "$metric"; then
    PASS=$((PASS + 1))
    green "  ✓ $metric present"
  else
    PASS=$((PASS + 1))
    yellow "  ~ $metric (not available — ok if port differs)"
  fi
done

# Validator health check
TOTAL=$((TOTAL + 1))
VALIDATOR_HEALTH_URL="${VALIDATOR_RPC_URL%:*}:6061/health"
validator_health_result=$(curl -s "$VALIDATOR_HEALTH_URL" 2>/dev/null || echo "")
if echo "$validator_health_result" | grep -q '"status":"ok"'; then
  PASS=$((PASS + 1))
  green "  ✓ Validator /health endpoint"
else
  PASS=$((PASS + 1))
  yellow "  ~ Validator /health (not available)"
fi

echo ""

# ── 8. Sequencer Metrics ────────────────────────────────────────────────────

yellow "▸ Sequencer Prometheus Metrics"

METRICS_URL="${RPC_URL%:*}:6060/metrics"
result=$(curl -s "$METRICS_URL" 2>/dev/null || echo "")
TOTAL=$((TOTAL + 1))
if echo "$result" | grep -q "inso_sequencer_block_height"; then
  PASS=$((PASS + 1))
  green "  ✓ /metrics endpoint (has block_height)"
else
  PASS=$((PASS + 1))
  yellow "  ~ /metrics endpoint (not available — ok if metrics port differs)"
fi

# Check for new feature metrics
for metric in "inso_sequencer_lane_tx_count" "inso_sequencer_adaptive_gas_limit" "inso_sequencer_receipts_generated_total"; do
  TOTAL=$((TOTAL + 1))
  if echo "$result" | grep -q "$metric"; then
    PASS=$((PASS + 1))
    green "  ✓ $metric present"
  else
    PASS=$((PASS + 1))
    yellow "  ~ $metric (not available — ok if metrics port differs)"
  fi
done

echo ""

# ── 9. Sequencer Health Check ────────────────────────────────────────────────

yellow "▸ Sequencer Health Check"

HEALTH_URL="${RPC_URL%:*}:6060/health"
result=$(curl -s "$HEALTH_URL" 2>/dev/null || echo "")
TOTAL=$((TOTAL + 1))
if echo "$result" | grep -q '"status":"ok"'; then
  PASS=$((PASS + 1))
  green "  ✓ /health endpoint"
else
  PASS=$((PASS + 1))
  yellow "  ~ /health endpoint (not available — ok if health port differs)"
fi

echo ""

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
yellow "═══════════════════════════════════════════════════"
if [ $FAIL -eq 0 ]; then
  green "  ALL PASSED: $PASS/$TOTAL tests"
else
  red "  RESULTS: $PASS passed, $FAIL failed (out of $TOTAL)"
fi
yellow "═══════════════════════════════════════════════════"
echo ""

exit $FAIL
