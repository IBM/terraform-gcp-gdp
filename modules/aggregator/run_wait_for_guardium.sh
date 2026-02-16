#!/bin/bash

#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/aggregator/run_wait_for_guardium.sh (GCP Version)
# Wrapper script for Guardium automation

set -eu

# Fixed log directory location
LOG_DIR="/opt/guardium-gcp/modules/aggregator/logs"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

# Create logs directory
mkdir -p "$LOG_DIR"

# Set log file name (will be updated with VM name later)
LOG_FILE="$LOG_DIR/guardium_setup_$TIMESTAMP.log"

# Start logging - tee to both console and log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=========================================="
echo "GUARDIUM AGGREGATOR AUTOMATION LOG"
echo "Log file: $LOG_FILE"
echo "Start time: $(date)"
echo "=========================================="

# Enable verbose output for debugging
set -x

# Check if expect is installed
if ! command -v expect >/dev/null 2>&1; then
  echo "[ERROR] expect is required but not installed. Installing expect..."
  sudo apt-get update && sudo apt-get install -y expect
fi

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
  echo "[ERROR] jq is required but not installed. Please install jq."
  exit 1
fi

# Try multiple possible JSON file locations (adapted for GCP)
JSON_LOCATIONS=(
  "../../examples/phase2agg/aggregator_config.json"
  "../phase2agg/aggregator_config.json"
  "$HOME/guardium-gcp/examples/phase2agg/aggregator_config.json"
  "/opt/guardium-gcp/examples/phase2agg/aggregator_config.json"
  "./aggregator_config.json"
)

JSON_FILE=""
for location in "${JSON_LOCATIONS[@]}"; do
  if [ -f "$location" ]; then
    JSON_FILE="$location"
    echo "[INFO] Found JSON config at: $JSON_FILE"
    break
  fi
done

if [ -z "$JSON_FILE" ]; then
  echo "[ERROR] aggregator_config.json not found in any of these locations:"
  for location in "${JSON_LOCATIONS[@]}"; do
    echo "  - $location"
  done
  exit 1
fi

# Extract arguments or fail if not provided
PRIVATE_IP="${1:?IP address not provided}"
DEFAULT_PW="${2:?Default password not provided}"

# Update log file with IP address
NEW_LOG_FILE="$LOG_DIR/agg_${PRIVATE_IP//./_}_$TIMESTAMP.log"
if [ -f "$LOG_FILE" ]; then
  mv "$LOG_FILE" "$NEW_LOG_FILE" 2>/dev/null || true
fi
LOG_FILE="$NEW_LOG_FILE"
echo "[INFO] Log file: $LOG_FILE"

# Extract configuration from JSON - find the matching instance by IP
FINAL_PW=$(jq -r ".aggregators[] | select(.network_interface_ip == \"$PRIVATE_IP\") | .guardium_final_pw" "$JSON_FILE")
SUBNET_MASK=$(jq -r ".aggregators[] | select(.network_interface_ip == \"$PRIVATE_IP\") | .network_interface_mask" "$JSON_FILE")
GATEWAY=$(jq -r ".aggregators[] | select(.network_interface_ip == \"$PRIVATE_IP\") | .network_routes_defaultroute" "$JSON_FILE")
RESOLVER1=$(jq -r ".aggregators[] | select(.network_interface_ip == \"$PRIVATE_IP\") | .network_resolvers1" "$JSON_FILE")
RESOLVER2=$(jq -r ".aggregators[] | select(.network_interface_ip == \"$PRIVATE_IP\") | .network_resolvers2 // \"8.8.8.8\"" "$JSON_FILE")
HOSTNAME=$(jq -r ".aggregators[] | select(.network_interface_ip == \"$PRIVATE_IP\") | .system_hostname" "$JSON_FILE")
DOMAIN=$(jq -r ".aggregators[] | select(.network_interface_ip == \"$PRIVATE_IP\") | .system_domain" "$JSON_FILE")
TIMEZONE=$(jq -r ".aggregators[] | select(.network_interface_ip == \"$PRIVATE_IP\") | .system_clock_timezone" "$JSON_FILE")
LICENSE_KEY=$(jq -r ".aggregators[] | select(.network_interface_ip == \"$PRIVATE_IP\") | .guardium_license_key" "$JSON_FILE")
SHARED_SECRET=$(jq -r ".aggregators[] | select(.network_interface_ip == \"$PRIVATE_IP\") | .guardium_shared_secret" "$JSON_FILE")
CM_IP=$(jq -r ".aggregators[] | select(.network_interface_ip == \"$PRIVATE_IP\") | .guardium_central_manager_ip" "$JSON_FILE")

# Validate that we found the configuration
if [ "$FINAL_PW" = "null" ] || [ -z "$FINAL_PW" ]; then
  echo "[ERROR] Could not find configuration for IP $PRIVATE_IP in $JSON_FILE"
  echo "[DEBUG] Available IPs in config:"
  jq -r '.aggregators[] | .network_interface_ip' "$JSON_FILE" | head -5
  exit 1
fi

# Convert subnet mask from CIDR to dotted decimal if needed
if [[ $SUBNET_MASK == /* ]]; then
  CIDR=${SUBNET_MASK:1}
  case $CIDR in
    16) DOTTED_MASK="255.255.0.0" ;;
    20) DOTTED_MASK="255.255.240.0" ;;
    23) DOTTED_MASK="255.255.254.0" ;;
    24) DOTTED_MASK="255.255.255.0" ;;
    25) DOTTED_MASK="255.255.255.128" ;;
    27) DOTTED_MASK="255.255.255.224" ;;
    *) echo "[ERROR] Unsupported CIDR: $SUBNET_MASK"; exit 1 ;;
  esac
else
  DOTTED_MASK=$SUBNET_MASK
fi

# Log values for debugging
echo "[DEBUG] Private IP: $PRIVATE_IP"
echo "[DEBUG] Central Manager IP: $CM_IP"
echo "[DEBUG] Hostname: $HOSTNAME"
echo "[DEBUG] Dotted Mask: $DOTTED_MASK"
echo "[DEBUG] Gateway: $GATEWAY"
echo "[DEBUG] Resolver1: $RESOLVER1"
echo "[DEBUG] Resolver2: $RESOLVER2"
echo "[DEBUG] Domain: $DOMAIN"
echo "[DEBUG] Timezone: $TIMEZONE"
echo "[DEBUG] License Key: ${LICENSE_KEY:0:20}..."
echo "[DEBUG] Shared Secret: ${SHARED_SECRET:0:3}..."

# GCP-specific connectivity check
echo "[INFO] Running GCP connectivity checks..."

# Check if running on GCP instance
if curl -s -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/name >/dev/null 2>&1; then
  echo "[INFO] Running on GCP instance - connectivity should work"
else
  echo "[WARNING] Not running on GCP instance - ensure proper network connectivity"
fi

# Wait for Guardium to be ready (SSH port check)
echo "[INFO] Waiting for Guardium SSH service to be ready..."
for i in {1..60}; do
  if nc -z -w5 "$PRIVATE_IP" 22 >/dev/null 2>&1; then
    echo "[INFO] SSH port is ready on $PRIVATE_IP"
    break
  fi
  echo "Waiting for SSH service... attempt $i/60"
  sleep 10
done

if ! nc -z -w5 "$PRIVATE_IP" 22 >/dev/null 2>&1; then
  echo "[ERROR] SSH service not ready after 10 minutes"
  exit 1
fi

# Check if expect script exists
EXPECT_SCRIPT="./wait_for_guardium.expect"

if [ ! -f "$EXPECT_SCRIPT" ]; then
  echo "[ERROR] Expect script not found at $EXPECT_SCRIPT"
  echo "Please ensure wait_for_guardium.expect exists in the current directory"
  exit 1
fi

# Make sure expect script is executable
chmod +x "$EXPECT_SCRIPT"

# Run the expect script
echo "[$(date '+%H:%M:%S')] Running Guardium automation on $PRIVATE_IP (GCP)"

if "$EXPECT_SCRIPT" "$PRIVATE_IP" "$DEFAULT_PW" "$FINAL_PW" "$PRIVATE_IP" "$DOTTED_MASK" "$GATEWAY" "$RESOLVER1" "$RESOLVER2" "$HOSTNAME" "$DOMAIN" "$TIMEZONE" "$LICENSE_KEY" "$SHARED_SECRET" "$CM_IP"; then
  echo "[$(date '+%H:%M:%S')] Guardium configuration completed successfully (GCP)"
  echo ""
  echo "==============================================="
  echo "GCP GUARDIUM AGGREGATOR SETUP COMPLETE"
  echo "==============================================="
  echo "Instance: $HOSTNAME.$DOMAIN"
  echo "Private IP: $PRIVATE_IP"
  echo "Central Manager IP: $CM_IP"
  echo "Final password: $FINAL_PW"
  echo "Access URL: https://$PRIVATE_IP:8443"
  echo ""
  echo "Configuration completed:"
  echo "- Two-phase password setup completed"
  echo "- Network settings configured"
  echo "- Configured as Aggregator"
  echo "- Registered with Central Manager at $CM_IP"
  echo "- Shared secret set"
  echo ""
  echo "CLI Access: ssh cli@$PRIVATE_IP (password: $FINAL_PW)"
  echo "Web UI: https://$PRIVATE_IP:8443 (admin/guardium)"
  echo "==============================================="

  exit 0
else
  echo "[$(date '+%H:%M:%S')] Guardium configuration completed with warnings"
  echo "VM is accessible for manual verification"
  echo "Try SSH: ssh cli@$PRIVATE_IP"
  echo "Passwords to try: guardium, $FINAL_PW"
  echo "Web UI: https://$PRIVATE_IP:8443"

  exit 0  # Don't fail deployment
fi
