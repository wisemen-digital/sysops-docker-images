# Docker Images

This is a collection of Docker images, both for development purposes, use during pipelines, or actually running apps.

# Development

Changes to this repository will trigger a build and push to GitHub packages automatically.

# Configuration

## nginx

Images with `nginx` can be configured using the following environment variables.

### Robots

| Environment Key | Applied | Description | Default |
|-----------------|---------|-------------|---------|
| NGINX_ROBOTS_TAG | Every run | `X-Robots-Tag` value | `none` |
| NGINX_ROBOTS_TXT | Every run | Content of `robots.txt` | `Disallow: /` |
