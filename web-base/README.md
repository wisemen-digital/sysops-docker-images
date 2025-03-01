# Base Web Docker

🐳 Generic docker image for static web applications.

Available images:
- `latest`: normal version.
- `latest-unsecured`: **without** extra security nginx options.

## Commands

Docker will default to the `serve` command.

- `serve`: starts all services, such as `nginx`.
- fallback: execute the provided command.

## Info

Serves content on port `80`.

## Configuration

Check the [general readme](../README.md) for configuring common settings.

# Environment Injection

:exclamation: Note that, if available, it will execute the `import-meta-env` command. This relies on a few things:
- The `import-meta-env` executable is availabe in a PATH location (such as `/usr/bin`).
- The template (example) env file is located at `/etc/import-meta-env/example`.

For more information about this mechanism, read the [import-meta-env](https://import-meta-env.org/guide/getting-started/runtime-transform.html) docs.
