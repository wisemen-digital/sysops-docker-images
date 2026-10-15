import http from 'node:http';

http.createServer((req, res) => {
  const domain = req.headers['x-forwarded-host'] ?? 'Website';
  if (domain === 'unavailable.example') {
    res.writeHead(503);
    return res.end('Unavailable');
  }

  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end(`<title>${domain}</title>`);
}).listen(18081, '127.0.0.1');
