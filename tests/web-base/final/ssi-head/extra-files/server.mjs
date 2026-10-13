import http from 'node:http';

const requests = new Map();

http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost');
  if (url.pathname === '/requests') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify(requests.get(url.searchParams.get('domain')) ?? 0));
  }
  if (url.pathname !== '/head') {
    res.writeHead(404);
    return res.end();
  }

  const domain = req.headers['x-forwarded-host'] ?? '';
  const revision = (requests.get(domain) ?? 0) + 1;
  requests.set(domain, revision);
  if (domain.startsWith('disconnect-')) return req.socket.destroy();
  if (/^(error|redirect)-/.test(domain)) {
    res.writeHead(domain.startsWith('error-') ? 503 : 302, { Location: '/unavailable' });
    return res.end('upstream-error-body');
  }

  const respond = () => {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(`<title>${domain}</title><meta name="revision" content="${revision}" />`
      + `<meta name="request" content="${req.headers.cookie ?? ''}|${req.headers.authorization ?? ''}|${url.searchParams}" />`);
  };
  if (/^(refresh|concurrent)-/.test(domain)) setTimeout(respond, 1000);
  else respond();
}).listen(18081, '127.0.0.1');
