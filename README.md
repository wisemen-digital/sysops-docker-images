# Docker Images

This is a collection of Docker images, both for development purposes, use during pipelines, or actually running apps.

# Development

Changes to this repository will trigger a build and push to GitHub packages automatically.

# Configuration

## nginx

Images with `nginx` can be configured using the following environment variables.

### Content Security Policy

Fetch:

| Environment Key | Applied | Description | Default |
------------------|---------|------------------------
| NGINX_CSP_CHILD_SRC | Every run | Allowed children (workers, frames) | |
| NGINX_CSP_CONNECT_SRC | Every run | Allowed connections (socket, xhr, …) | |
| NGINX_CSP_FONT_SRC | Every run | Allowed fonts | `https://fonts.gstatic.com` |
| NGINX_CSP_FRAME_SRC | Every run | Allowed iframes | `https://youtube.com https://www.youtube.com` |
| NGINX_CSP_IMG_SRC | Every run | Allowed images | `https:` |
| NGINX_CSP_MANIFEST_SRC | Every run | Allowed manifests | |
| NGINX_CSP_MEDIA_SRC | Every run | Allowed media | `https:` |
| NGINX_CSP_OBJECT_SRC | Every run | Allowed embeds | |
| NGINX_CSP_SCRIPT_SRC | Every run | Allowed scripts | |
| NGINX_CSP_STYLE_SRC | Every run | Allowed styles | `https://fonts.googleapis.com` |
| NGINX_CSP_WORKER_SRC | Every run | Allowed workers | |

Navigation:

| Environment Key | Applied | Description | Default |
------------------|---------|------------------------
| NGINX_FRAME_OPTIONS | Every run | Possible embedders, deprecated. Note that setting to `disable` removes the header completely. | `deny` |
| NGINX_CSP_FRAME_ANCESTORS | Every run | Possible embedders | `none` |
| NGINX_CSP_FORM_ACTION | Every run | Form submit action | |

Reporting:

| Environment Key | Applied | Description | Default |
------------------|---------|------------------------
| NGINX_CSP_REPORT_URI | Every run | Set to Sentry CSP reporting URI | |

### Robots

| Environment Key | Applied | Description | Default |
------------------|---------|------------------------
| NGINX_ROBOTS_TAG | Every run | `X-Robots-Tag` value | `none` |
| NGINX_ROBOTS_TXT | Every run | Content of `robots.txt` | `Disallow: /` |
