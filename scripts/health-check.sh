#!/bin/bash
# Health check for all devnet services — Phase 5 enhanced

set -e

echo "🔍 Checking InSo Devnet services..."
echo ""

# L1 Node
if curl -sf http://localhost:8551 > /dev/null 2>&1; then
  echo "✅ L1 Node (Anvil)     — http://localhost:8551"
else
  echo "❌ L1 Node (Anvil)     — NOT RUNNING"
fi

# Sequencer — liveness
if curl -sf http://localhost:8545/health > /dev/null 2>&1; then
  BLOCK=$(curl -s http://localhost:8545/health | grep -o '"currentBlock":[0-9]*' | cut -d: -f2)
  echo "✅ Sequencer Health    — http://localhost:8545/health (block: ${BLOCK:-?})"
else
  echo "❌ Sequencer Health    — NOT RUNNING"
fi

# Sequencer — readiness
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8545/ready 2>/dev/null || echo "000")
if [ "$STATUS" = "200" ]; then
  echo "✅ Sequencer Ready     — http://localhost:8545/ready"
else
  echo "⏳ Sequencer Ready     — NOT READY (HTTP $STATUS)"
fi

# Validator — liveness
if curl -sf http://localhost:8547/health > /dev/null 2>&1; then
  SYNCED=$(curl -s http://localhost:8547/health | grep -o '"synced":[a-z]*' | cut -d: -f2)
  PEERS=$(curl -s http://localhost:8547/health | grep -o '"peers":[0-9]*' | cut -d: -f2)
  echo "✅ Validator Health    — http://localhost:8547/health (synced: ${SYNCED:-?}, peers: ${PEERS:-?})"
else
  echo "❌ Validator Health    — NOT RUNNING"
fi

# Validator — readiness
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8547/ready 2>/dev/null || echo "000")
if [ "$STATUS" = "200" ]; then
  echo "✅ Validator Ready     — http://localhost:8547/ready"
else
  echo "⏳ Validator Ready     — NOT READY (HTTP $STATUS)"
fi

# Sequencer Metrics
if curl -sf http://localhost:6060/metrics > /dev/null 2>&1; then
  echo "✅ Sequencer Metrics   — http://localhost:6060/metrics"
else
  echo "❌ Sequencer Metrics   — NOT RUNNING"
fi

# Validator Metrics
if curl -sf http://localhost:6061/metrics > /dev/null 2>&1; then
  echo "✅ Validator Metrics   — http://localhost:6061/metrics"
else
  echo "❌ Validator Metrics   — NOT RUNNING"
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
echo "📊 Dashboard: http://localhost:3000/d/insoblok-overview"
echo "
echo "Done."
