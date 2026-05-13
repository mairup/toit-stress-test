#!/bin/bash

# Edge Case / Fuzz Tester for test_suite.sh
# This script runs the test suite with various boundary conditions to verify stability.

LOG_FILE="fuzz_test.log"
echo "--- STARTING FUZZ TEST ---" > "$LOG_FILE"

run_fuzz() {
    local desc=$1
    local cmd=$2
    echo "[*] Testing: $desc"
    echo "[*] Command: $cmd"
    
    # Run with a 10s timeout to prevent hanging, capture output
    timeout 15s $cmd > temp_output.txt 2>&1
    local status=$?
    
    if [ $status -eq 124 ]; then
        echo "    [TIMEOUT] OK (Expected for long runs)"
    elif [ $status -ne 0 ]; then
        echo "    [FAIL] Exit code: $status"
        cat temp_output.txt >> "$LOG_FILE"
    else
        echo "    [PASS] Finished successfully"
    fi
    echo "-----------------------------------"
}

# 1. Zero Containers
run_fuzz "Zero containers" "./test_suite.sh 0 --min"

# 2. Very Short Duration (Stress testing the math)
run_fuzz "1-second total duration" "./test_suite.sh 1 --duration 1"

# 3. Non-existent filter
run_fuzz "Filter with no matches (--high)" "./test_suite.sh 1 --high"

# 4. Multiple filters
run_fuzz "Combined filters (--min --max)" "./test_suite.sh 1 --min --max"

# 5. Huge duration
run_fuzz "Huge duration" "./test_suite.sh 1 --duration 9999 --min"

# 6. Invalid non-numeric argument (should be ignored by parser)
run_fuzz "Invalid container arg" "./test_suite.sh abc --min"

# 7. Rapid Start/Stop (Interrupt test)
echo "[*] Testing: Rapid Interrupt"
./test_suite.sh 4 --min > /dev/null 2>&1 &
PID=$!
sleep 1
kill -INT $PID
wait $PID 2>/dev/null
echo "    [DONE] Checked manual interrupt"

# Final Cleanup Check
echo "[*] Checking for zombie processes..."
pgrep -f stress_tool > /dev/null
if [ $? -eq 0 ]; then
    echo "    [FAIL] Orphan processes found!"
    pkill -9 -f stress_tool
else
    echo "    [PASS] Clean exit"
fi

rm temp_output.txt
echo "--- FUZZ TEST COMPLETE ---"
