# File: services/phl-products/tests/zap/zap-baseline.py

import time
import sys
import os
from zapv2 import ZAPv2

# Configuration
ZAP_PROXY = 'http://localhost:8080'  # ZAP Docker container proxy
TARGET = os.getenv('BASE_URL')        # Base URL of the API to scan
BEARER_TOKEN = os.getenv('BEARER_TOKEN')  # Bearer Token for authentication
REPORT_PATH = 'zap-report.html'       # Path to save the ZAP HTML report

# Initialize ZAP API client
zap = ZAPv2(proxies={'http': ZAP_PROXY, 'https': ZAP_PROXY})

def load_zap_script(script_path):
    """
    Loads a ZAP script that injects the Authorization header.
    """
    print(f"Loading ZAP script from {script_path}")
    with open(script_path, 'r') as script_file:
        script_content = script_file.read()
    
    # Create the script in ZAP
    script_id = zap.script.load(
        script_name='AddAuthHeader',
        script_type='proxy',
        engine='jsscript',
        script_file=script_content
    )
    print(f"Script loaded with ID: {script_id}")

def run_baseline_scan():
    """
    Initiates the baseline scan using ZAP's Active Scan.
    """
    print(f"Starting ZAP baseline scan on {TARGET}")
    scan_id = zap.ascan.scan(url=TARGET)
    
    while int(zap.ascan.status(scan_id)) < 100:
        print(f"Scan progress: {zap.ascan.status(scan_id)}%")
        time.sleep(5)
    
    print("Scan completed.")

def generate_report():
    """
    Generates an HTML report of the ZAP scan.
    """
    print("Generating ZAP HTML report...")
    with open(REPORT_PATH, 'w') as report_file:
        report_file.write(zap.core.htmlreport())
    print(f"ZAP report generated at {REPORT_PATH}")

def main():
    # Validate environment variables
    if not TARGET:
        print("Error: BASE_URL environment variable is not set.")
        sys.exit(1)
    if not BEARER_TOKEN:
        print("Error: BEARER_TOKEN environment variable is not set.")
        sys.exit(1)
    
    # Path to the ZAP script that adds the Authorization header
    script_path = 'services/phl-products/tests/zap/add_auth_header.js'
    
    try:
        # Load the Authorization header script into ZAP
        load_zap_script(script_path)
        
        # Run the baseline scan
        run_baseline_scan()
        
        # Generate the HTML report
        generate_report()
        
    except Exception as e:
        print(f"Error during ZAP scan: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
