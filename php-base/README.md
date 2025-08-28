# Base PHP Docker

🐳 Generic docker image for PHP (Laravel) Applications.

Available images (one for each PHP version):
- `8.1`
- `8.2`
- `8.3`
- `8.4`

## Commands

Docker will default to the `serve` command.

- `serve`: starts all services, such as `nginx` and `php-fpm`.
- `scheduler`: process scheduled tasks (cron jobs).
- `queue`: process queued jobs. You can provide a specific queue with `--queue=my_queue`.
- `websockets`: provide pusher websockets service.
- `init`: initialize the project, such as executing migrations.
- `artisan`: helper to execute artisan commands.
- fallback: execute the provided command.

## Info

Serves content on port `8080`.

## Configuration

Check the [general readme](../README.md) for configuring common settings.

This image can be configured using the following environment variables:

| Environment Key | Applied | Description | Default |
|-----------------|---------|-------------|---------|
| NGINX_MAX_BODY_SIZE | Every run | nginx: maximum client body size | `8M` |
| PHP_FPM_MEMORY_LIMIT | Every run | PHP: maximum FPM memory limit | `256M` |
| PHP_POST_MAX_SIZE | Every run | PHP: maximum post size, should match nginx | `8M` |
| PHP_POST_MAX_FILESIZE | Every run | PHP: maximum post file size | `2M` |

### FPM `pm` Mode

You can controle the FPM `pm` mode with the `PHP_FPM_PM` key:
- `static` (default): Set the amount of workers to a fixed value.
- `ondemand`: Set the amount of workers to a dynamic amount, scaling to a very high number. Meant for autoscaling setups.
