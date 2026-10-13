import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';

const containerScript = '/scripts/startup/50-env-configure-nginx-ssi-head.sh';
const startup = existsSync(containerScript) ? containerScript
  : fileURLToPath(new URL('../../web-base/scripts/startup/50-env-configure-nginx-ssi-head.sh', import.meta.url));

function fixture(t) {
  const directory = mkdtempSync(join(tmpdir(), 'ssi-head-config-'));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const nginx = join(directory, 'nginx');
  const script = join(directory, 'configure.sh');
  const bin = join(directory, 'bin');
  mkdirSync(bin);
  writeFileSync(join(bin, 'chown'), '#!/bin/sh\nexit 0\n', { mode: 0o755 });
  writeFileSync(script, readFileSync(startup, 'utf8')
    .replaceAll('/etc/nginx', nginx).replaceAll('/tmp/ssi-head-cache', join(directory, 'cache')));
  const env = Object.fromEntries(Object.entries(process.env).filter(([key]) => !key.startsWith('NGINX_SSI_HEAD_')));
  return {
    configure(settings = {}) {
      return spawnSync('sh', [script], {
        env: { ...env, ...settings, PATH: `${bin}:${env.PATH}` }, encoding: 'utf8', timeout: 5000,
      });
    },
    read: (path) => readFileSync(join(nginx, path), 'utf8'),
    exists: (path) => existsSync(join(nginx, path)),
  };
}

test('opting out removes previously generated configuration', (t) => {
  const f = fixture(t);
  assert.equal(f.configure({ NGINX_SSI_HEAD_URL: 'http://127.0.0.1/head' }).status, 0);
  assert.equal(f.configure().status, 0);
  assert.doesNotMatch(f.read('snippets/ssi-head-html.conf'), /ssi on/);
  assert.equal(f.exists('http.d/generated-ssi-head-cache.conf'), false);
  assert.equal(f.exists('site-mods-enabled.d/generated-ssi-head.conf'), false);
});

test('defaults isolate domains, strip credentials, and allow only successful cache fills', (t) => {
  const f = fixture(t);
  const url = 'https://api.example.test/head?source=web&language=en';
  assert.equal(f.configure({ NGINX_SSI_HEAD_URL: url }).status, 0);
  const location = f.read('site-mods-enabled.d/generated-ssi-head.conf');
  assert.ok(location.includes(`proxy_cache_key "${url}|$host";`));
  assert.doesNotMatch(location, /\$request_uri/);
  for (const directive of ['proxy_pass_request_headers off;', 'proxy_set_header X-Forwarded-Host $host;',
    'proxy_ssl_verify on;', 'proxy_cache_valid 200 1h;', 'proxy_cache_background_update on;',
    'proxy_cache_use_stale updating;', 'proxy_no_cache $ssi_head_do_not_cache;']) {
    assert.ok(location.includes(directive), directive);
  }
  assert.match(f.read('http.d/generated-ssi-head-cache.conf'), /max_size=100m inactive=2h/);
  assert.match(f.read('snippets/ssi-head-html.conf'), /etag off;\nif_modified_since off;/);
});

test('bare endpoint URLs target the upstream root', (t) => {
  const f = fixture(t);
  assert.equal(f.configure({ NGINX_SSI_HEAD_URL: 'https://127.0.0.1:8081' }).status, 0);
  assert.match(f.read('site-mods-enabled.d/generated-ssi-head.conf'), /proxy_pass "https:\/\/127\.0\.0\.1:8081\/";/);
});

test('cache limits are configurable', (t) => {
  const f = fixture(t);
  assert.equal(f.configure({ NGINX_SSI_HEAD_URL: 'http://[::1]:8081/head',
    NGINX_SSI_HEAD_CACHE_TTL: '5s', NGINX_SSI_HEAD_CACHE_INACTIVE: '30m', NGINX_SSI_HEAD_CACHE_MAX_SIZE: '8m' }).status, 0);
  assert.match(f.read('site-mods-enabled.d/generated-ssi-head.conf'), /proxy_cache_valid 200 5s;/);
  assert.match(f.read('http.d/generated-ssi-head-cache.conf'), /max_size=8m inactive=30m/);
});

test('invalid configuration is rejected before writing files', (t) => {
  const f = fixture(t);
  const invalid = {
    NGINX_SSI_HEAD_URL: ['ftp://api.example/head', 'http://user:password@api.example/head',
      'http://api.example/head#fragment', 'http://api.example/$host', 'http://api.example/"; return 200; #',
      'http://api.example/head\nserver { listen 1234; }'],
    NGINX_SSI_HEAD_CACHE_TTL: ['0', '-1h', '1h; return 200;', '1h\n1d'],
    NGINX_SSI_HEAD_CACHE_INACTIVE: ['0s', 'two hours', '2h\r\n1d'],
    NGINX_SSI_HEAD_CACHE_MAX_SIZE: ['0', '-1m', '100m; server {}', '100m\n1g'],
  };
  for (const [key, values] of Object.entries(invalid)) {
    for (const value of values) {
      assert.notEqual(f.configure({ NGINX_SSI_HEAD_URL: 'http://127.0.0.1/head', [key]: value }).status, 0, key);
      assert.equal(f.exists(''), false, key);
    }
  }
});
