# Database Backup

🐳 A Docker image for automated database backups from Managed Databases to S3-compatible storage.

Available images:
- `latest`: normal version.

## Commands

This image supports multiple commands:

- `backup`: creates backups of managed DBs (PostgreSQL, MySQL) and uploads them to any S3-compatible storage (Scaleway Object Storage, AWS S3, MinIO, etc.)
- fallback: execute the provided command.

## Configuration

Configuration is done using environment variables, and may depend on the command.

### Command `backup`

You'll need to select a DB provider, and also:
- Provider-specific configuration, see below for example for [Provider scw](#provider-scw).
- Configure [general S3 remote](#general-s3-remote).

| Variable | Description | Required |
|----------|-------------|----------|
| `DB_PROVIDER` | Hosting provider (i.e. `scw`) | Yes |
| `DB_INSTANCE_ID` | Database instance ID | Yes |
| `DB_NAME` | Name of the database to backup | Yes |

### Provider `scw`

| Variable | Description | Required |
|----------|-------------|----------|
| `SCW_ACCESS_KEY` | Scaleway API access key | Yes |
| `SCW_SECRET_KEY` | Scaleway API secret key | Yes |
| `SCW_DEFAULT_ORGANIZATION_ID` | Scaleway organization ID | Yes |
| `SCW_DEFAULT_PROJECT_ID` | Scaleway project ID | Yes |
| `SCW_DEFAULT_REGION` | Scaleway region (e.g., `nl-ams`, `fr-par`) | Yes |

### General S3 Remote

Will be used by `rclone` to address a S3-bucket as a remote.

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `S3_PROVIDER` | S3 provider (e.g. `Scaleway`, see rclone docs) | Yes |
| `S3_ACCESS_KEY_ID` | S3 access key | Yes | - |
| `S3_SECRET_ACCESS_KEY` | S3 secret key | Yes | - |
| `S3_REGION` | S3 region | Yes | `nl-ams` |
| `S3_ENDPOINT` | S3 endpoint URL | Yes | `s3.nl-ams.scw.cloud` |
| `S3_BUCKET` | S3 bucket name | Yes | `my-backups` |
| `S3_PATH` | Path prefix in bucket | Yes | `database/production` |
| `S3_STORAGE_CLASS` | S3 storage class | No | Scaleway: `STANDARD`, `ONEZONE_IA`, `GLACIER` |

### Webhook configuration

A heartbeat url can be triggered when the job has been succesfully completed.
If the environment variable is not configured, this step will be skipped.

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `HEARTBEAT_URL` | Heartbeat webhook url | no | - |

## Backup File Format

Backups are stored with the following naming convention:

```
{DB_NAME}_{TIMESTAMP}.custom
```

Example: `production_20251226T01.custom`

The `.custom` format is PostgreSQL's custom format, which can be restored using `pg_restore`.

## Restoring Backups

### PostgreSQL

```bash
# Restore to database
pg_restore \
  -h ip \
  -p port \
  -U user \
  -d database \
  --no-owner \
  --no-privileges \
  --single-transaction \
  --exclude-schema=_timescaledb_internal \
  --exclude-schema=_timescaledb_cache \
  --exclude-schema=_timescaledb_catalog \
  --exclude-schema=_timescaledb_config \
  production_20251226T010203Z.custom
```

### MySQL/MariaDB

For MySQL databases, the backup format may differ. Consult documentation for the exact format.

## Error Handling & Heartbeat

The script will exit with code 1 and provide error details if:

- Backup creation fails
- S3 upload fails
- Any critical step encounters an error

Backup cleanup run after a successful sync to avoid accumulating backups. If configured, a heartbeat webhook will be triggered.
