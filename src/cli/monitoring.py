"""
Real-time VPN Monitoring and Analytics Module

Professional monitoring solution for healthcare VPN deployments.
Generates compliance reports, tracks usage patterns, and provides alerts.
"""

import json
import time
import subprocess
import smtplib
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import click


class VPNMonitor:
    """Professional VPN monitoring and alerting system."""
    
    def __init__(self, config_file: Optional[str] = None):
        self.config_file = config_file or "monitoring_config.json"
        self.config = self._load_config()
        self.data_dir = Path("monitoring_data")
        self.data_dir.mkdir(exist_ok=True)
    
    def _load_config(self) -> Dict:
        """Load monitoring configuration."""
        default_config = {
            "alert_email": "",
            "smtp_server": "smtp.gmail.com",
            "smtp_port": 587,
            "smtp_username": "",
            "smtp_password": "",
            "check_interval": 300,  # 5 minutes
            "offline_threshold": 600,  # 10 minutes
            "data_retention_days": 90,
            "interfaces": ["wg0"],
            "alerts_enabled": True,
            "report_schedule": "daily"
        }
        
        try:
            if Path(self.config_file).exists():
                with open(self.config_file, 'r') as f:
                    loaded_config = json.load(f)
                    default_config.update(loaded_config)
        except Exception as e:
            print(f"⚠️  Warning: Could not load config ({e}), using defaults")
        
        return default_config
    
    def save_config(self):
        """Save current configuration."""
        with open(self.config_file, 'w') as f:
            json.dump(self.config, f, indent=2)
    
    def collect_metrics(self) -> Dict:
        """Collect current VPN metrics."""
        metrics = {
            "timestamp": datetime.now().isoformat(),
            "interfaces": {},
            "system": self._get_system_metrics()
        }
        
        for interface in self.config["interfaces"]:
            try:
                # Get WireGuard interface stats
                result = subprocess.run(
                    ["wg", "show", interface, "dump"],
                    capture_output=True, text=True, check=True
                )
                
                interface_data = {
                    "status": "active",
                    "peers": [],
                    "total_rx": 0,
                    "total_tx": 0
                }
                
                lines = result.stdout.strip().split('\n')
                for line in lines[1:]:  # Skip header
                    if line.strip():
                        parts = line.split('\t')
                        if len(parts) >= 6:
                            peer_data = {
                                "public_key": parts[0][:16] + "...",  # Truncated for privacy
                                "endpoint": parts[2] if parts[2] != "(none)" else None,
                                "allowed_ips": parts[3],
                                "latest_handshake": parts[4],
                                "rx_bytes": int(parts[5]) if parts[5].isdigit() else 0,
                                "tx_bytes": int(parts[6]) if parts[6].isdigit() else 0,
                                "connected": self._is_peer_connected(parts[4])
                            }
                            
                            interface_data["peers"].append(peer_data)
                            interface_data["total_rx"] += peer_data["rx_bytes"]
                            interface_data["total_tx"] += peer_data["tx_bytes"]
                
                metrics["interfaces"][interface] = interface_data
                
            except subprocess.CalledProcessError:
                metrics["interfaces"][interface] = {"status": "inactive", "error": "Interface not found"}
        
        return metrics
    
    def _is_peer_connected(self, handshake_time: str) -> bool:
        """Check if peer is considered connected based on handshake time."""
        if not handshake_time or handshake_time == "0":
            return False
        
        try:
            handshake_timestamp = int(handshake_time)
            current_timestamp = int(time.time())
            
            # Consider connected if handshake within offline threshold
            return (current_timestamp - handshake_timestamp) < self.config["offline_threshold"]
        except (ValueError, TypeError):
            return False
    
    def _get_system_metrics(self) -> Dict:
        """Get system-level metrics."""
        metrics = {}
        
        try:
            # CPU and memory
            with open('/proc/loadavg', 'r') as f:
                load_avg = f.read().strip().split()
                metrics['load_average'] = float(load_avg[0])
            
            with open('/proc/meminfo', 'r') as f:
                meminfo = f.read()
                for line in meminfo.split('\n'):
                    if 'MemTotal:' in line:
                        metrics['memory_total'] = int(line.split()[1]) * 1024
                    elif 'MemAvailable:' in line:
                        metrics['memory_available'] = int(line.split()[1]) * 1024
            
            if 'memory_total' in metrics and 'memory_available' in metrics:
                metrics['memory_usage_percent'] = (
                    (metrics['memory_total'] - metrics['memory_available']) / 
                    metrics['memory_total'] * 100
                )
        
        except Exception as e:
            metrics['error'] = str(e)
        
        return metrics
    
    def store_metrics(self, metrics: Dict):
        """Store metrics to time-series data file."""
        date_str = datetime.now().strftime("%Y-%m-%d")
        metrics_file = self.data_dir / f"metrics_{date_str}.jsonl"
        
        with open(metrics_file, 'a') as f:
            f.write(json.dumps(metrics) + '\n')
    
    def check_alerts(self, metrics: Dict) -> List[Dict]:
        """Check for alert conditions."""
        alerts = []
        
        if not self.config.get("alerts_enabled", True):
            return alerts
        
        # Check interface status
        for interface_name, interface_data in metrics["interfaces"].items():
            if interface_data.get("status") != "active":
                alerts.append({
                    "type": "interface_down",
                    "severity": "critical",
                    "message": f"Interface {interface_name} is not active",
                    "interface": interface_name,
                    "timestamp": metrics["timestamp"]
                })
        
        # Check peer connections
        for interface_name, interface_data in metrics["interfaces"].items():
            if interface_data.get("status") == "active":
                total_peers = len(interface_data.get("peers", []))
                connected_peers = len([p for p in interface_data.get("peers", []) if p.get("connected")])
                
                if total_peers > 0 and connected_peers == 0:
                    alerts.append({
                        "type": "all_peers_offline",
                        "severity": "high",
                        "message": f"All {total_peers} peers offline on {interface_name}",
                        "interface": interface_name,
                        "timestamp": metrics["timestamp"]
                    })
                elif connected_peers < total_peers:
                    offline_count = total_peers - connected_peers
                    alerts.append({
                        "type": "peers_offline",
                        "severity": "medium",
                        "message": f"{offline_count}/{total_peers} peers offline on {interface_name}",
                        "interface": interface_name,
                        "timestamp": metrics["timestamp"]
                    })
        
        # Check system metrics
        system_metrics = metrics.get("system", {})
        if system_metrics.get("memory_usage_percent", 0) > 90:
            alerts.append({
                "type": "high_memory",
                "severity": "medium",
                "message": f"High memory usage: {system_metrics['memory_usage_percent']:.1f}%",
                "timestamp": metrics["timestamp"]
            })
        
        if system_metrics.get("load_average", 0) > 2.0:
            alerts.append({
                "type": "high_load",
                "severity": "medium",
                "message": f"High system load: {system_metrics['load_average']:.2f}",
                "timestamp": metrics["timestamp"]
            })
        
        return alerts
    
    def send_alert_email(self, alerts: List[Dict]):
        """Send alert notifications via email."""
        if not alerts or not self.config.get("alert_email"):
            return
        
        try:
            # Group alerts by severity
            critical_alerts = [a for a in alerts if a["severity"] == "critical"]
            high_alerts = [a for a in alerts if a["severity"] == "high"]
            medium_alerts = [a for a in alerts if a["severity"] == "medium"]
            
            # Create email content
            subject = f"🚨 VPN Alert: {len(alerts)} issues detected"
            if critical_alerts:
                subject = f"🔴 CRITICAL VPN Alert: {len(critical_alerts)} critical issues"
            
            body = self._create_alert_email_body(critical_alerts, high_alerts, medium_alerts)
            
            # Send email
            msg = MIMEMultipart()
            msg['From'] = self.config["smtp_username"]
            msg['To'] = self.config["alert_email"]
            msg['Subject'] = subject
            
            msg.attach(MIMEText(body, 'html'))
            
            server = smtplib.SMTP(self.config["smtp_server"], self.config["smtp_port"])
            server.starttls()
            server.login(self.config["smtp_username"], self.config["smtp_password"])
            
            text = msg.as_string()
            server.sendmail(self.config["smtp_username"], self.config["alert_email"], text)
            server.quit()
            
            print(f"📧 Alert email sent with {len(alerts)} alerts")
            
        except Exception as e:
            print(f"❌ Failed to send alert email: {e}")
    
    def _create_alert_email_body(self, critical: List, high: List, medium: List) -> str:
        """Create HTML email body for alerts."""
        html = """
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; }
                .alert { margin: 10px 0; padding: 10px; border-radius: 5px; }
                .critical { background-color: #ffebee; border-left: 4px solid #f44336; }
                .high { background-color: #fff3e0; border-left: 4px solid #ff9800; }
                .medium { background-color: #f3e5f5; border-left: 4px solid #9c27b0; }
                .timestamp { color: #666; font-size: 0.9em; }
            </style>
        </head>
        <body>
            <h2>🏥 VPN Monitoring Alert Report</h2>
            <p><strong>Generated:</strong> {timestamp}</p>
        """.format(timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        
        if critical:
            html += "<h3>🔴 Critical Alerts</h3>"
            for alert in critical:
                html += f"""
                <div class="alert critical">
                    <strong>{alert['message']}</strong><br>
                    <span class="timestamp">Interface: {alert.get('interface', 'N/A')} | 
                    Time: {alert['timestamp']}</span>
                </div>
                """
        
        if high:
            html += "<h3>🟠 High Priority Alerts</h3>"
            for alert in high:
                html += f"""
                <div class="alert high">
                    <strong>{alert['message']}</strong><br>
                    <span class="timestamp">Interface: {alert.get('interface', 'N/A')} | 
                    Time: {alert['timestamp']}</span>
                </div>
                """
        
        if medium:
            html += "<h3>🟡 Medium Priority Alerts</h3>"
            for alert in medium:
                html += f"""
                <div class="alert medium">
                    <strong>{alert['message']}</strong><br>
                    <span class="timestamp">Interface: {alert.get('interface', 'N/A')} | 
                    Time: {alert['timestamp']}</span>
                </div>
                """
        
        html += """
            <hr>
            <p><em>This is an automated alert from your VPN monitoring system.</em></p>
        </body>
        </html>
        """
        
        return html
    
    def generate_usage_report(self, days: int = 7) -> Dict:
        """Generate usage analytics report."""
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        report = {
            "period": {
                "start": start_date.strftime("%Y-%m-%d"),
                "end": end_date.strftime("%Y-%m-%d"),
                "days": days
            },
            "interfaces": {},
            "summary": {}
        }
        
        # Load historical data
        metrics_data = []
        for day_offset in range(days):
            check_date = end_date - timedelta(days=day_offset)
            date_str = check_date.strftime("%Y-%m-%d")
            metrics_file = self.data_dir / f"metrics_{date_str}.jsonl"
            
            if metrics_file.exists():
                with open(metrics_file, 'r') as f:
                    for line in f:
                        try:
                            metrics_data.append(json.loads(line))
                        except json.JSONDecodeError:
                            continue
        
        if not metrics_data:
            report["summary"]["note"] = "No historical data available"
            return report
        
        # Analyze data
        total_samples = len(metrics_data)
        interface_stats = {}
        
        for metrics in metrics_data:
            for interface_name, interface_data in metrics.get("interfaces", {}).items():
                if interface_name not in interface_stats:
                    interface_stats[interface_name] = {
                        "uptime_samples": 0,
                        "total_samples": 0,
                        "peak_peers": 0,
                        "total_data_rx": 0,
                        "total_data_tx": 0,
                        "connection_events": []
                    }
                
                stats = interface_stats[interface_name]
                stats["total_samples"] += 1
                
                if interface_data.get("status") == "active":
                    stats["uptime_samples"] += 1
                    
                    peers = interface_data.get("peers", [])
                    stats["peak_peers"] = max(stats["peak_peers"], len(peers))
                    
                    stats["total_data_rx"] += interface_data.get("total_rx", 0)
                    stats["total_data_tx"] += interface_data.get("total_tx", 0)
        
        # Calculate final statistics
        for interface_name, stats in interface_stats.items():
            uptime_percent = (stats["uptime_samples"] / stats["total_samples"]) * 100 if stats["total_samples"] > 0 else 0
            
            report["interfaces"][interface_name] = {
                "uptime_percent": round(uptime_percent, 2),
                "peak_concurrent_peers": stats["peak_peers"],
                "total_data_transfer_gb": round((stats["total_data_rx"] + stats["total_data_tx"]) / (1024**3), 3),
                "data_rx_gb": round(stats["total_data_rx"] / (1024**3), 3),
                "data_tx_gb": round(stats["total_data_tx"] / (1024**3), 3)
            }
        
        # Overall summary
        all_uptimes = [stats["uptime_percent"] for stats in report["interfaces"].values()]
        total_data = sum(stats["total_data_transfer_gb"] for stats in report["interfaces"].values())
        
        report["summary"] = {
            "total_samples": total_samples,
            "average_uptime_percent": round(sum(all_uptimes) / len(all_uptimes), 2) if all_uptimes else 0,
            "total_data_transfer_gb": round(total_data, 3),
            "interfaces_monitored": len(interface_stats)
        }
        
        return report
    
    def run_monitoring_cycle(self):
        """Run one monitoring cycle."""
        print(f"🔍 Running monitoring cycle at {datetime.now().strftime('%H:%M:%S')}")
        
        # Collect metrics
        metrics = self.collect_metrics()
        
        # Store metrics
        self.store_metrics(metrics)
        
        # Check for alerts
        alerts = self.check_alerts(metrics)
        
        if alerts:
            print(f"⚠️  Found {len(alerts)} alerts")
            for alert in alerts:
                severity_icon = {"critical": "🔴", "high": "🟠", "medium": "🟡"}.get(alert["severity"], "⚪")
                print(f"   {severity_icon} {alert['message']}")
            
            # Send alert notifications
            if self.config.get("alerts_enabled", True):
                self.send_alert_email(alerts)
        else:
            print("✅ No alerts detected")
        
        # Print summary
        for interface_name, interface_data in metrics["interfaces"].items():
            if interface_data.get("status") == "active":
                peer_count = len(interface_data.get("peers", []))
                connected_count = len([p for p in interface_data.get("peers", []) if p.get("connected")])
                print(f"   📊 {interface_name}: {connected_count}/{peer_count} peers connected")
    
    def cleanup_old_data(self):
        """Clean up old monitoring data."""
        retention_days = self.config.get("data_retention_days", 90)
        cutoff_date = datetime.now() - timedelta(days=retention_days)
        
        cleaned = 0
        for metrics_file in self.data_dir.glob("metrics_*.jsonl"):
            try:
                # Extract date from filename
                date_str = metrics_file.stem.replace("metrics_", "")
                file_date = datetime.strptime(date_str, "%Y-%m-%d")
                
                if file_date < cutoff_date:
                    metrics_file.unlink()
                    cleaned += 1
            except (ValueError, OSError):
                continue
        
        if cleaned > 0:
            print(f"🧹 Cleaned up {cleaned} old monitoring files")


@click.group()
def monitor():
    """VPN monitoring and analytics commands."""
    pass


@monitor.command("setup")
@click.option("--email", prompt="Alert email address", help="Email for alerts")
@click.option("--smtp-user", prompt="SMTP username", help="SMTP authentication username")
@click.option("--smtp-pass", prompt="SMTP password", hide_input=True, help="SMTP authentication password")
def setup_monitoring(email: str, smtp_user: str, smtp_pass: str):
    """Configure VPN monitoring system."""
    monitor_system = VPNMonitor()
    
    monitor_system.config.update({
        "alert_email": email,
        "smtp_username": smtp_user,
        "smtp_password": smtp_pass,
        "alerts_enabled": True
    })
    
    monitor_system.save_config()
    
    click.echo("✅ Monitoring system configured successfully")
    click.echo(f"📧 Alerts will be sent to: {email}")
    click.echo("💡 Start monitoring with: python vpn.py monitor run")


@monitor.command("run")
@click.option("--daemon", is_flag=True, help="Run as background daemon")
@click.option("--interval", default=300, help="Check interval in seconds")
def run_monitoring(daemon: bool, interval: int):
    """Start VPN monitoring."""
    monitor_system = VPNMonitor()
    
    if not monitor_system.config.get("alert_email"):
        click.echo("❌ Monitoring not configured. Run: python vpn.py monitor setup")
        return
    
    if daemon:
        click.echo("🔄 Starting monitoring daemon...")
        try:
            while True:
                monitor_system.run_monitoring_cycle()
                time.sleep(interval)
        except KeyboardInterrupt:
            click.echo("\n🛑 Monitoring stopped")
    else:
        monitor_system.run_monitoring_cycle()


@monitor.command("report")
@click.option("--days", default=7, help="Number of days to include in report")
@click.option("--output", help="Output file for report")
def generate_report(days: int, output: Optional[str]):
    """Generate usage analytics report."""
    monitor_system = VPNMonitor()
    
    click.echo(f"📊 Generating {days}-day usage report...")
    report = monitor_system.generate_usage_report(days)
    
    if output:
        with open(output, 'w') as f:
            json.dump(report, f, indent=2)
        click.echo(f"📄 Report saved to: {output}")
    else:
        # Print summary to console
        click.echo("\n" + "="*50)
        click.echo(f"📈 VPN USAGE REPORT ({report['period']['start']} to {report['period']['end']})")
        click.echo("="*50)
        
        summary = report['summary']
        click.echo(f"📊 Total Samples: {summary['total_samples']}")
        click.echo(f"⏱️  Average Uptime: {summary['average_uptime_percent']}%")
        click.echo(f"📦 Total Data Transfer: {summary['total_data_transfer_gb']} GB")
        click.echo(f"🔌 Interfaces Monitored: {summary['interfaces_monitored']}")
        
        for interface_name, stats in report['interfaces'].items():
            click.echo(f"\n🔗 Interface: {interface_name}")
            click.echo(f"   ⏰ Uptime: {stats['uptime_percent']}%")
            click.echo(f"   👥 Peak Peers: {stats['peak_concurrent_peers']}")
            click.echo(f"   📊 Data Transfer: {stats['total_data_transfer_gb']} GB")


@monitor.command("status")
def monitoring_status():
    """Show current monitoring status."""
    monitor_system = VPNMonitor()
    
    click.echo("📊 VPN MONITORING STATUS")
    click.echo("="*30)
    
    # Show configuration
    if monitor_system.config.get("alert_email"):
        click.echo(f"📧 Alert Email: {monitor_system.config['alert_email']}")
        click.echo(f"⚡ Alerts Enabled: {'Yes' if monitor_system.config.get('alerts_enabled') else 'No'}")
        click.echo(f"⏱️  Check Interval: {monitor_system.config['check_interval']}s")
    else:
        click.echo("❌ Monitoring not configured")
        return
    
    # Show current metrics
    click.echo("\n📈 Current Status:")
    metrics = monitor_system.collect_metrics()
    
    for interface_name, interface_data in metrics["interfaces"].items():
        status_icon = "✅" if interface_data.get("status") == "active" else "❌"
        click.echo(f"   {status_icon} {interface_name}: {interface_data.get('status', 'unknown')}")
        
        if interface_data.get("status") == "active":
            peers = interface_data.get("peers", [])
            connected = len([p for p in peers if p.get("connected")])
            click.echo(f"      👥 Peers: {connected}/{len(peers)} connected")
            
            total_data = (interface_data.get("total_rx", 0) + interface_data.get("total_tx", 0)) / (1024**2)
            click.echo(f"      📊 Data: {total_data:.1f} MB total")


@monitor.command("cleanup")
def cleanup_data():
    """Clean up old monitoring data."""
    monitor_system = VPNMonitor()
    monitor_system.cleanup_old_data()
    click.echo("✅ Data cleanup completed")


if __name__ == "__main__":
    monitor()
