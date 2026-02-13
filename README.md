# InSo Devnet

One-command local development network for the InSoBlok L2 blockchain. Spins up the sequencer, validator(s), explorer, and supporting services using Docker Compose.

## Quick Start

```bash
# Clone with submodules (or standalone)
git clone https://github.com/insoblok/inso-devnet.git
cd inso-devnet

# Start all services
docker compose up

# Or start in background
docker compose up -d
```

That's it! Your local InSoBlok devnet is running:

| Service | URL | Description |
|---------|-----|-------------|
| **Sequencer RPC** | `http://localhost:8545` | JSON-RPC endpoint |
| **Sequencer WS** | `ws://localhost:8546` | WebSocket endpoint |
| **Validator RPC** | `http://localhost:8547` | Validator API |
| **Explorer** | `http://localhost:3001` | Block explorer UI |
| **Metrics** | `http://localhost:3000` | Grafana dashboards |
| **Prometheus** | `http://localhost:9090` | Metrics collection |

## Architecture

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Explorer   │────▶│  Sequencer   │◀────│  Validator   │
│  :3001       │     │  :8545/:8546 │     │  :8547/:30303│
└──────────────┘     └──────┬───────┘     └──────────────┘
                            │
                     ┌──────▼───────┐
                     │   L1 Geth    │
                     │   (anvil)    │
                     │   :8551      │
                     └──────────────┘

┌──────────────┐     ┌──────────────┐
│   Grafana    │────▶│  Prometheus  │
│   :3000      │     │  :9090       │
└──────────────┘     └──────────────┘
```

## Services

### Core
- **sequencer** — InSo Sequencer for transaction ordering and block production
- **validator** — InSo Validator for block verification and consensus
- **l1-node** — Anvil (Foundry) as a mock L1 Ethereum node

### Frontend
- **explorer** — InSo Explorer block explorer UI

### Monitoring
- **prometheus** — Metrics collection from sequencer & validator
- **grafana** — Pre-configured dashboards for network health

## Configuration

### Environment variables
Copy and edit the env file:
```bash
cp .env.example .env
```

### Scale validators
```bash
docker compose up --scale validator=3
```

### Reset all data
```bash
docker compose down -v
```

### View logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f sequencer
```

## Pre-funded Accounts

The devnet comes with pre-funded accounts for development:

| Account | Address | Private Key | Balance |
|---------|---------|-------------|---------|
| Deployer | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80` | 10,000 INSO |
| User 1 | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d` | 10,000 INSO |
| User 2 | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` | `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a` | 10,000 INSO |
| Validator | `0x90F79bf6EB2c4f870365E785982E1f101E93b906` | `0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6` | 100,000 INSO |

> **Warning:** These are well-known Hardhat/Anvil keys. Never use them on mainnet.

## Project Structure

```
inso-devnet/
├── docker-compose.yml      # Main orchestration file
├── .env.example            # Environment variables template
├── config/
│   ├── sequencer.yaml      # Sequencer configuration
│   ├── validator.yaml      # Validator configuration
│   ├── prometheus.yml      # Prometheus scrape config
│   └── grafana/
│       └── dashboards/     # Pre-built Grafana dashboards
├── genesis/
│   └── genesis.json        # L2 genesis state
├── scripts/
│   ├── fund-accounts.sh    # Fund dev accounts on startup
│   └── health-check.sh     # Service health checker
└── README.md
```

## Developing Against the Devnet

### Connect MetaMask
- Network Name: `InSoBlok Local`
- RPC URL: `http://localhost:8545`
- Chain ID: `42069`
- Symbol: `INSO`

### Deploy a contract
```bash
# Using Foundry
forge create --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  src/MyContract.sol:MyContract

# Using Hardhat
npx hardhat run scripts/deploy.ts --network inso-local
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

Apache-2.0
