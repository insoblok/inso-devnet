#!/bin/bash
# Health check for all devnet services

set -e

echo "🔍 Checking InSo Devnet services..."

# L1 Node
if curl -sf http://localhost:8551 > /dev/null 2>&1; then
  echo "✅ L1 Node (Anvil)     — http://localhost:8551"
else
  echo "❌ L1 Node (Anvil)     — NOT RUNNING"
fi

# Sequencer
if curl -sf http://localhost:8545 > /dev/null 2>&1; then
  echo "✅ Sequencer RPC       — http://localhost:8545"
else
  echo "❌ Sequencer RPC       — NOT RUNNING"
fi

# Validator
if curl -sf http://localhost:8547 > /dev/null 2>&1; then
  echo "✅ Validator RPC       — http://localhost:8547"
else
  echo "❌ Validator RPC       — NOT RUNNING"
fi

# Explorer
if curl -sf http://localhost:3001 > /dev/null 2>&1; then
  echo "✅ Explorer            — http://localhost:3001"
else
  echo "❌ Explorer            — NOT RUNNING"
fi

# Prometheus
if curl -sf http://localhost:9090/-/healthy > /dev/null 2>&1; then
  echo "✅ Prometheus          — http://localhost:9090"
else
  echo "❌ Prometheus          — NOT RUNNING"
fi

# Grafana
if curl -sf http://localhost:3000/api/health > /dev/null 2>&1; then
  echo "✅ Grafana             — http://localhost:3000"
else
  echo "❌ Grafana             — NOT RUNNING"
fi

echo ""
echo "Done."
