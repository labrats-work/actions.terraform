# WireGuard VPN GitHub Action

A composite GitHub Action for establishing WireGuard VPN connections in CI/CD workflows.

## Overview

This action simplifies the process of connecting to a network via WireGuard VPN during GitHub Actions workflows. It's particularly useful for infrastructure management workflows that need to access internal resources.

## Prerequisites

- Container with NET_ADMIN and SYS_MODULE capabilities
- WireGuard tools installed in the container
- WireGuard configuration stored as a GitHub secret

## Usage

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    container: 
      image: your-container-with-wireguard
      options: --cap-add NET_ADMIN --cap-add SYS_MODULE --sysctl net.ipv4.conf.all.src_valid_mark=1
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Connect to VPN
        uses: ./.github/actions/wireguard-vpn
        with:
          config: ${{ secrets.WG_PEER_CONFIG }}
      
      # Your other steps that require VPN access
      - name: Run tests
        run: ./run_tests.sh
```

## Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `config` | WireGuard peer configuration content | Yes |

## Implementation Details

The action:

1. Creates a WireGuard configuration file from the provided secret
2. Disables the problematic sysctl command in wg-quick (which is already handled by the container options)
3. Establishes the VPN connection using wg-quick

## Security Considerations

- The WireGuard config should be stored as a GitHub secret
- Ensure your container has the necessary capabilities
- Consider using environment protection rules for production environments

## License

MIT