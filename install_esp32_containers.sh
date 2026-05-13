#!/bin/bash

# This script installs multiple independent containers onto the ESP32 via Jaguar.
# Each container runs in its own isolated memory space.

CONTAINERS=1
if [ $# -ge 1 ]; then
    CONTAINERS=$1
fi

echo "========================================================"
echo "Installing $CONTAINERS separate containers to the ESP32..."
echo "========================================================"

# Ensure we have a parameters.cfg
if [ ! -f parameters.cfg ]; then
    cat > parameters.cfg <<EOF
DEFAULT_TASKS=5
DEFAULT_INTENSITY=0.65
DURATION=0
EOF
fi

# Generate the config.toit so the containers compile correctly
echo "Translating parameters.cfg..."
echo "// Auto-generated" > config.toit
while IFS='=' read -r key value; do
    # Skip empty lines or comments
    if [[ -z "$key" || "$key" == \#* ]]; then continue; fi
    
    # Trim whitespace
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    
    if [[ -n "$key" && -n "$value" ]]; then
        echo "${key} ::= ${value}" >> config.toit
    fi
done < parameters.cfg

for ((i=1; i<=CONTAINERS; i++)); do
    container_name="stress_worker_$i"
    echo ">>> Installing container: $container_name..."
    jag container install "$container_name" stress_tool.toit
done

# Clean up
rm config.toit

echo ""
echo "========================================================"
echo "Done! The ESP32 is now running $CONTAINERS separate isolated containers."
echo "You can check their status with: jag monitor"
echo "To uninstall them later, use: jag container uninstall stress_worker_1"
echo "========================================================"
