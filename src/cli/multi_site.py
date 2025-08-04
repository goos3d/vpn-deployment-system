#!/usr/bin/env python3
"""
Multi-site VPN Configuration CLI

Extends the VPN system to support multi-location medical practices.
"""

import click
import json
import os
from pathlib import Path
from datetime import datetime

@click.group()
def multi_site():
    """Multi-site VPN management commands."""
    pass

@multi_site.command("create")
@click.option("--sites", required=True, help="Comma-separated list of site names")
@click.option("--client", required=True, help="Client name")
@click.option("--base-network", default="10.0.0.0/16", help="Base network for all sites")
def create_sites(sites, client, base_network):
    """Create multi-site VPN configuration."""
    site_list = [s.strip() for s in sites.split(",")]
    
    click.echo(f"🏥 Creating multi-site VPN for {client}")
    click.echo(f"📍 Sites: {', '.join(site_list)}")
    click.echo(f"🌐 Network: {base_network}")
    
    # Create client directory
    client_dir = Path(f"clients/{client}")
    client_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate site configurations
    configs = {}
    for i, site in enumerate(site_list, 1):
        subnet = f"10.0.{i}.0/24"
        configs[site] = {
            "subnet": subnet,
            "server_ip": f"10.0.{i}.1",
            "client_range": f"10.0.{i}.2-10.0.{i}.254",
            "port": 51820 + i - 1
        }
        
        click.echo(f"  ✅ {site}: {subnet} (Port {configs[site]['port']})")
    
    # Save configuration
    config_file = client_dir / "multi-site-config.json"
    with open(config_file, "w") as f:
        json.dump({
            "client": client,
            "created": datetime.now().isoformat(),
            "sites": configs,
            "base_network": base_network
        }, f, indent=2)
    
    click.echo(f"💾 Configuration saved: {config_file}")
    
    # Generate AI handoff instructions
    handoff_file = client_dir / "MULTI_SITE_HANDOFF.md"
    with open(handoff_file, "w") as f:
        f.write(f"""# 🤖 AI HANDOFF: Multi-Site VPN Setup

## 🎯 PRIMARY MISSION
**Objective**: Deploy multi-site VPN for {client}
**Priority**: HIGH
**Environment**: Multiple server locations
**Estimated Time**: 45-60 minutes

## 📋 SITES TO CONFIGURE
""")
        for site, config in configs.items():
            f.write(f"""
### {site}
- **Subnet**: {config['subnet']}
- **Server IP**: {config['server_ip']}
- **Port**: {config['port']}
- **Client Range**: {config['client_range']}
""")
        
        f.write(f"""
## 🔧 EXECUTION CONTEXT
```json
{{
  "client": "{client}",
  "sites": {len(site_list)},
  "network_type": "multi-site-mesh",
  "config_file": "{config_file}"
}}
```

## 📋 TASK QUEUE
### Immediate Tasks (This Handoff)
- [ ] Generate server keys for each site
- [ ] Create site-to-site routing configs
- [ ] Configure firewall rules for each location
- [ ] Test inter-site connectivity

### Follow-up Tasks (Next Handoff)
- [ ] Deploy configs to each server location
- [ ] Validate routing between all sites
- [ ] Generate client device configurations
- [ ] Create monitoring dashboard

## 🧪 VALIDATION COMMANDS
```bash
# Test connectivity between sites
ping {configs[site_list[0]]['server_ip']} # From site 2
ping {configs[site_list[1]]['server_ip'] if len(site_list) > 1 else '10.0.2.1'} # From site 1

# Check routing tables
ip route show | grep 10.0.

# Verify WireGuard status
wg show
```

## ✅ SUCCESS CRITERIA
- [ ] All sites can communicate with each other
- [ ] Routing tables configured correctly
- [ ] Firewall rules allow inter-site traffic
- [ ] No conflicts with existing networks
- [ ] Performance within acceptable range

## 💰 CLIENT VALUE
- **Traditional Setup Time**: 4-6 hours per site
- **AI Handoff Target**: 45-60 minutes total
- **Client Billing**: ${750 + (len(site_list) - 2) * 250} for {len(site_list)}-site deployment
""")
    
    click.echo(f"📋 AI Handoff instructions: {handoff_file}")
    click.echo(f"💰 Estimated project value: ${750 + (len(site_list) - 2) * 250}")

@multi_site.command("list")
@click.option("--client", help="Show sites for specific client")
def list_sites(client):
    """List multi-site configurations."""
    clients_dir = Path("clients")
    if not clients_dir.exists():
        click.echo("❌ No clients directory found")
        return
    
    if client:
        # Show specific client
        client_dir = clients_dir / client
        config_file = client_dir / "multi-site-config.json"
        if config_file.exists():
            with open(config_file) as f:
                config = json.load(f)
            
            click.echo(f"🏥 {config['client']}")
            click.echo(f"📅 Created: {config['created']}")
            click.echo(f"🌐 Base Network: {config['base_network']}")
            click.echo("📍 Sites:")
            for site, site_config in config['sites'].items():
                click.echo(f"  • {site}: {site_config['subnet']} (Port {site_config['port']})")
        else:
            click.echo(f"❌ No multi-site config found for {client}")
    else:
        # Show all clients
        click.echo("🏥 Multi-Site VPN Clients:")
        for client_dir in clients_dir.iterdir():
            if client_dir.is_dir():
                config_file = client_dir / "multi-site-config.json"
                if config_file.exists():
                    with open(config_file) as f:
                        config = json.load(f)
                    site_count = len(config['sites'])
                    click.echo(f"  • {config['client']}: {site_count} sites")

if __name__ == "__main__":
    multi_site()
