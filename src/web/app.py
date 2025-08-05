"""
Flask Web Dashboard for VPN Management

Provides a web interface for managing WireGuard VPN clients and configurations.
"""

import os
import sys
from pathlib import Path
from flask import Flask, render_template, request, jsonify, send_file
from datetime import datetime
import subprocess
import json

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from src.core.keys import WireGuardKeyManager
from src.core.client_config import ClientConfigGenerator


class VPNDashboard:
    """Main VPN management dashboard."""
    
    def __init__(self, keys_dir="/etc/wireguard", server_endpoint=None):
        self.app = Flask(__name__)
        self.keys_dir = keys_dir
        self.server_endpoint = server_endpoint
        self.key_manager = WireGuardKeyManager(keys_dir)
        
        # Try to load server configuration
        self.server_config = self._load_server_config()
        
        # Set up routes
        self._setup_routes()
    
    def _load_server_config(self):
        """Load server configuration and public key."""
        config = {}
        
        # Try to find server public key
        possible_keys = [
            Path(self.keys_dir) / "server_public.key",
            Path(self.keys_dir) / "public.key"
        ]
        
        for key_file in possible_keys:
            if key_file.exists():
                config['public_key'] = key_file.read_text().strip()
                break
        
        # Try to get server endpoint from environment or config
        config['endpoint'] = (
            self.server_endpoint or 
            os.environ.get('VPN_SERVER_ENDPOINT') or
            'YOUR_SERVER_IP'
        )
        
        config['port'] = int(os.environ.get('VPN_SERVER_PORT', 51820))
        config['network'] = os.environ.get('VPN_NETWORK', '10.0.0.0/24')
        
        return config
    
    def _setup_routes(self):
        """Set up Flask routes."""
        
        @self.app.route('/')
        def dashboard():
            """Main dashboard page."""
            clients = self._get_clients()
            server_status = self._get_server_status()
            
            return render_template('dashboard.html', 
                                 clients=clients,
                                 server_status=server_status,
                                 server_config=self.server_config)
        
        @self.app.route('/api/clients')
        def api_clients():
            """API endpoint for client list."""
            return jsonify(self._get_clients())
        
        @self.app.route('/api/client/create', methods=['POST'])
        def api_create_client():
            """API endpoint for creating new client."""
            data = request.get_json()
            client_name = data.get('name')
            
            if not client_name:
                return jsonify({'error': 'Client name required'}), 400
            
            try:
                # Generate client keys
                client_keys = self.key_manager.save_client_keys(client_name)
                
                # Generate configuration
                if 'public_key' not in self.server_config:
                    return jsonify({'error': 'Server public key not found'}), 500
                
                config_gen = ClientConfigGenerator(
                    server_public_key=self.server_config['public_key'],
                    server_endpoint=self.server_config['endpoint'],
                    server_port=self.server_config['port'],
                    network_base=self.server_config['network']
                )
                
                # Use working MacBook-Test pattern: VPN network only (preserves internet)
                result = config_gen.save_client_package(
                    client_name=client_name,
                    client_private_key=client_keys['private_key'],
                    output_dir=Path(self.keys_dir) / "clients",
                    generate_qr=True,
                    allowed_ips="10.0.0.0/24"  # CRITICAL: Only VPN network, not 0.0.0.0/0
                )
                
                return jsonify({
                    'success': True,
                    'client': {
                        'name': client_name,
                        'public_key': client_keys['public_key'],
                        'config_file': result['config_file'],
                        'qr_file': result.get('qr_file'),
                        'created': datetime.now().isoformat()
                    }
                })
                
            except Exception as e:
                return jsonify({'error': str(e)}), 500
        
        @self.app.route('/api/client/<client_name>/config')
        def api_client_config(client_name):
            """Download client configuration file."""
            config_file = Path(self.keys_dir) / "clients" / client_name / f"{client_name}.conf"
            
            if not config_file.exists():
                return jsonify({'error': 'Configuration not found'}), 404
            
            return send_file(config_file, as_attachment=True)
        
        @self.app.route('/api/client/<client_name>/qr')
        def api_client_qr(client_name):
            """Download client QR code."""
            qr_file = Path(self.keys_dir) / "clients" / client_name / f"{client_name}_qr.png"
            
            if not qr_file.exists():
                return jsonify({'error': 'QR code not found'}), 404
            
            return send_file(qr_file, mimetype='image/png')
        
        @self.app.route('/api/server/status')
        def api_server_status():
            """API endpoint for server status."""
            return jsonify(self._get_server_status())
    
    def _get_clients(self):
        """Get list of configured clients."""
        clients = []
        clients_dir = Path(self.keys_dir) / "clients"
        
        if clients_dir.exists():
            for client_dir in clients_dir.iterdir():
                if client_dir.is_dir():
                    public_key_file = client_dir / "public.key"
                    config_file = client_dir / f"{client_dir.name}.conf"
                    qr_file = client_dir / f"{client_dir.name}_qr.png"
                    
                    client_info = {
                        'name': client_dir.name,
                        'has_config': config_file.exists(),
                        'has_qr': qr_file.exists(),
                        'created': datetime.fromtimestamp(client_dir.stat().st_ctime).isoformat()
                    }
                    
                    if public_key_file.exists():
                        client_info['public_key'] = public_key_file.read_text().strip()
                    
                    clients.append(client_info)
        
        return clients
    
    def _get_server_status(self):
        """Get WireGuard server status."""
        status = {
            'running': False,
            'interface': None,
            'peers': [],
            'error': None
        }
        
        try:
            # Check if WireGuard interface is up
            result = subprocess.run(['wg', 'show'], capture_output=True, text=True)
            if result.returncode == 0:
                status['running'] = True
                status['interface'] = result.stdout
                
                # Parse peer information
                lines = result.stdout.strip().split('\n')
                current_peer = None
                
                for line in lines:
                    line = line.strip()
                    if line.startswith('peer:'):
                        if current_peer:
                            status['peers'].append(current_peer)
                        current_peer = {'public_key': line.split(': ')[1]}
                    elif current_peer and ':' in line:
                        key, value = line.split(': ', 1)
                        current_peer[key.strip()] = value.strip()
                
                if current_peer:
                    status['peers'].append(current_peer)
            
        except Exception as e:
            status['error'] = str(e)
        
        return status
    
    def run(self, host='0.0.0.0', port=5000, debug=False):
        """Run the Flask application."""
        self.app.run(host=host, port=port, debug=debug)


def main():
    """Main entry point for the web dashboard."""
    import click
    
    @click.command()
    @click.option('--host', default='0.0.0.0', help='Host to bind to')
    @click.option('--port', default=5000, help='Port to bind to')
    @click.option('--debug', is_flag=True, help='Enable debug mode')
    @click.option('--keys-dir', default='/etc/wireguard', help='Directory containing keys')
    @click.option('--server-endpoint', help='Server public IP/endpoint')
    def run_dashboard(host, port, debug, keys_dir, server_endpoint):
        """Run the VPN management web dashboard."""
        dashboard = VPNDashboard(keys_dir=keys_dir, server_endpoint=server_endpoint)
        
        click.echo(f"🌐 Starting VPN Dashboard on http://{host}:{port}")
        click.echo(f"📁 Keys directory: {keys_dir}")
        
        if debug:
            click.echo("🐛 Debug mode enabled")
        
        dashboard.run(host=host, port=port, debug=debug)
    
    run_dashboard()


if __name__ == '__main__':
    main()
