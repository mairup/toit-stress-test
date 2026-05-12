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

Run the tool using the Toit VM:

```bash
toit run stress_tool.toit [options]
```

### Options

| Flag | Short | Description | Default |
|------|-------|-------------|---------|
| `--taskn=N` | `-t` | Number of concurrent tasks | `5` |
| `--intensity=V` | `-i` | Load level (`min`, `medium`, `high`, `max`, or `0.0-1.0`) | `medium` |
| `--duration=N` | `-d` | Run duration in seconds or `infinite` | `30` |
| `--help` | `-h` | Show usage information | - |

### Examples

**Standard Benchmark (10 tasks, 1 minute):**
```bash
toit run stress_tool.toit -t=10 -d=60
```

**Heavy Load (High intensity, infinite run):**
```bash
toit run stress_tool.toit --intensity=high --duration=infinite
```

**Custom Intensity (75% load):**
```bash
toit run stress_tool.toit -i=0.75
```

## Project Structure

- `stress_tool.toit`: Core library and entry point containing the `StressTester` orchestrator and `Matrix` engine.
- `config.toit`: Global default settings.
