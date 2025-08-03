#!/usr/bin/env python3
"""
VPN Deployment System CLI Entry Point

Provides a unified command-line interface for all VPN management tasks.
"""

import click
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from src.cli.keygen import main as keygen_main
from src.cli.client_config import main as client_config_main
from src.web.app import main as dashboard_main
from src.utils.testing import main as testing_main


@click.group()
@click.version_option("1.0.0")
def cli():
    """
    🛡️ VPN Deployment System
    
    Comprehensive WireGuard VPN management for dental software clients.
    """
    pass


@cli.command("keygen")
@click.pass_context
def keygen(ctx):
    """Generate WireGuard keys for servers and clients."""
    ctx.forward(keygen_main)


@cli.command("client")
@click.pass_context  
def client(ctx):
    """Generate client configurations and QR codes."""
    ctx.forward(client_config_main)


@cli.command("dashboard")
@click.pass_context
def dashboard(ctx):
    """Launch the web management dashboard."""
    ctx.forward(dashboard_main)


@cli.command("test")
@click.pass_context
def test(ctx):
    """Run VPN testing and diagnostics."""
    ctx.forward(testing_main)


@cli.command("info")
def info():
    """Display system information and status."""
    click.echo("🛡️ VPN Deployment System v1.0.0")
    click.echo("=" * 40)
    click.echo("For dental software secure remote access")
    click.echo("")
    click.echo("📋 Available Commands:")
    click.echo("  • keygen     - Generate WireGuard keys")
    click.echo("  • client     - Create client configurations")
    click.echo("  • dashboard  - Launch web management UI")
    click.echo("  • test       - Run diagnostics")
    click.echo("")
    click.echo("📚 Documentation: docs/DEPLOYMENT_GUIDE.md")
    click.echo("🌐 Web Dashboard: python -m vpn dashboard")


if __name__ == "__main__":
    cli()
