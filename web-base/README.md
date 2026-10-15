# Base Web Docker

🐳 Generic docker image for static web applications.

Available images:
- `latest`: normal version.

## Commands

Docker will default to the `serve` command.

- `serve`: starts all services, such as `nginx`.
- fallback: execute the provided command.

## Info

Serves content on port `80`.

## Configuration

Check the [general readme](../README.md) for configuring common settings.

### Server-side head fragments

Set `NGINX_SSI_HEAD_URL` to enable domain-specific head fragments in the HTML
entrypoint and SPA fallback routes. Leave it unset to retain static HTML serving.
Use an internal HTTP endpoint; TLS terminates at the Kubernetes ingress/gateway.

| Environment Key | Applied | Description | Default |
|-----------------|---------|-------------|---------|
| NGINX_SSI_HEAD_URL | Every run | Literal HTTP URL returning public HTML head elements. | |
| NGINX_SSI_HEAD_CACHE_TTL | Every run | Freshness duration without upstream freshness headers. | `1h` |
| NGINX_SSI_HEAD_CACHE_INACTIVE | Every run | Remove cache entries not accessed for this duration. | `2h` |
| NGINX_SSI_HEAD_CACHE_MAX_SIZE | Every run | Maximum disk cache size per container. | `100m` |

Cache settings use nginx duration and size syntax (for example `1m`, `1h`,
and `100m`). nginx validates these values when it starts.

Include the fragment inside `<head>` and preserve SSI comments in the HTML build:

```html
<!--# include virtual="/_ssi/head" wait="yes" -->
```

The upstream must return `200 text/html` with escaped head elements and stable
public asset URLs, based only on `X-Forwarded-Host` (set by nginx to the requested
domain). Browser credentials, paths, and query parameters are not forwarded;
a query configured in the upstream URL is retained.

Fragments are cached separately per endpoint/domain in each container. Expired
entries are served while a traffic-triggered background refresh runs. Upstream
freshness headers override the configured TTL. Inactivity controls eviction
after the last access, not a hard maximum age or an immediate cache purge.
Common upstream redirects and errors produce an empty fragment; use an SSI
`stub` for application-defined fallback content.

See the [nginx SSI documentation](https://nginx.org/en/docs/http/ngx_http_ssi_module.html)
for include and fallback syntax.

# Environment Injection

:exclamation: Note that, if available, it will execute the `import-meta-env` command. This relies on a few things:
- The `import-meta-env` executable is availabe in a PATH location (such as `/usr/bin`).
- The template (example) env file is located at `/etc/import-meta-env/example`.

For more information about this mechanism, read the [import-meta-env](https://import-meta-env.org/guide/getting-started/runtime-transform.html) docs.
