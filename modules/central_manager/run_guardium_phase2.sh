#!/bin/bash

#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/central_manager/run_guardium_phase2.sh (GCP Version)
# Wrapper script for Guardium Phase 2 configuration

set -euo pipefail

# Check arguments
if [ $# -ne 3 ]; then
    echo "Usage: $0 <IP> <final_password> <shared_secret>"
    echo "Example: $0 10.0.0.10 'MyCliSecurePassword123!' 'MySharedSecret123'"
    echo "Note: Add single quotation marks around complex passwords"
    exit 1
fi

IP="$1"
FINAL_PASSWORD="$2"
SHARED_SECRET="$3"

echo "=========================================="
echo "GUARDIUM PHASE 2 CONFIGURATION (GCP)"
echo "IP: $IP"
echo "Time: $(date)"
echo "=========================================="

# Check if expect script exists (adapted for GCP paths)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPECT_SCRIPT="$SCRIPT_DIR/wait_for_guardium_phase2.expect"

# Try multiple locations for expect script
EXPECT_LOCATIONS=(
  "$SCRIPT_DIR/wait_for_guardium_phase2.expect"
  "$HOME/guardium-gcp/modules/central_manager/wait_for_guardium_phase2.expect"
  "/opt/guardium-gcp/modules/central_manager/wait_for_guardium_phase2.expect"
)

EXPECT_SCRIPT=""
for location in "${EXPECT_LOCATIONS[@]}"; do
  if [ -f "$location" ]; then
    EXPECT_SCRIPT="$location"
    echo "Found expect script at: $EXPECT_SCRIPT"
    break
  fi
done

if [ -z "$EXPECT_SCRIPT" ]; then
    echo "Error: Expect script not found in any of these locations:"
    for location in "${EXPECT_LOCATIONS[@]}"; do
      echo "  - $location"
    done
    exit 1
fi

# Make sure expect script is executable
chmod +x "$EXPECT_SCRIPT"

# Test connectivity first
echo "Testing connectivity to $IP:22..."
if ! nc -z -w10 "$IP" 22 >/dev/null 2>&1; then
    echo "Error: Cannot reach $IP on port 22"
    echo "Ensure you're running this from the bastion host"
    exit 1
fi

echo "Connection test passed. Starting Phase 2 configuration..."

# Run the expect script
if "$EXPECT_SCRIPT" "$IP" "$FINAL_PASSWORD" "$SHARED_SECRET"; then
    echo "=========================================="
    echo "Phase 2 configuration completed successfully!"
    echo "Guardium Central Manager is now fully configured."
    echo "Ready for Phase 2 (Aggregators) deployment."
    echo "=========================================="
    exit 0
else
    echo "=========================================="
    echo "Phase 2 configuration failed!"
    echo "Please check the logs and try again."
    echo "Manual steps:"
    echo "  ssh cli@$IP"
    echo "  store unit type manager"
    echo "  store system shared secret $SHARED_SECRET"
    echo "=========================================="
    exit 1
fi

