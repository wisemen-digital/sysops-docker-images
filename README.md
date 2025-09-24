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

### Content Security Policy

You can control the CSP behaviour with the `NGINX_CSP_MODE` key:
- `enforce` (default): Configure the `Content-Security-Policy` header.
- `report-only`: Instead configure the `Content-Security-Policy-Report-Only` header.

Note: the following fetch & navigation CSP keys can also be set via an embedded file located at `/etc/csp-generator/default`.

Fetch:

| Environment Key | Applied | Description | Default |
|-----------------|---------|-------------|---------|
| NGINX_CSP_CHILD_SRC | Every run | Allowed children (workers, frames) | |
| NGINX_CSP_CONNECT_SRC | Every run | Allowed connections (socket, xhr, …) | |
| NGINX_CSP_FONT_SRC | Every run | Allowed fonts | |
| NGINX_CSP_FRAME_SRC | Every run | Allowed iframes | |
| NGINX_CSP_IMG_SRC | Every run | Allowed images | |
| NGINX_CSP_MANIFEST_SRC | Every run | Allowed manifests | |
| NGINX_CSP_MEDIA_SRC | Every run | Allowed media | |
| NGINX_CSP_OBJECT_SRC | Every run | Allowed embeds | |
| NGINX_CSP_REQUIRE_TRUSTED_TYPES_FOR| Every run | Enable type checking for … | |
| NGINX_CSP_SCRIPT_SRC | Every run | Allowed scripts | |
| NGINX_CSP_STYLE_SRC | Every run | Allowed styles | |
| NGINX_CSP_TRUSTED_TYPES | Every run | List of type policies | |
| NGINX_CSP_WORKER_SRC | Every run | Allowed workers | |

Navigation:

| Environment Key | Applied | Description | Default |
|-----------------|---------|-------------|---------|
| NGINX_FRAME_OPTIONS | Every run | Possible embedders, deprecated. Note that setting to `disable` removes the header completely. | `deny` |
| NGINX_CSP_FRAME_ANCESTORS | Every run | Possible embedders | |
| NGINX_CSP_FORM_ACTION | Every run | Form submit action | |

Reporting:

| Environment Key | Applied | Description | Default |
|-----------------|---------|-------------|---------|
| NGINX_CSP_REPORT_URI | Every run | Set to Sentry CSP reporting URI | |

### Paths

| Environment Key | Applied | Description | Default |
|-----------------|---------|-------------|---------|
| NGINX_API_PATHS | Every run | Comma separated list of paths (without `/`), pointed to the `@api_backend` bucket. Note to only use this on images that have such a backend. | |

### Robots

| Environment Key | Applied | Description | Default |
|-----------------|---------|-------------|---------|
| NGINX_ROBOTS_TAG | Every run | `X-Robots-Tag` value | `none` |
| NGINX_ROBOTS_TXT | Every run | Content of `robots.txt`. Note that setting to `disable` removes the rule completely. | `Disallow: /` |
