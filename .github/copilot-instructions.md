<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# VPN Deployment System - Copilot Instructions

This is a comprehensive WireGuard VPN deployment and management system designed for dental software clients requiring HIPAA-compliant remote access.

## Project Context
- **Target**: Dental practices needing secure remote access to Optima/Open Dental
- **Current Client**: Dr. Jeff Kover - ServerOptima VPS deployment
- **Contract**: $375 flat-rate via Thumbtack
- **Security Focus**: HIPAA compliance and dental practice requirements

## Architecture Overview
- **Core**: Python-based key management and configuration generation
- **CLI Tools**: Command-line interfaces for key generation and client config
- **Web Dashboard**: Flask-based management interface
- **Scripts**: Shell scripts for VPS setup and automation
- **Testing**: Comprehensive testing and debugging utilities

## Key Components
1. **src/core/keys.py**: WireGuard key generation and encryption
2. **src/core/client_config.py**: Client configuration and QR code generation
3. **src/cli/**: Command-line tools for key and client management
4. **src/web/app.py**: Flask web dashboard for VPN management
5. **scripts/**: Shell scripts for server setup and client generation
6. **src/utils/testing.py**: Comprehensive VPN testing utilities

## Security Requirements
- All private keys must be handled securely
- Support for encrypted private key storage
- HIPAA-compliant configurations
- Secure client configuration distribution
- Regular security testing and validation

## Development Guidelines
- Use type hints for all Python functions
- Include comprehensive error handling
- Provide clear user feedback and status messages
- Follow security best practices for key handling
- Include testing utilities for all major components
- Support both CLI and web interfaces for flexibility

## Common Tasks
- Generate server/client key pairs with proper security
- Create client configurations with QR codes
- Manage VPN server setup and configuration
- Provide testing and debugging tools
- Handle secure key storage and distribution

When working on this project, prioritize security, user experience, and reliability suitable for professional dental practice environments.
