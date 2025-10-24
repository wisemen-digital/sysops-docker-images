# Base Nuxt Docker

🐳 Generic docker image for Nuxt Applications.

Available images:
- `lts`: normal version.

## Commands

Docker will default to the `serve` command.

- `serve`: starts all services, such as `nginx`.
- fallback: execute the provided command.

## Info

Serves content on port `8080`.

## Configuration

Check the [general readme](../README.md) for configuring common settings.

This image can be configured using the following environment variables:

| Environment Key | Applied | Description | Default |
|-----------------|---------|-------------|---------|
| MONITOR_MEM_THRESHOLD | Every run | Percentage of maximum memory use that cannot be exceeded for the given processes (see below). Stops the container if exceeded. | `85` |
| MONITOR_PID_NAME | Every run | Name of the processes to look for (using `pidof`) | `node` |
