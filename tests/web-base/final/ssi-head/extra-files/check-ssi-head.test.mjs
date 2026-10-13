import assert from 'node:assert/strict';
import http from 'node:http';
import { test } from 'node:test';
import { setTimeout as delay } from 'node:timers/promises';

function request(domain, path = '/', headers = {}, port = 80) {
  return new Promise((resolve, reject) => {
    const req = http.get({ hostname: '127.0.0.1', port, path, headers: { Host: domain, ...headers } }, (res) => {
      let body = '';
      res.setEncoding('utf8');
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => resolve({ body, headers: res.headers, status: res.statusCode }));
      res.on('error', reject);
    });
    req.setTimeout(5000, () => req.destroy(new Error('Request timed out')));
    req.on('error', reject);
  });
}

const domain = (prefix) => `${prefix}-${process.pid}.example`;
const revision = ({ body }) => {
  const match = body.match(/<meta name="revision" content="([^"]+)"/);
  assert.ok(match, 'fragment has a revision');
  return match[1];
};
const count = async (host) => JSON.parse((await request('localhost', `/requests?domain=${host}`, {}, 18081)).body);

test('domains are isolated; index, deep links, and queries reuse one fragment', async () => {
  const a = domain('a');
  const b = domain('b');
  const first = await request(a);
  assert.ok(first.body.includes(`<title>${a}</title>`));
  assert.ok((await request(b)).body.includes(`<title>${b}</title>`));
  assert.equal(revision(await request(a, '/index.html')), revision(first));
  assert.equal(revision(await request(a, '/foo/bar?language=ignored')), revision(first));
  assert.equal(await count(a), 1);
});

test('caller credentials and spoofed hostnames are omitted', async () => {
  const host = domain('credentials');
  const response = await request(host, '/', { 'X-Forwarded-Host': 'spoofed.example',
    Cookie: 'browser-cookie', Authorization: 'Bearer browser-token' });
  assert.ok(response.body.includes(`<title>${host}</title>`));
  assert.ok(response.body.includes('content="||source=ssi"'));
});

test('conditional requests assemble HTML without static validators', async () => {
  const response = await request(domain('conditional'), '/', {
    'If-Modified-Since': 'Wed, 01 Jan 2031 00:00:00 GMT', 'If-None-Match': '*',
  });
  assert.equal(response.status, 200);
  assert.equal(response.headers.etag, undefined);
  assert.equal(response.headers['last-modified'], undefined);
});

test('concurrent cold requests share one upstream fill', async () => {
  const host = domain('concurrent');
  const responses = await Promise.all(Array.from({ length: 4 }, () => request(host)));
  assert.equal(new Set(responses.map(revision)).size, 1);
  assert.equal(await count(host), 1);
});

test('expired fragments are served while the upstream refreshes', async () => {
  const host = domain('refresh');
  const first = await request(host);
  await delay(2100);
  const started = performance.now();
  const stale = await request(host);
  assert.ok(performance.now() - started < 800, 'cached response does not wait for the one-second upstream');
  assert.equal(revision(stale), revision(first));
  for (let attempt = 0; attempt < 10; attempt += 1) {
    await delay(200);
    if (revision(await request(host)) !== revision(first)) return;
  }
  assert.fail('background refresh did not update the fragment');
});

test('upstream failures use the fallback without caching error bodies', async () => {
  for (const prefix of ['error', 'redirect', 'disconnect']) {
    const host = domain(prefix);
    for (let attempt = 0; attempt < 2; attempt += 1) {
      const response = await request(host);
      assert.equal(response.status, 200);
      assert.ok(response.body.includes('<title>Fallback website</title>'));
      assert.ok(!response.body.includes('upstream-error-body'));
    }
    assert.equal(await count(host), 2);
  }
});
