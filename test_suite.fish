#!/usr/bin/env fish

# A declarative test suite to gradually increase stress.
# Run locally on the PC by spawning multiple isolated Toit VM processes.

set CONTAINERS 1
if test (count $argv) -ge 1
    set CONTAINERS $argv[1]
end

echo "========================================================"
echo "Starting Gradual Stress Test Suite (Local PC)"
echo "Spawning $CONTAINERS concurrent OS processes per test"
echo "========================================================"

function cleanup_on_exit --on-signal SIGINT
    echo -e "\n[!] Caught Ctrl+C. Forcefully terminating all background workers..."
    # 1. Kill all background jobs known to this shell
    kill (jobs -p) 2>/dev/null
    # 2. Kill any remaining stress_tool processes to be safe
    pkill -9 -f "toit run stress_tool.toit" 2>/dev/null
    pkill -9 -f "stress_tool.sh" 2>/dev/null
    exit 1
end

function run_test
    set tasks $argv[1]
    set intensity $argv[2]
    set duration $argv[3]
    set desc $argv[4]

    echo ""
    echo ">>> [TEST] $desc"
    echo ">>> [CONF] Tasks/Process: $tasks | Intensity: $intensity | Duration: $duration"
    
    # Overwrite parameters.cfg for this specific test
    echo "DEFAULT_TASKS=$tasks" > parameters.cfg
    echo "DEFAULT_INTENSITY=$intensity" >> parameters.cfg
    echo "DEFAULT_DURATION_SECONDS=$duration" >> parameters.cfg

    # Spawn N processes in the background
    for i in (seq 1 $CONTAINERS)
        if test $i -eq 1
            # The first process is allowed to print
            ./stress_tool.sh --toit &
        else
            # All subsequent processes run in silent mode
            ./stress_tool.sh --toit --silent &
        end
    end

    # Wait for all background processes to finish
    wait

    echo ">>> Cooldown: waiting 2 seconds..."
    sleep 2
end

# ---------------------------------------------------------
# DECLARATIVE TEST LIST
# ---------------------------------------------------------

run_test 2 0.20 15 "Light Warmup"
run_test 5 0.65 30 "Standard Operations"
run_test 15 0.65 30 "High Task Contention"
run_test 5 1.00 45 "CPU Bound Maximum Pressure"
run_test 20 1.00 60 "The Gauntlet"

echo ""
echo "========================================================"
echo "Test suite execution finished!"
echo "========================================================"
