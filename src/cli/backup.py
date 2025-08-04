"""
Automated Backup and Disaster Recovery Module

Professional backup, restoration, and disaster recovery capabilities
for VPN infrastructure and client configurations.
"""

import json
import subprocess
import tarfile
import shutil
import hashlib
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import click
try:
    import boto3
    from botocore.exceptions import ClientError, NoCredentialsError
    S3_AVAILABLE = True
except ImportError:
    S3_AVAILABLE = False
    boto3 = None
    ClientError = Exception
    NoCredentialsError = Exception


class VPNBackupManager:
    """Professional VPN backup and disaster recovery system."""
    
    def __init__(self, config_file: str = "backup_config.json"):
        self.config_file = config_file
        self.config = self._load_config()
        self.backup_dir = Path(self.config.get("local_backup_dir", "vpn_backups"))
        self.backup_dir.mkdir(exist_ok=True)
    
    def _load_config(self) -> Dict:
        """Load backup configuration."""
        default_config = {
            "local_backup_dir": "vpn_backups",
            "retention_days": 30,
            "compress_backups": True,
            "encrypt_backups": False,
            "encryption_key": "",
            "s3_enabled": False,
            "s3_bucket": "",
            "s3_region": "us-east-1",
            "s3_access_key": "",
            "s3_secret_key": "",
            "backup_items": [
                "/etc/wireguard",
                "client_configs",
                "server_keys",
                "monitoring_data",
                "compliance_reports"
            ],
            "exclude_patterns": [
                "*.tmp",
                "*.log",
                "__pycache__",
                ".git"
            ]
        }
        
        try:
            if Path(self.config_file).exists():
                with open(self.config_file, 'r') as f:
                    loaded_config = json.load(f)
                    default_config.update(loaded_config)
        except Exception as e:
            click.echo(f"⚠️  Warning: Could not load backup config ({e}), using defaults")
        
        return default_config
    
    def save_config(self):
        """Save current configuration."""
        with open(self.config_file, 'w') as f:
            json.dump(self.config, f, indent=2)
    
    def create_backup(self, backup_name: Optional[str] = None) -> Dict:
        """Create comprehensive VPN backup."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_name = backup_name or f"vpn_backup_{timestamp}"
        
        backup_info = {
            "name": backup_name,
            "timestamp": datetime.now().isoformat(),
            "type": "full",
            "files": [],
            "size_bytes": 0,
            "checksum": "",
            "compressed": self.config.get("compress_backups", True),
            "encrypted": self.config.get("encrypt_backups", False)
        }
        
        try:
            # Create temporary backup directory
            temp_backup_dir = self.backup_dir / f"temp_{backup_name}"
            temp_backup_dir.mkdir(exist_ok=True)
            
            # Collect backup items
            for item in self.config["backup_items"]:
                self._backup_item(item, temp_backup_dir, backup_info)
            
            # Create backup archive
            if self.config.get("compress_backups", True):
                archive_path = self.backup_dir / f"{backup_name}.tar.gz"
                self._create_compressed_archive(temp_backup_dir, archive_path)
                backup_info["archive_path"] = str(archive_path)
                backup_info["size_bytes"] = archive_path.stat().st_size
            else:
                final_backup_dir = self.backup_dir / backup_name
                shutil.move(str(temp_backup_dir), str(final_backup_dir))
                backup_info["backup_path"] = str(final_backup_dir)
                backup_info["size_bytes"] = self._get_directory_size(final_backup_dir)
            
            # Calculate checksum
            if backup_info.get("archive_path"):
                backup_info["checksum"] = self._calculate_file_checksum(backup_info["archive_path"])
            
            # Clean up temp directory
            if temp_backup_dir.exists():
                shutil.rmtree(temp_backup_dir)
            
            # Save backup metadata
            self._save_backup_metadata(backup_info)
            
            # Upload to cloud if configured
            if self.config.get("s3_enabled", False):
                self._upload_to_s3(backup_info)
            
            return {
                "success": True,
                "backup_info": backup_info,
                "message": f"Backup created successfully: {backup_name}"
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "message": f"Backup failed: {str(e)}"
            }
    
    def _backup_item(self, item: str, backup_dir: Path, backup_info: Dict):
        """Backup individual item."""
        source_path = Path(item)
        
        # Handle different item types
        if source_path.is_absolute() and source_path.exists():
            # Absolute path - copy directly
            if source_path.is_file():
                dest_path = backup_dir / source_path.name
                shutil.copy2(source_path, dest_path)
                backup_info["files"].append(str(source_path))
            elif source_path.is_dir():
                dest_path = backup_dir / source_path.name
                shutil.copytree(source_path, dest_path, ignore=self._get_ignore_function())
                backup_info["files"].append(str(source_path))
        else:
            # Relative path - look in current directory
            current_dir_path = Path.cwd() / item
            if current_dir_path.exists():
                if current_dir_path.is_file():
                    dest_path = backup_dir / current_dir_path.name
                    shutil.copy2(current_dir_path, dest_path)
                    backup_info["files"].append(str(current_dir_path))
                elif current_dir_path.is_dir():
                    dest_path = backup_dir / current_dir_path.name
                    shutil.copytree(current_dir_path, dest_path, ignore=self._get_ignore_function())
                    backup_info["files"].append(str(current_dir_path))
        
        # Also backup system configuration if it's WireGuard related
        if item == "/etc/wireguard":
            self._backup_system_config(backup_dir, backup_info)
    
    def _backup_system_config(self, backup_dir: Path, backup_info: Dict):
        """Backup system configuration files."""
        system_config_dir = backup_dir / "system_config"
        system_config_dir.mkdir(exist_ok=True)
        
        # Backup systemd service files
        systemd_files = [
            "/etc/systemd/system/wg-quick@*.service",
            "/lib/systemd/system/wg-quick@.service"
        ]
        
        for pattern in systemd_files:
            try:
                result = subprocess.run(
                    ["find", "/", "-path", pattern, "-type", "f"],
                    capture_output=True, text=True
                )
                
                for file_path in result.stdout.strip().split('\n'):
                    if file_path and Path(file_path).exists():
                        dest_path = system_config_dir / Path(file_path).name
                        shutil.copy2(file_path, dest_path)
                        backup_info["files"].append(file_path)
            except Exception:
                continue
        
        # Backup firewall rules
        try:
            result = subprocess.run(["ufw", "status", "numbered"], capture_output=True, text=True)
            if result.returncode == 0:
                ufw_rules_file = system_config_dir / "ufw_rules.txt"
                ufw_rules_file.write_text(result.stdout)
                backup_info["files"].append("ufw_rules")
        except Exception:
            pass
        
        # Backup network configuration
        network_files = [
            "/etc/sysctl.conf",
            "/etc/iptables/rules.v4",
            "/etc/iptables/rules.v6"
        ]
        
        for file_path in network_files:
            if Path(file_path).exists():
                dest_path = system_config_dir / Path(file_path).name
                shutil.copy2(file_path, dest_path)
                backup_info["files"].append(file_path)
    
    def _get_ignore_function(self):
        """Get ignore function for shutil.copytree."""
        def ignore_patterns(dir_path, contents):
            ignored = []
            for pattern in self.config.get("exclude_patterns", []):
                import fnmatch
                ignored.extend(fnmatch.filter(contents, pattern))
            return ignored
        return ignore_patterns
    
    def _create_compressed_archive(self, source_dir: Path, archive_path: Path):
        """Create compressed tar archive."""
        with tarfile.open(archive_path, "w:gz") as tar:
            tar.add(source_dir, arcname=source_dir.name)
    
    def _get_directory_size(self, directory: Path) -> int:
        """Get total size of directory."""
        total_size = 0
        for dirpath, dirnames, filenames in directory.walk():
            for filename in filenames:
                file_path = dirpath / filename
                total_size += file_path.stat().st_size
        return total_size
    
    def _calculate_file_checksum(self, file_path: str) -> str:
        """Calculate SHA256 checksum of file."""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()
    
    def _save_backup_metadata(self, backup_info: Dict):
        """Save backup metadata."""
        metadata_file = self.backup_dir / f"{backup_info['name']}_metadata.json"
        with open(metadata_file, 'w') as f:
            json.dump(backup_info, f, indent=2)
    
    def _upload_to_s3(self, backup_info: Dict):
        """Upload backup to Amazon S3."""
        if not self.config.get("s3_enabled", False) or not S3_AVAILABLE:
            if not S3_AVAILABLE:
                click.echo("⚠️  S3 upload skipped: boto3 not installed")
            return
        
        try:
            s3_client = boto3.client(
                's3',
                region_name=self.config.get("s3_region", "us-east-1"),
                aws_access_key_id=self.config.get("s3_access_key"),
                aws_secret_access_key=self.config.get("s3_secret_key")
            )
            
            bucket = self.config.get("s3_bucket")
            if not bucket:
                raise ValueError("S3 bucket not configured")
            
            # Upload backup file
            if backup_info.get("archive_path"):
                file_path = backup_info["archive_path"]
                key = f"vpn_backups/{backup_info['name']}.tar.gz"
                
                s3_client.upload_file(file_path, bucket, key)
                backup_info["s3_location"] = f"s3://{bucket}/{key}"
            
            # Upload metadata
            metadata_key = f"vpn_backups/{backup_info['name']}_metadata.json"
            metadata_content = json.dumps(backup_info, indent=2)
            
            s3_client.put_object(
                Bucket=bucket,
                Key=metadata_key,
                Body=metadata_content.encode('utf-8'),
                ContentType='application/json'
            )
            
            click.echo(f"☁️  Backup uploaded to S3: {backup_info.get('s3_location')}")
            
        except (ClientError, NoCredentialsError) as e:
            click.echo(f"⚠️  S3 upload failed: {e}")
        except Exception as e:
            click.echo(f"⚠️  S3 upload error: {e}")
    
    def list_backups(self) -> List[Dict]:
        """List available backups."""
        backups = []
        
        # Local backups
        for metadata_file in self.backup_dir.glob("*_metadata.json"):
            try:
                with open(metadata_file, 'r') as f:
                    backup_info = json.load(f)
                    backup_info["location"] = "local"
                    backups.append(backup_info)
            except Exception:
                continue
        
        # Sort by timestamp (newest first)
        backups.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
        
        return backups
    
    def restore_backup(self, backup_name: str, restore_location: Optional[str] = None) -> Dict:
        """Restore from backup."""
        backups = self.list_backups()
        backup_info = None
        
        for backup in backups:
            if backup["name"] == backup_name:
                backup_info = backup
                break
        
        if not backup_info:
            return {
                "success": False,
                "message": f"Backup '{backup_name}' not found"
            }
        
        try:
            restore_location = restore_location or "restored_configs"
            restore_path = Path(restore_location)
            restore_path.mkdir(exist_ok=True)
            
            if backup_info.get("archive_path"):
                # Extract compressed backup
                archive_path = Path(backup_info["archive_path"])
                if archive_path.exists():
                    with tarfile.open(archive_path, "r:gz") as tar:
                        tar.extractall(restore_path)
            elif backup_info.get("backup_path"):
                # Copy uncompressed backup
                backup_path = Path(backup_info["backup_path"])
                if backup_path.exists():
                    shutil.copytree(backup_path, restore_path / backup_path.name)
            
            return {
                "success": True,
                "message": f"Backup restored to: {restore_path}",
                "restore_path": str(restore_path)
            }
            
        except Exception as e:
            return {
                "success": False,
                "message": f"Restore failed: {str(e)}"
            }
    
    def cleanup_old_backups(self):
        """Clean up old backups based on retention policy."""
        retention_days = self.config.get("retention_days", 30)
        cutoff_date = datetime.now() - timedelta(days=retention_days)
        
        backups = self.list_backups()
        cleaned_count = 0
        
        for backup in backups:
            try:
                backup_date = datetime.fromisoformat(backup["timestamp"])
                if backup_date < cutoff_date:
                    # Remove backup files
                    if backup.get("archive_path"):
                        Path(backup["archive_path"]).unlink(missing_ok=True)
                    if backup.get("backup_path"):
                        shutil.rmtree(backup["backup_path"], ignore_errors=True)
                    
                    # Remove metadata
                    metadata_file = self.backup_dir / f"{backup['name']}_metadata.json"
                    metadata_file.unlink(missing_ok=True)
                    
                    cleaned_count += 1
            except Exception:
                continue
        
        return cleaned_count
    
    def verify_backup(self, backup_name: str) -> Dict:
        """Verify backup integrity."""
        backups = self.list_backups()
        backup_info = None
        
        for backup in backups:
            if backup["name"] == backup_name:
                backup_info = backup
                break
        
        if not backup_info:
            return {
                "success": False,
                "message": f"Backup '{backup_name}' not found"
            }
        
        try:
            verification_results = {
                "files_exist": False,
                "checksum_valid": False,
                "archive_readable": False,
                "size_matches": False
            }
            
            # Check if backup files exist
            if backup_info.get("archive_path"):
                archive_path = Path(backup_info["archive_path"])
                verification_results["files_exist"] = archive_path.exists()
                
                if archive_path.exists():
                    # Verify checksum
                    current_checksum = self._calculate_file_checksum(str(archive_path))
                    stored_checksum = backup_info.get("checksum", "")
                    verification_results["checksum_valid"] = current_checksum == stored_checksum
                    
                    # Check if archive is readable
                    try:
                        with tarfile.open(archive_path, "r:gz") as tar:
                            tar.getnames()
                        verification_results["archive_readable"] = True
                    except Exception:
                        verification_results["archive_readable"] = False
                    
                    # Check size
                    current_size = archive_path.stat().st_size
                    stored_size = backup_info.get("size_bytes", 0)
                    verification_results["size_matches"] = current_size == stored_size
            
            all_checks_passed = all(verification_results.values())
            
            return {
                "success": all_checks_passed,
                "verification_results": verification_results,
                "message": "Backup verification passed" if all_checks_passed else "Backup verification failed"
            }
            
        except Exception as e:
            return {
                "success": False,
                "message": f"Verification failed: {str(e)}"
            }


@click.group()
def backup():
    """VPN backup and disaster recovery commands."""
    pass


@backup.command("create")
@click.option("--name", help="Custom backup name")
@click.option("--description", help="Backup description")
def create_backup(name: Optional[str], description: Optional[str]):
    """Create a new VPN backup."""
    manager = VPNBackupManager()
    
    click.echo("💾 Creating VPN backup...")
    
    result = manager.create_backup(name)
    
    if result["success"]:
        backup_info = result["backup_info"]
        size_mb = backup_info["size_bytes"] / (1024 * 1024)
        
        click.echo(f"✅ {result['message']}")
        click.echo(f"📦 Size: {size_mb:.1f} MB")
        click.echo(f"📁 Files: {len(backup_info['files'])} items backed up")
        click.echo(f"🔐 Checksum: {backup_info['checksum'][:16]}...")
        
        if backup_info.get("s3_location"):
            click.echo(f"☁️  Cloud Location: {backup_info['s3_location']}")
    else:
        click.echo(f"❌ {result['message']}")


@backup.command("list")
@click.option("--detailed", is_flag=True, help="Show detailed backup information")
def list_backups(detailed: bool):
    """List available backups."""
    manager = VPNBackupManager()
    backups = manager.list_backups()
    
    if not backups:
        click.echo("📦 No backups found")
        return
    
    click.echo(f"📦 Found {len(backups)} backups:")
    click.echo()
    
    for backup in backups:
        timestamp = datetime.fromisoformat(backup["timestamp"])
        size_mb = backup.get("size_bytes", 0) / (1024 * 1024)
        
        click.echo(f"🗂️  {backup['name']}")
        click.echo(f"   📅 Created: {timestamp.strftime('%Y-%m-%d %H:%M:%S')}")
        click.echo(f"   📦 Size: {size_mb:.1f} MB")
        click.echo(f"   📁 Files: {len(backup.get('files', []))} items")
        
        if detailed:
            click.echo(f"   🔐 Checksum: {backup.get('checksum', 'N/A')[:16]}...")
            click.echo(f"   📍 Location: {backup.get('location', 'local')}")
            if backup.get("s3_location"):
                click.echo(f"   ☁️  S3: {backup['s3_location']}")
        
        click.echo()


@backup.command("restore")
@click.argument("backup_name")
@click.option("--location", help="Restore location (default: restored_configs)")
def restore_backup(backup_name: str, location: Optional[str]):
    """Restore from backup."""
    manager = VPNBackupManager()
    
    click.echo(f"🔄 Restoring backup: {backup_name}")
    
    result = manager.restore_backup(backup_name, location)
    
    if result["success"]:
        click.echo(f"✅ {result['message']}")
        click.echo(f"📁 Restored to: {result['restore_path']}")
    else:
        click.echo(f"❌ {result['message']}")


@backup.command("verify")
@click.argument("backup_name")
def verify_backup(backup_name: str):
    """Verify backup integrity."""
    manager = VPNBackupManager()
    
    click.echo(f"🔍 Verifying backup: {backup_name}")
    
    result = manager.verify_backup(backup_name)
    
    if result["success"]:
        click.echo("✅ Backup verification passed")
    else:
        click.echo(f"❌ {result['message']}")
    
    # Show detailed verification results
    if "verification_results" in result:
        click.echo("\n📊 Verification Details:")
        for check, passed in result["verification_results"].items():
            status = "✅" if passed else "❌"
            click.echo(f"   {status} {check.replace('_', ' ').title()}")


@backup.command("cleanup")
@click.option("--dry-run", is_flag=True, help="Show what would be cleaned up without doing it")
def cleanup_backups(dry_run: bool):
    """Clean up old backups."""
    manager = VPNBackupManager()
    
    if dry_run:
        click.echo("🧹 Dry run - showing what would be cleaned up:")
        # This would need additional logic to show what would be cleaned
        click.echo("   (Dry run functionality not implemented yet)")
    else:
        click.echo("🧹 Cleaning up old backups...")
        cleaned_count = manager.cleanup_old_backups()
        
        if cleaned_count > 0:
            click.echo(f"✅ Cleaned up {cleaned_count} old backups")
        else:
            click.echo("📦 No old backups to clean up")


@backup.command("configure")
@click.option("--s3-bucket", help="S3 bucket name for cloud backups")
@click.option("--s3-region", default="us-east-1", help="S3 region")
@click.option("--retention-days", type=int, default=30, help="Backup retention period")
def configure_backup(s3_bucket: Optional[str], s3_region: str, retention_days: int):
    """Configure backup settings."""
    manager = VPNBackupManager()
    
    if s3_bucket:
        manager.config["s3_enabled"] = True
        manager.config["s3_bucket"] = s3_bucket
        manager.config["s3_region"] = s3_region
        click.echo(f"☁️  Configured S3 backups to: {s3_bucket}")
    
    manager.config["retention_days"] = retention_days
    manager.save_config()
    
    click.echo(f"⚙️  Backup retention set to: {retention_days} days")
    click.echo("✅ Backup configuration saved")


if __name__ == "__main__":
    backup()
