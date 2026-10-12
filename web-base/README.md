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

# Environment Injection

:exclamation: Note that, if available, it will execute the `import-meta-env` command. This relies on a few things:
- The `import-meta-env` executable is availabe in a PATH location (such as `/usr/bin`).
- The template (example) env file is located at `/etc/import-meta-env/example`.

For more information about this mechanism, read the [import-meta-env](https://import-meta-env.org/guide/getting-started/runtime-transform.html) docs.

# Server-side head fragments

Set `NGINX_SSI_HEAD_URL`, for example `https://api.example.com/api/public/head`, to
enable Server Side Includes for the HTML entrypoint and SPA fallback routes.
Leave it unset to retain normal static HTML serving. Other image families are
unaffected. No application-specific nginx configuration is needed.

Replace the application's static branding tags with this include inside `<head>`:

```html
<!--# include virtual="/_ssi/head" wait="yes" -->
```

An application can provide neutral tags when the upstream fails or returns an
empty fragment:

```html
<!--# block name="head-fallback" -->
<title>Website</title>
<meta name="description" content="Generic description." />
<!--# endblock -->
<!--# include virtual="/_ssi/head" wait="yes" stub="head-fallback" -->
```

Keep charset and viewport tags outside the include. Ensure your HTML build
preserves SSI comments. Nginx inserts the fragment before continuing past the
include, so tags are available in the initial response without browser JavaScript.
The internal `/_ssi/head` and `/_ssi/head-empty` paths cannot be requested directly.

## Upstream contract

- Return `200` and `Content-Type: text/html`, with head elements only. Escape all
  user-controlled text and attributes. Use stable, publicly accessible image
  and icon URLs rather than expiring signed URLs.
- Resolve the domain from `X-Forwarded-Host`. Nginx overwrites it with its `$host`
  value. The upstream HTTP `Host` and HTTPS SNI identify the configured API server.
- Return public content determined only by this domain and the configured
  endpoint. Browser cookies, authorization, request bodies, paths, and query
  parameters are not forwarded. A query in `NGINX_SSI_HEAD_URL` is sent unchanged.
- Omit cache freshness headers to use `NGINX_SSI_HEAD_CACHE_TTL`, or set matching
  upstream freshness headers. Nginx honors `Cache-Control`, `Expires`, and
  `X-Accel-Expires`; they can override the configured freshness. `private`,
  `no-cache`, `no-store`, `Set-Cookie`, and `Vary: *` prevent caching.
- Redirects and errors become empty fragments and are not cached. Connect timeout
  is one second; send/read timeouts are two seconds between successive operations.
  These timeouts are not a total response deadline. Errors during an already
  streamed response cannot retract bytes that have been sent.

HTTPS certificate verification is enabled with the image's system trust store.
The URL must be literal HTTP(S), without credentials, a fragment, nginx variables,
or configuration delimiters. Percent-encode unsupported URI characters. Upstream
hostnames resolve at nginx startup; restart the container after DNS changes.

## Caching and performance

Each configured endpoint/domain pair has an independent cache entry. All pages
on one domain share it. The first visitor waits for the API response. Subsequent
visitors use the local fragment cache, avoiding metadata API requests.

After the default one-hour freshness expires, the next visitor receives the
previous fragment while nginx refreshes it in the background. Refreshes are
traffic-driven: there is no polling or preloading of inactive domains. Cache
locking reduces duplicate requests when concurrent visitors first open a domain.
Persistent stale-on-error serving is not enabled.

Response bodies are stored under `/tmp/ssi-head-cache`; cache metadata uses a
one-megabyte shared memory index. Entries with no access for two hours are removed.
The cache manager also evicts least recently used entries to keep the disk cache
near its 100-megabyte limit. Cleanup is asynchronous. Override these limits using
the variables in the [configuration reference](../README.md#server-side-head-fragments-web-base-only).

Every container/replica maintains its own cache; cached content is not shared
between replicas. Recreating a container discards its local cache. Metadata changes
can take one hour plus refresh time to appear. The assembled HTML retains
`no-cache, must-revalidate`; its static-file ETag/Last-Modified validators are
disabled while SSI is enabled. CSS/JavaScript caching and gzip are unchanged.

Validate compression, initial source HTML, and fallback behavior in the consuming
application before enabling the feature in production.
