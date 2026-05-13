#!/bin/bash

# A declarative test suite to gradually increase stress.
# Run locally on the PC by spawning multiple isolated Toit VM processes.

CONTAINERS=1
if [ $# -ge 1 ]; then
    CONTAINERS=$1
fi

echo "========================================================"
echo "Starting Gradual Stress Test Suite (Local PC)"
echo "Spawning $CONTAINERS concurrent OS processes per test"
echo "========================================================"

cleanup() {
    echo -e "\n[!] Caught Ctrl+C. Forcefully terminating all background workers..."
    # 1. Kill all background jobs known to this shell
    # We use pkill -P to kill children of the current script's PID
    pkill -9 -P $$ 2>/dev/null
    # 2. Kill any remaining stress_tool processes to be safe
    pkill -9 -f "stress_tool.toit" 2>/dev/null
    pkill -9 -f "stress_tool.sh" 2>/dev/null
    exit 1
}
trap cleanup SIGINT SIGTERM

run_test() {
    local tasks=$1
    local intensity=$2
    local duration=$3
    local desc=$4

    echo ""
    echo ">>> [TEST] $desc"
    echo ">>> [CONF] Tasks/Process: $tasks | Intensity: $intensity | Duration: $duration"
    
    # Overwrite parameters.cfg for this specific test
    cat > parameters.cfg <<EOF
DEFAULT_TASKS=$tasks
DEFAULT_INTENSITY=$intensity
DURATION=$duration
EOF

    # Spawn N processes in the background
    for ((i=1; i<=CONTAINERS; i++)); do
        if [ $i -eq 1 ]; then
            # The first process is the designated reporter
            ./stress_tool.sh --toit -- --print &
        else
            # All subsequent processes are silent by default
            ./stress_tool.sh --toit &
        end
    done

    # Wait for all background processes to finish
    wait

    echo ">>> Cooldown: waiting 2 seconds..."
    sleep 2
}

# ---------------------------------------------------------
# DECLARATIVE TEST LIST
# ---------------------------------------------------------

run_test 2 0.20 10 "Light Warmup"
run_test 5 0.60 20 "Standard Operations"
run_test 10 0.60 20 "High Task Contention"
run_test 5 1.00 30 "CPU Bound Maximum Pressure"
run_test 20 1.00 40 "The Gauntlet"

echo ""
echo "========================================================"
echo "Test suite execution finished!"
echo "========================================================"
