# Matomo Docker

🐳 Variant of the official Matomo docker image, tweaked to match our preferences.

Available images:
- `latest`: normal version.

## Commands

Docker will default to the `serve` command.

- `serve`: starts all services, such as `nginx`.
- `scheduler`: process scheduled tasks (cron jobs).
- `init`: initialize the project, such as executing migrations.
- fallback: execute the provided command.

# Initialization

Using an init container (that invokes `init` command above), the container will be prepared for use. This entails:

- Running through the Matomo onboarding wizard.
- Installing some plugins.
- Tweaking some base Matomo options.
- Applying the environment variables to the Matomo config.

# Configuration

This image can be configured using the following environment variables:

| Environment Key | Applied | Description |
------------------|---------|--------------
| MATOMO_USERNAME | Bootstrap only | Admin user username |
| MATOMO_PASSWORD | Bootstrap only | Admin user password |
| MATOMO_EMAIL | Bootstrap only | Admin user email address |
| MATOMO_HOST | Bootstrap only | Hostname of the first website that'll be created |
| MATOMO_WEBSITE_NAME | Bootstrap only | Name of the first website that'll be created |
| MATOMO_SMTP_HOST | Every run | SMTP server hostname |
| MATOMO_SMTP_PORT_NUMBER | Every run | SMTP server port number |
| MATOMO_SMTP_USER | Every run | SMTP server username |
| MATOMO_SMTP_PASSWORD | Every run | SMTP server password |
| MATOMO_SMTP_ENCRYPTION | Every run | SMTP server encryption |
| MATOMO_NOREPLY_NAME | Every run | Sender name for sent emails |
| MATOMO_NOREPLY_ADDRESS | Every run | Sender email address for sent emails |
| MATOMO_DATABASE_HOST | Every run | Database hostname |
| MATOMO_DATABASE_PORT_NUMBER | Every run | Database port number |
| MATOMO_DATABASE_NAME | Every run | Database name |
| MATOMO_DATABASE_USER | Every run | Database user |
| MATOMO_DATABASE_PASSWORD | Every run | Database password |
