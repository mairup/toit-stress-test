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

This tool is entirely configured via the `config.toit` file. This approach ensures that your benchmark parameters remain consistent across local tests and device deployments.

### Configuration (`config.toit`)

Before running the test, edit `config.toit` to set your desired parameters:

- `DEFAULT_TASKS`: Number of concurrent tasks.
- `DEFAULT_INTENSITY`: Load level (`0.20` for min, `0.65` for medium, `0.90` for high, `1.00` for max).
- `DEFAULT_DURATION_SECONDS`: Run duration in seconds, or `null` for an infinite run.

### Running on a Device (Jaguar)

Once configured, simply flash and run the test on your ESP32 device using Jaguar:

```bash
jag run stress_tool.toit
```

### Running Locally (PC)

You can also run the test on your local machine using the Toit VM:

```bash
toit run stress_tool.toit
```


## Project Structure

- `stress_tool.toit`: Core library and entry point containing the `StressTester` orchestrator and `Matrix` engine.
- `config.toit`: Global default settings.
