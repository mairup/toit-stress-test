#!/usr/bin/env fish

# A declarative test suite to gradually increase stress on the ESP32 via Jaguar.

echo "========================================================"
echo "Starting ESP32 Gradual Stress Test Suite"
echo "Make sure your ESP32 is powered on and Jaguar is ready."
echo "========================================================"

function run_test
    set tasks $argv[1]
    set intensity $argv[2]
    set duration $argv[3]
    set desc $argv[4]

    echo ""
    echo ">>> [TEST] $desc"
    echo ">>> [CONF] Tasks: $tasks | Intensity: $intensity | Duration: $duration"
    
    # Overwrite parameters.cfg for this specific test
    echo "DEFAULT_TASKS=$tasks" > parameters.cfg
    echo "DEFAULT_INTENSITY=$intensity" >> parameters.cfg
    echo "DEFAULT_DURATION_SECONDS=$duration" >> parameters.cfg

    # Execute via our unified runner targeting Jaguar
    ./stress_tool.sh --jag

    # Give the ESP32 a moment to cool down and collect garbage before the next run
    echo ">>> Cooldown: waiting 5 seconds..."
    sleep 5
end

# ---------------------------------------------------------
# DECLARATIVE TEST LIST
# ---------------------------------------------------------

# Test 1: Light Warmup
# Very low load to ensure basic functionality without memory pressure.
run_test 2 0.20 15 "Light Warmup"

# Test 2: Standard Operations
# The default configuration, checking standard scheduling behavior.
run_test 5 0.65 30 "Standard Operations"

# Test 3: High Contention
# High number of tasks to test the cooperative scheduler's context switching.
run_test 15 0.65 30 "High Task Contention"

# Test 4: CPU Bound Pressure
# Maximum intensity (no sleep) but a reasonable number of tasks.
run_test 5 1.00 45 "CPU Bound Maximum Pressure"

# Test 5: The Gauntlet
# High task count and maximum intensity. Tests both memory limits and CPU limits.
run_test 20 1.00 60 "The Gauntlet"

# ---------------------------------------------------------

echo ""
echo "========================================================"
echo "Test suite execution finished!"
echo "========================================================"
