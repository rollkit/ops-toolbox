# ops-toolbox
Central hub for operations scripts, documentation, tutorials, and monitoring configurations. This repository serves as a reference and resource for DevOps practices, system automation, and team knowledge sharing.

## EV-Stacks

EV-Stacks provides Docker-based deployment stacks for Rollkit chains, enabling easy deployment of EVM-compatible blockchain infrastructure.

**Features:**
- One-command deployment of complete EVM stacks
- Single sequencer, full node, and data availability configurations
- Modular DA layer integration (Celestia support)
- Production-ready with monitoring and metrics

**Quick Start:**
```bash
bash -c "bash -i <(curl -s https://raw.githubusercontent.com/auricom/ev-stacks/main/deploy-rollkit.sh)"
```

See [EV-Stacks README](ev-stacks/README.md) for detailed documentation.
