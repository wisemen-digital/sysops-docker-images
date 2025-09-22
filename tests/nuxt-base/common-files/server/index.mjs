import http from 'http';

const server = http.createServer((req, res) => {
  if (req.url === '/env') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(process.env, null, 2));
  } else {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Hey from index.mjs');
  }
});

server.listen(3000, () => {
  console.log('Server running on http://localhost:3000');
});
