# Changelog

All notable changes to the EV-Stacks deployment framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-12-08

### Added
- Support for separate header and data namespaces in Celestia DA integration
- New environment variables `DA_HEADER_NAMESPACE` and `DA_DATA_NAMESPACE`
- Enhanced deployment script prompts for both namespace configurations
- Improved validation for both header and data namespace inputs
- Added `--ev-reth.enable` flag to ev-reth node configurations for proper integration

### Changed
- **BREAKING**: Replaced single `DA_NAMESPACE` environment variable with two separate variables:
  - `DA_HEADER_NAMESPACE` - for header blob categorization on Celestia
  - `DA_DATA_NAMESPACE` - for data blob categorization on Celestia
- **BREAKING**: Changed namespace format from 58-character hex strings to encoded string identifiers:
  - Old format: `000000000000000000000000000000000000002737d4d967c7ca526dd5`
  - New format: `namespace_test_header` or `namespace_test_data`
- Updated Rollkit flags to use new namespace parameters:
  - `--rollkit.da.namespace` → `--rollkit.da.header_namespace` and `--rollkit.da.data_namespace`
- Component naming updates to reflect current project names:
  - Rollkit → Ev-node (consensus layer)
  - Lumen → Ev-reth (execution layer)
- Updated all Docker Compose files to use the new namespace environment variables
- Enhanced deployment script configuration management for namespace propagation
- Updated documentation and examples to reflect the new namespace structure

### Removed
- **BREAKING**: Removed deprecated `DA_NAMESPACE` environment variable
- **BREAKING**: Removed deprecated `--chain_id` flag from ev-node start command
- Removed all references to the old single namespace configuration

### Migration Guide
If you are upgrading from version 1.0.0:

1. **Update Environment Variables**: Replace `DA_NAMESPACE` with both `DA_HEADER_NAMESPACE` and `DA_DATA_NAMESPACE` in your `.env` files
2. **Update Namespace Format**: Convert from 58-character hex strings to encoded string identifiers
3. **Namespace Values**: You can use similar namespace identifiers for both header and data, or specify different namespaces for separation
4. **Redeploy**: Run the deployment script again to ensure all configurations are updated with the new namespace variables

Example migration:
```bash
# Before (v1.0.0)
DA_NAMESPACE="000000000000000000000000000000000000002737d4d967c7ca526dd5"

# After (v1.1.0)
DA_HEADER_NAMESPACE="namespace_test_header"
DA_DATA_NAMESPACE="namespace_test_data"
```

### Technical Details
- The deployment script now prompts users to enter both namespace values separately during setup
- Both namespaces undergo validation for encoded string format (alphanumeric characters, underscores, and hyphens)
- The script automatically propagates namespace values from da-celestia configuration to sequencer and fullnode configurations
- All entrypoint scripts have been updated to handle the new namespace flags correctly

## [1.0.0] - 2025-07-31

### Added
- Initial release of EV-Stacks deployment framework
- Single sequencer deployment stack
- Celestia DA integration support
- Fullnode deployment option
- Interactive deployment script with guided setup
- Docker Compose based deployment architecture
- Automated configuration management
- Genesis block customization
- JWT token generation and management
- Comprehensive documentation and examples

### Features
- One-liner deployment script for easy setup
- Support for Celestia mocha-4 testnet integration
- Automatic service dependency management
- Health monitoring and logging capabilities
- Backup and recovery procedures
- Service management commands
- Network endpoint configuration
