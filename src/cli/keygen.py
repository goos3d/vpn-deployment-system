"""
Command Line Interface for Key Generation

Provides CLI commands for generating WireGuard keys with various options.
"""

import click
import os
import sys
from pathlib import Path

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from src.core.keys import WireGuardKeyManager, check_wireguard_installation


@click.command()
@click.option('--server', is_flag=True, help='Generate server keys')
@click.option('--client', help='Generate client keys (provide client name)')
@click.option('--output', '-o', default='/etc/wireguard', 
              help='Output directory (default: /etc/wireguard)')
@click.option('--encrypt', is_flag=True, help='Encrypt private key with password')
@click.option('--password', help='Password for encryption (will prompt if not provided)')
@click.option('--name', default='server', help='Server name/identifier (default: server)')
def main(server, client, output, encrypt, password, name):
    """
    WireGuard Key Generation Tool
    
    Generate secure WireGuard keys for servers and clients.
    """
    # Check if WireGuard is installed
    if not check_wireguard_installation():
        click.echo("❌ Error: WireGuard tools not found. Please install WireGuard first.")
        click.echo("   Ubuntu/Debian: sudo apt install wireguard")
        click.echo("   macOS: brew install wireguard-tools")
        sys.exit(1)
    
    try:
        key_manager = WireGuardKeyManager(output)
        
        if server:
            click.echo(f"🔐 Generating server keys...")
            
            # Handle password for encryption
            if encrypt:
                if not password:
                    password = click.prompt('Enter password for private key encryption', 
                                          hide_input=True, confirmation_prompt=True)
            
            result = key_manager.save_server_keys(
                name=name, 
                encrypt=encrypt, 
                password=password
            )
            
            click.echo("✅ Server keys generated successfully!")
            click.echo(f"   Server name: {result['name']}")
            click.echo(f"   Public key: {result['public_key']}")
            click.echo(f"   Private key file: {result['private_file']}")
            click.echo(f"   Public key file: {result['public_file']}")
            click.echo(f"   Preshared key file: {result['preshared_file']}")
            
            if encrypt:
                click.echo("   🔒 Private key is encrypted")
            
        elif client:
            click.echo(f"🔐 Generating client keys for: {client}")
            
            result = key_manager.save_client_keys(client)
            
            click.echo("✅ Client keys generated successfully!")
            click.echo(f"   Client name: {result['client_name']}")
            click.echo(f"   Public key: {result['public_key']}")
            click.echo(f"   Private key file: {result['private_file']}")
            click.echo(f"   Public key file: {result['public_file']}")
            
        else:
            click.echo("❌ Please specify either --server or --client <name>")
            sys.exit(1)
            
    except PermissionError:
        click.echo(f"❌ Permission denied: Cannot write to {output}")
        click.echo("   Try running with sudo or choose a different output directory")
        sys.exit(1)
    except Exception as e:
        click.echo(f"❌ Error: {str(e)}")
        sys.exit(1)


if __name__ == '__main__':
    main()
