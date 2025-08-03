# VPN Deployment System Tests

import unittest
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))


class TestKeyGeneration(unittest.TestCase):
    """Test WireGuard key generation functionality."""
    
    def setUp(self):
        """Set up test environment."""
        self.test_dir = Path("/tmp/vpn_test")
        self.test_dir.mkdir(exist_ok=True)
    
    def test_import_key_manager(self):
        """Test that key manager can be imported."""
        try:
            from src.core.keys import WireGuardKeyManager
            self.assertTrue(True)
        except ImportError as e:
            self.fail(f"Cannot import WireGuardKeyManager: {e}")
    
    def test_import_client_config(self):
        """Test that client config generator can be imported."""
        try:
            from src.core.client_config import ClientConfigGenerator
            self.assertTrue(True)
        except ImportError as e:
            self.fail(f"Cannot import ClientConfigGenerator: {e}")


class TestWebApplication(unittest.TestCase):
    """Test web dashboard functionality."""
    
    def test_import_flask_app(self):
        """Test that Flask app can be imported."""
        try:
            from src.web.app import VPNDashboard
            self.assertTrue(True)
        except ImportError as e:
            self.fail(f"Cannot import VPNDashboard: {e}")


class TestUtilities(unittest.TestCase):
    """Test utility functions."""
    
    def test_import_testing_module(self):
        """Test that testing utilities can be imported."""
        try:
            from src.utils.testing import VPNTester
            self.assertTrue(True)
        except ImportError as e:
            self.fail(f"Cannot import VPNTester: {e}")


if __name__ == "__main__":
    unittest.main()
