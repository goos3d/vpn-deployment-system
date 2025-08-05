#!/usr/bin/env python3
"""
Professional VPN Deployment System - Main CLI

Complete HIPAA-compliant VPN solution for healthcare practices.
Provides automated deployment, management, and compliance reporting.
"""

import click
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from src.cli.keygen import main as keygen_main
from src.cli.client_config import main as client_config_main
from src.cli.multi_site import multi_site
from src.cli.monitoring import monitor
from src.cli.compliance import compliance
from src.cli.backup import backup
from src.web.app import main as dashboard_main
from src.utils.testing import main as testing_main

# Import screenshot CLI integration
try:
    from src.screenshot.cli_integration import add_screenshot_commands
    SCREENSHOT_AVAILABLE = True
except ImportError:
    SCREENSHOT_AVAILABLE = False


@click.group()
@click.version_option("3.0.0")
def cli():
    """
    🏥 Professional VPN Deployment System - Enterprise Edition
    
    Complete HIPAA-compliant VPN infrastructure for healthcare organizations.
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


# Add all command groups
cli.add_command(multi_site, name="multi-site")
cli.add_command(monitor)
cli.add_command(compliance)
cli.add_command(backup)

# Add screenshot commands if available
if SCREENSHOT_AVAILABLE:
    add_screenshot_commands(cli)


@cli.command("dashboard")
@click.option('--host', default='127.0.0.1', help='Host to bind to')
@click.option('--port', default=5000, help='Port to bind to')
@click.option('--debug', is_flag=True, help='Enable debug mode')
@click.option('--keys-dir', default='./keys', help='Directory containing keys')
@click.option('--server-endpoint', help='Server public IP/endpoint')
def dashboard(host, port, debug, keys_dir, server_endpoint):
    """Launch the web management dashboard."""
    from src.web.app import VPNDashboard
    
    dashboard_app = VPNDashboard(keys_dir=keys_dir, server_endpoint=server_endpoint)
    
    click.echo(f"🌐 Starting VPN Dashboard on http://{host}:{port}")
    click.echo(f"📁 Keys directory: {keys_dir}")
    
    if debug:
        click.echo("🐛 Debug mode enabled")
    
    dashboard_app.run(host=host, port=port, debug=debug)


@cli.command("test")
@click.pass_context
def test(ctx):
    """Run VPN testing and diagnostics."""
    ctx.forward(testing_main)


@cli.command("info")
def info():
    """Display system information and status."""
    click.echo("🛡️ VPN Deployment System v3.0.0 - Enterprise Edition")
    click.echo("=" * 55)
    click.echo("Professional VPN solutions for healthcare organizations")
    click.echo("")
    click.echo("📋 Core Commands:")
    click.echo("  • keygen      - Generate WireGuard keys")
    click.echo("  • client      - Create client configurations") 
    click.echo("  • multi-site  - Multi-location VPN deployments")
    click.echo("  • dashboard   - Launch web management UI")
    click.echo("  • test        - Run diagnostics")
    click.echo("")
    click.echo("🔧 Enterprise Features:")
    click.echo("  • monitor     - Real-time monitoring & alerts")
    click.echo("  • compliance  - HIPAA audit & reporting")
    click.echo("  • backup      - Disaster recovery & backups")
    if SCREENSHOT_AVAILABLE:
        click.echo("  • screenshot  - AI-powered screenshot analysis")
    click.echo("")
    click.echo("🏥 Healthcare Specialization:")
    click.echo("  • HIPAA Technical Safeguards compliance")
    click.echo("  • Automated compliance reporting")
    click.echo("  • Real-time security monitoring")
    click.echo("  • Professional audit documentation")
    click.echo("  • Disaster recovery capabilities")
    click.echo("")
    click.echo("� Service Packages:")
    click.echo("  • Single Site: $375-500")
    click.echo("  • Multi-Site: $750-1500") 
    click.echo("  • Enterprise: $1500-3000")
    click.echo("")
    click.echo("�📚 Documentation: docs/DEPLOYMENT_GUIDE.md")
    click.echo("🌐 Web Dashboard: python vpn.py dashboard")
    click.echo("📊 Quick Status: python vpn.py monitor status")
    click.echo("🔍 Compliance Check: python vpn.py compliance quick-check")


@cli.command("quick-setup")
@click.option("--client-name", required=True, help="Client/practice name")
@click.option("--package", default="professional", 
              type=click.Choice(["basic", "professional", "enterprise"]),
              help="Service package level")
def quick_setup(client_name: str, package: str):
    """Quick setup wizard for new VPN deployments."""
    click.echo(f"🚀 Setting up {package} VPN package for {client_name}")
    click.echo("=" * 50)
    
    package_features = {
        "basic": [
            "Generate server keys",
            "Create client configuration", 
            "Basic security setup"
        ],
        "professional": [
            "Generate server keys",
            "Create client configuration",
            "HIPAA compliance verification",
            "Professional documentation",
            "Basic monitoring setup"
        ],
        "enterprise": [
            "Generate server keys", 
            "Multi-site configuration",
            "Full compliance audit",
            "Real-time monitoring",
            "Automated backups",
            "Professional reporting"
        ]
    }
    
    click.echo(f"📦 {package.title()} Package includes:")
    for feature in package_features[package]:
        click.echo(f"  ✅ {feature}")
    
    click.echo(f"\n🔧 Run these commands to complete setup:")
    click.echo(f"  1. python vpn.py keygen --server")
    click.echo(f"  2. python vpn.py client --name '{client_name}-Admin'")
    
    if package in ["professional", "enterprise"]:
        click.echo(f"  3. python vpn.py compliance audit --client '{client_name}'")
        click.echo(f"  4. python vpn.py monitor setup")
    
    if package == "enterprise":
        click.echo(f"  5. python vpn.py backup configure")
        click.echo(f"  6. python vpn.py multi-site create '{client_name}-Network'")
    
    click.echo(f"\n💡 Quick start dashboard: python vpn.py dashboard")


if __name__ == "__main__":
    cli()
