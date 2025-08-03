"""
Command Line Interface for Client Configuration Generation

Provides CLI commands for generating WireGuard client configurations and QR codes.
"""

import click
import sys
from pathlib import Path

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from src.core.client_config import ClientConfigGenerator
from src.core.keys import WireGuardKeyManager


def load_server_public_key(key_file: str) -> str:
    """Load server public key from file."""
    key_path = Path(key_file)
    if not key_path.exists():
        raise FileNotFoundError(f"Server public key file not found: {key_file}")
    return key_path.read_text().strip()


@click.command()
@click.option('--name', '-n', required=True, help='Client name/identifier')
@click.option('--server-key', help='Path to server public key file')
@click.option('--server-ip', required=True, help='Server public IP address')
@click.option('--server-port', default=51820, help='Server port (default: 51820)')
@click.option('--client-ip', help='Specific IP to assign to client (auto-allocated if not provided)')
@click.option('--network', default='10.0.0.0/24', help='VPN network range (default: 10.0.0.0/24)')
@click.option('--dns', multiple=True, help='DNS servers (can specify multiple)')
@click.option('--allowed-ips', default='0.0.0.0/0', help='Traffic to route through VPN (default: all)')
@click.option('--output', '-o', default='./clients', help='Output directory (default: ./clients)')
@click.option('--no-qr', is_flag=True, help='Skip QR code generation')
@click.option('--keys-dir', default='/etc/wireguard', help='Directory containing keys (default: /etc/wireguard)')
@click.option('--preshared-key', help='Path to preshared key file for additional security')
def main(name, server_key, server_ip, server_port, client_ip, network, dns, 
         allowed_ips, output, no_qr, keys_dir, preshared_key):
    """
    WireGuard Client Configuration Generator
    
    Generate client configuration files and QR codes for easy setup.
    """
    try:
        # Load or find server public key
        if server_key:
            server_public_key = load_server_public_key(server_key)
        else:
            # Try to find server public key in keys directory
            possible_keys = [
                Path(keys_dir) / "server_public.key",
                Path(keys_dir) / "public.key",
                Path(keys_dir) / "server.pub"
            ]
            
            server_public_key = None
            for key_file in possible_keys:
                if key_file.exists():
                    server_public_key = key_file.read_text().strip()
                    click.echo(f"📁 Using server public key from: {key_file}")
                    break
            
            if not server_public_key:
                click.echo("❌ Server public key not found. Please specify --server-key")
                click.echo(f"   Searched in: {', '.join(str(k) for k in possible_keys)}")
                sys.exit(1)
        
        # Generate client keys if they don't exist
        key_manager = WireGuardKeyManager(keys_dir)
        client_keys_result = key_manager.save_client_keys(name)
        client_private_key = client_keys_result['private_key']
        client_public_key = client_keys_result['public_key']
        
        click.echo(f"🔐 Generated keys for client: {name}")
        click.echo(f"   Client public key: {client_public_key}")
        
        # Load preshared key if specified
        psk = None
        if preshared_key:
            psk_path = Path(preshared_key)
            if psk_path.exists():
                psk = psk_path.read_text().strip()
                click.echo(f"🔐 Using preshared key from: {preshared_key}")
            else:
                click.echo(f"⚠️  Warning: Preshared key file not found: {preshared_key}")
        
        # Set up DNS servers
        dns_servers = list(dns) if dns else ["1.1.1.1", "8.8.8.8"]
        
        # Create configuration generator
        config_gen = ClientConfigGenerator(
            server_public_key=server_public_key,
            server_endpoint=server_ip,
            server_port=server_port,
            network_base=network
        )
        
        # Generate client package
        click.echo(f"📄 Generating configuration for: {name}")
        
        result = config_gen.save_client_package(
            client_name=name,
            client_private_key=client_private_key,
            output_dir=output,
            generate_qr=not no_qr,
            client_ip=client_ip,
            dns_servers=dns_servers,
            allowed_ips=allowed_ips,
            preshared_key=psk
        )
        
        click.echo("✅ Client configuration generated successfully!")
        click.echo(f"   Configuration file: {result['config_file']}")
        
        if not no_qr:
            click.echo(f"   QR code: {result['qr_file']}")
        
        # Display server-side configuration
        server_config = config_gen.generate_server_config_section(
            client_public_key=client_public_key,
            client_ip=client_ip or config_gen.allocated_ips.pop(),
            preshared_key=psk
        )
        
        click.echo("\n📋 Add this to your server configuration (/etc/wireguard/wg0.conf):")
        click.echo(server_config)
        
        click.echo(f"\n📱 To connect:")
        click.echo(f"   1. Send {result['config_file']} to the client")
        if not no_qr:
            click.echo(f"   2. Or scan the QR code: {result['qr_file']}")
        click.echo(f"   3. Import into WireGuard app")
        
    except Exception as e:
        click.echo(f"❌ Error: {str(e)}")
        sys.exit(1)


if __name__ == '__main__':
    main()
