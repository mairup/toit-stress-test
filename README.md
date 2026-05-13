# Toit Stress Test Tool

A modular and configurable utility designed to stress the Toit VM and container system through concurrent workloads of CPU-intensive arithmetic and memory-heavy matrix operations.

## Features

- **Multi-Tasking**: Spawn multiple concurrent worker tasks to test the scheduler and resource isolation.
- **Intensity Profiles**: 
  - `min`: 20% work / 80% sleep
  - `medium`: 65% work / 35% sleep
  - `high`: 90% work / 10% sleep
  - `max`: 100% work (no sleep)
- **Flexible Duration**: Run for a specific number of seconds or set to `infinite`.
- **Layered Configuration**: Use `config.toit` for defaults and override them via CLI arguments.

## Usage

This tool is configured via the `config.toit` file.

### Configuration (`parameters.cfg`)

Before running the test, edit `parameters.cfg` using bash or any text editor:

```ini
DEFAULT_TASKS=5
DEFAULT_INTENSITY=0.65
DEFAULT_DURATION_SECONDS=30
```

### Running the Tool

We have provided a unified bash script that handles translating your `parameters.cfg` file into a Toit-compatible format on the fly. 

To run the test on an **ESP32 device via Jaguar** (Default):
```bash
./stress_tool.sh
```
*(Or explicitly use `./stress_tool.sh --jag`)*

To run the test locally on your **PC via the Toit VM**:
```bash
./stress_tool.sh --toit
```

*Note: You can pass extra arguments to the Toit VM after a `--` separator, such as `./stress_tool.sh -t -- --print`.*


## Project Structure

- `stress_tool.toit`: Core library and entry point containing the orchestrator and load functions.
- `config.toit`: Auto-generated file containing Toit constants based on parameters.cfg.
- `stress_tool.sh`: The main unified shell runner.
- `test_suite.sh`: The automated multi-process test orchestrator.

## Automated Test Suite (`test_suite.sh`)

For heavy-duty system load testing, the `test_suite.sh` script orchestrates a gradual, multi-process stress test on your local PC. It spawns multiple independent OS-level processes, each running its own instance of the Toit VM.

### Usage

Run the test suite and specify the number of concurrent OS processes (containers) you want to spawn:

```bash
./test_suite.sh <containers>
```

**Example (Spawning 32 concurrent OS processes):**
```bash
./test_suite.sh 32
```

The suite will automatically progress through several escalating stages, modifying the parameters on the fly:
1. **Light Warmup**: Low intensity, short duration.
2. **Standard Operations**: Medium intensity.
3. **High Task Contention**: Medium intensity, high number of Toit tasks per process.
4. **CPU Bound Maximum Pressure**: 100% intensity, moderate duration.
5. **The Gauntlet**: 100% intensity, maximum task count, long duration.

If your system begins to lock up, you can hit `Ctrl+C` to immediately forcefully terminate all associated background VMs and halt the test suite.
