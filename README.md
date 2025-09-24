# Docker Images

This is a collection of Docker images, both for development purposes, use during pipelines, or actually running apps.

# Development

Changes to this repository will trigger a build and push to GitHub packages automatically.

# Configuration

## nginx

Images with `nginx` can be configured using the following environment variables.

### CORS

| Environment Key | Applied | Description | Default |
|-----------------|---------|-------------|---------|
| NGINX_CORS_ORIGINS | Every run | Comma separated list of hostnames (without `https://`) | `*` |
| NGINX_CORS_RESOURCE_POLICY | Every run | `Cross-Origin-Resource-Policy` value | `same-origin` |

### Paths

| Environment Key | Applied | Description | Default |
|-----------------|---------|-------------|---------|
| NGINX_API_PATHS | Every run | Comma separated list of paths (without `/`), pointed to the `@api_backend` bucket. Note to only use this on images that have such a backend. | |

### Robots

| Environment Key | Applied | Description | Default |
|-----------------|---------|-------------|---------|
| NGINX_ROBOTS_TAG | Every run | `X-Robots-Tag` value | `none` |
| NGINX_ROBOTS_TXT | Every run | Content of `robots.txt`. Note that setting to `disable` removes the rule completely. | `Disallow: /` |
