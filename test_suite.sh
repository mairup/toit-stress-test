#!/bin/bash

FILTER=""
CONTAINERS=1
REQUESTED_DURATION=0
TOTAL_EXPECTED_DURATION=0
MATCH_COUNT=0
TOTAL_DEFAULT_WORK_DURATION=0

# Parse CLI arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --min)    FILTER="$FILTER min"; shift ;;
        --medium) FILTER="$FILTER medium"; shift ;;
        --high)   FILTER="$FILTER high"; shift ;;
        --max)    FILTER="$FILTER max"; shift ;;
        -d=*|--duration=*)
            REQUESTED_DURATION="${1#*=}"
            if [[ ! "$REQUESTED_DURATION" =~ ^[0-9]+$ ]]; then
                echo "Error: Invalid duration '$REQUESTED_DURATION'. Must be a positive integer."
                exit 1
            fi
            shift
            ;;
        -d|--duration)
            shift
            REQUESTED_DURATION=$1
            if [[ ! "$REQUESTED_DURATION" =~ ^[0-9]+$ ]]; then
                echo "Error: Invalid duration '$REQUESTED_DURATION'. Must be a positive integer."
                exit 1
            fi
            shift
            ;;
        --help|-h)
            echo "Usage: ./test_suite.sh [containers] [--min] [--medium] [--high] [--max] [-d|--duration seconds]"
            exit 0
            ;;
        [0-9]*)
            if [[ ! "$1" =~ ^[0-9]+$ ]]; then
                echo "Error: Invalid container count '$1'. Must be a positive integer."
                exit 1
            fi
            CONTAINERS=$1; shift ;;
        *)
            echo "Error: Unknown argument '$1'"
            exit 1
            ;;
    esac
done

cleanup() {
    echo -e "\n[!] Caught Ctrl+C. Forcefully terminating all background workers..."
    # 1. Kill all background jobs known to this shell
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

    # Translate intensity profile names to numeric values (case-insensitive and trimmed)
    intensity=$(echo "$intensity" | xargs | tr '[:upper:]' '[:lower:]')
    case "$intensity" in
        min)    intensity=0.20 ;;
        medium) intensity=0.65 ;;
        high)   intensity=0.90 ;;
        max)    intensity=1.00 ;;
    esac

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
            ./stress_tool.sh --toit --silent -- --print &
        else
            # All subsequent processes are silent by default
            ./stress_tool.sh --toit --silent &
        fi
    done

    # Wait for all background processes to finish
    wait

    echo ">>> Cooldown: waiting 2 seconds..."
    sleep 2
}

# ---------------------------------------------------------
# TEST DEFINITION WRAPPER
# ---------------------------------------------------------

# This allows us to "dry run" the test list to calculate total time
# before actually executing anything.
queue_test() {
    local tasks=$1
    local intensity=$2
    local duration=$3
    local desc=$4
    
    # Filter check
    if [ -n "$FILTER" ]; then
        if [[ ! "$FILTER" =~ "$intensity" ]]; then
            return 0
        fi
    fi
    
    if [ "$MODE" == "calculate" ]; then
        MATCH_COUNT=$((MATCH_COUNT + 1))
        TOTAL_DEFAULT_WORK_DURATION=$((TOTAL_DEFAULT_WORK_DURATION + duration))
    else
        # Apply scaling if requested
        if [ "$REQUESTED_DURATION" -gt 0 ]; then
            # Calculate new duration using scale factor: (WORK_BUDGET / TOTAL_DEFAULT) * duration
            # Rounded to nearest integer
            duration=$(awk "BEGIN { printf \"%d\", ($WORK_BUDGET / $TOTAL_DEFAULT_WORK_DURATION) * $duration + 0.5 }")
            if [ "$duration" -lt 1 ]; then duration=1; fi
        fi
        run_test "$tasks" "$intensity" "$duration" "$desc"
    fi
}

define_tests() {
    queue_test 2 min 10 "Stage 1: Low Load"
    queue_test 5 medium 20 "Stage 2: Moderate Load"
    queue_test 10 medium 20 "Stage 3: High Task Count"
    queue_test 5 max 30 "Stage 4: 100% CPU Load"
    queue_test 20 max 40 "Stage 5: Maximum System Stress"
}

# 1. First pass: Calculate default totals and match count
MODE="calculate"
define_tests

# 2. Adjust for requested duration if provided
if [ "$REQUESTED_DURATION" -gt 0 ]; then
    # Work budget = Total time - (cooldowns)
    WORK_BUDGET=$((REQUESTED_DURATION - (MATCH_COUNT * 2)))
    if [ "$WORK_BUDGET" -lt "$MATCH_COUNT" ]; then
        WORK_BUDGET=$MATCH_COUNT
    fi
    TOTAL_EXPECTED_DURATION=$REQUESTED_DURATION
else
    TOTAL_EXPECTED_DURATION=$((TOTAL_DEFAULT_WORK_DURATION + (MATCH_COUNT * 2)))
fi

echo "========================================================"
echo "Starting Gradual Stress Test Suite (Local PC)"
echo "Spawning $CONTAINERS concurrent OS processes per test"
echo "Total expected run time: ${TOTAL_EXPECTED_DURATION}s"
echo "========================================================"

# 3. Second pass: Execute
MODE="run"
define_tests

echo ""
echo "========================================================"
echo "Test suite execution finished!"
echo "========================================================"
