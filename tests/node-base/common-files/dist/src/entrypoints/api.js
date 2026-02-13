import http from 'http';

const server = http.createServer((req, res) => {
  if (req.url === '/env') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(process.env, null, 2));
  } else if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': 86400
    });
    res.end();
  } else {
    res.writeHead(200, {
      'Access-Control-Allow-Origin': '*',
      'Content-Type': 'text/plain',
      'Referrer-Policy': 'no-referrer',
      'Strict-Transport-Security': 'max-age=63072000; includeSubDomains; preload',
      'X-Content-Type-Options': 'nosniff',
      'X-Robots-Tag': 'none'
    });
    res.end('Hey from api.js');
  }
});

server.listen(3000, () => {
  console.log('Server running on http://localhost:3000');
});
