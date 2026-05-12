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


## Project Structure

- `stress_tool.toit`: Core library and entry point containing the `StressTester` orchestrator and `Matrix` engine.
- `config.toit`: Global default settings.
