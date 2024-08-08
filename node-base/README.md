# Base Node Docker

🐳 Generic docker image for Node Applications.

Available images:
- `lts`: normal version.

## Commands

Docker will default to the `serve` command.

- `serve`: starts all services, such as `nginx`.
- `scheduler`: process scheduled tasks (cron jobs), need to provide argument.
- `worker`: run a specific worker, need to provide argument.
- `node`: helper to execute node commands.
- fallback: execute the provided command.

## Info

Serves content on port `8080`.
