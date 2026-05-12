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

### Running Locally (PC)

You can run the test on your local machine using the Toit VM. It will automatically read the `parameters.cfg` file from your disk:

```bash
toit run stress_tool.toit
```

### ⚠️ Running on a Device (Jaguar)

Because this tool now reads a file (`parameters.cfg`) from the local Linux filesystem using `host.file`, **it will not compile out-of-the-box on an ESP32 via `jag run`**. ESP32 devices do not have access to your PC's filesystem.

To run this on an ESP32, you will need to either pass the config as an asset (`--assets`) and switch the import to `system.assets`, or use Jaguar defines (`-D`).


## Project Structure

- `stress_tool.toit`: Core library and entry point containing the `StressTester` orchestrator and `Matrix` engine.
- `config.toit`: Global default settings.
