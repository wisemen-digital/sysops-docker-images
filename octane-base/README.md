# Base PHP Docker

🐳 Generic docker image for Laravel Octane Applications.

Available images (one for each PHP version):
- `8.1`
- `8.2`
- `8.3`

## Commands

Docker will default to the `serve` command.

- `serve`: starts all services, such as `nginx` and `octane`.
- `scheduler`: process scheduled tasks (cron jobs).
- `queue`: process queued jobs. You can provide a specific queue with `--queue=my_queue`.
- `init`: initialize the project, such as executing migrations.
- `artisan`: helper to execute artisan commands.
- fallback: execute the provided command.

## Info

Serves content on port `8080`.