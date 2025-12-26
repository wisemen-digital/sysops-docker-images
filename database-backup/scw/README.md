# Scaleway Database Backup

A Docker image for automated database backups from Scaleway Managed Databases to S3-compatible storage.

## Overview

This image creates backups of Scaleway Managed Databases (PostgreSQL, MySQL) and uploads them to any S3-compatible storage (Scaleway Object Storage, AWS S3, MinIO, etc.). The backup process includes:

1. Creating a backup in Scaleway
2. Exporting the backup
3. Streaming the backup directly to S3 storage
4. Cleaning up the Scaleway backup snapshot

## Environment Variables

### Scaleway Configuration

| Variable | Description | Required |
|----------|-------------|----------|
| `SCW_ACCESS_KEY` | Scaleway API access key | Yes |
| `SCW_SECRET_KEY` | Scaleway API secret key | Yes |
| `SCW_DEFAULT_ORGANIZATION_ID` | Scaleway organization ID | Yes |
| `SCW_DEFAULT_PROJECT_ID` | Scaleway project ID | Yes |
| `SCW_DEFAULT_REGION` | Scaleway region (e.g., `nl-ams`, `fr-par`) | Yes |
| `DB_INSTANCE_ID` | Scaleway database instance ID | Yes |
| `DB_NAME` | Name of the database to backup | Yes |

### S3 Configuration

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `S3_ACCESS_KEY_ID` | S3 access key | Yes | - |
| `S3_SECRET_ACCESS_KEY` | S3 secret key | Yes | - |
| `S3_REGION` | S3 region | Yes | `nl-ams` |
| `S3_ENDPOINT` | S3 endpoint URL | Yes | `https://s3.nl-ams.scw.cloud` |
| `S3_BUCKET` | S3 bucket name | Yes | `my-backups` |
| `S3_PATH` | Path prefix in bucket | Yes | `database/production` |
| `S3_STORAGE_CLASS` | S3 storage class | Yes | Scaleway: `STANDARD`, `ONEZONE_IA`, `GLACIER` |

### Webhook configuration
| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `HEARTBEAT_URL` | Heartbeat webhook url | no | - |

## Backup File Format

Backups are stored with the following naming convention:

```
{DB_NAME}_{TIMESTAMP}.custom
```

Example: `production_20251226T010203Z.custom`

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

For MySQL databases, the backup format may differ. Consult Scaleway documentation for the exact format.


## Error Handling & Heartbeat

The script will exit with code 1 and provide error details if:

- Backup creation fails
- S3 upload fails
- Any critical step encounters an error

Scaleway backup cleanup always runs (even on failure) to avoid accumulating backups.

A heartbeat url can be triggered when the job has been succesfully completed.
If the environment variable is not configured, this step will be skipped.

