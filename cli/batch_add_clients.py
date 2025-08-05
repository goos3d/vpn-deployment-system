#!/usr/bin/env python3
"""
batch_add_clients.py - Add multiple VPN clients from a list

Usage: python cli/batch_add_clients.py client_list.txt

Creates a client for each name in the text file (one name per line).
"""

import sys
import os
from pathlib import Path

# Add src to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from cli.add_client import SimpleClientGenerator


def main():
    """Add multiple clients from a text file."""
    if len(sys.argv) != 2:
        print("Usage: python cli/batch_add_clients.py client_list.txt")
        print("\nExample client_list.txt:")
        print("john_doe")
        print("patient_smith") 
        print("office_laptop")
        sys.exit(1)
    
    client_list_file = sys.argv[1]
    
    if not Path(client_list_file).exists():
        print(f"Error: File '{client_list_file}' not found")
        sys.exit(1)
    
    # Read client names
    with open(client_list_file, 'r', encoding='utf-8') as f:
        client_names = [line.strip() for line in f if line.strip()]
    
    if not client_names:
        print("Error: No client names found in file")
        sys.exit(1)
    
    print(f"Found {len(client_names)} clients to create:")
    for name in client_names:
        print(f"  - {name}")
    
    # Confirm before proceeding
    response = input(f"\nCreate {len(client_names)} VPN clients? (y/N): ")
    if response.lower() != 'y':
        print("Cancelled")
        sys.exit(0)
    
    # Generate clients
    generator = SimpleClientGenerator()
    success_count = 0
    failed_clients = []
    
    for client_name in client_names:
        try:
            print(f"\n{'='*50}")
            result = generator.add_client(client_name)
            success_count += 1
        except Exception as e:
            print(f"❌ Failed to create client '{client_name}': {e}")
            failed_clients.append(client_name)
    
    # Summary
    print(f"\n{'='*50}")
    print("BATCH GENERATION COMPLETE")
    print(f"{'='*50}")
    print(f"✅ Successfully created: {success_count} clients")
    
    if failed_clients:
        print(f"❌ Failed to create: {len(failed_clients)} clients")
        print("Failed clients:")
        for name in failed_clients:
            print(f"  - {name}")
    
    print(f"\nAll client files saved in: clients/")
    print("Ready for email delivery!")


if __name__ == '__main__':
    main()
