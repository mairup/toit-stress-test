#!/usr/bin/env fish

# This script installs multiple independent containers onto the ESP32 via Jaguar.
# Each container runs in its own isolated memory space.

set CONTAINERS 1
if test (count $argv) -ge 1
    set CONTAINERS $argv[1]
end

echo "========================================================"
echo "Installing $CONTAINERS separate containers to the ESP32..."
echo "========================================================"

# Ensure we have a parameters.cfg
if not test -f parameters.cfg
    echo "DEFAULT_TASKS=5" > parameters.cfg
    echo "DEFAULT_INTENSITY=0.65" >> parameters.cfg
    echo "DEFAULT_DURATION_SECONDS=infinite" >> parameters.cfg
end

# Generate the config.toit so the containers compile correctly
echo "Translating parameters.cfg..."
echo "// Auto-generated" > config.toit
cat parameters.cfg | while read -l line
    if test -n "$line"; and not string match -q "#*" "$line"
        set parts (string split "=" $line)
        set key (string trim $parts[1])
        set value (string trim $parts[2])
        if test -n "$key"; and test -n "$value"
            echo "$key ::= $value" >> config.toit
        end
    end
end

for i in (seq 1 $CONTAINERS)
    set container_name "stress_worker_$i"
    echo ">>> Installing container: $container_name..."
    jag container install $container_name stress_tool.toit
end

# Clean up
rm config.toit

echo ""
echo "========================================================"
echo "Done! The ESP32 is now running $CONTAINERS separate isolated containers."
echo "You can check their status with: jag monitor"
echo "To uninstall them later, use: jag container uninstall stress_worker_1"
echo "========================================================"
