# Base PHP Docker

🐳 Generic docker image for PHP (Laravel) Applications.

Available images (one for each PHP version):
- `8.1`
- `8.2`
- `8.3`

## Commands

Docker will default to the `serve` command.

- `serve`: starts all services, such as `nginx` and `php-fpm`.
- `scheduler`: process scheduled tasks (cron jobs).
- `queue`: process queued jobs. You can provide a specific queue with `--queue=my_queue`.
- `init`: initialize the project, such as executing migrations.
- `artisan`: helper to execute artisan commands.
- fallback: execute the provided command.

## Configuration

You can configure the max. allowed uploads via these 2 variables:
- `SERVER_POST_MAX_SIZE`: max post size (in nginx and PHP)
- `SERVER_POST_MAX_FILESIZE`: max upload file size (in PHP)
