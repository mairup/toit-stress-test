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
    echo -e "\n[!] Caught Ctrl+C. Killing all background processes..."
    # pkill -P %self kills all direct children of the current shell
    pkill -P %self 2>/dev/null
    exit 1
end

function run_test
    set tasks $argv[1]
    set intensity $argv[2]
    set duration $argv[3]
    set mandel_iters $argv[4]
    set pi_iters $argv[5]
    set desc $argv[6]

    echo ""
    echo ">>> [TEST] $desc"
    echo ">>> [CONF] Tasks/Process: $tasks | Intensity: $intensity | Duration: $duration | Mandel: $mandel_iters | Pi: $pi_iters"
    
    # Overwrite parameters.cfg for this specific test
    echo "DEFAULT_TASKS=$tasks" > parameters.cfg
    echo "DEFAULT_INTENSITY=$intensity" >> parameters.cfg
    echo "DEFAULT_DURATION_SECONDS=$duration" >> parameters.cfg
    echo "MANDELBROT_ITERATIONS=$mandel_iters" >> parameters.cfg
    echo "PI_ITERATIONS=$pi_iters" >> parameters.cfg

    # Spawn N processes in the background
    for i in (seq 1 $CONTAINERS)
        ./stress_tool.sh --toit &
    end

    # Wait for all background processes to finish
    wait

    echo ">>> Cooldown: waiting 2 seconds..."
    sleep 2
end

# ---------------------------------------------------------
# DECLARATIVE TEST LIST
# ---------------------------------------------------------

# Format: tasks intensity duration mandel_iters pi_iters description

run_test 2  0.20 15 100 5000   "Light Warmup"
run_test 5  0.65 30 500 20000  "Standard Operations"
run_test 15 0.65 30 500 20000  "High Task Contention"
run_test 5  1.00 45 1000 50000 "CPU Bound Maximum Pressure"
run_test 20 1.00 60 2000 100000 "The Gauntlet"

echo ""
echo "========================================================"
echo "Test suite execution finished!"
echo "========================================================"
