const http = require('http');
const { URL } = require('url');

const PORT = process.env.PORT || 3000;

const tasks = [
  { id: 1, title: 'Provision dev environment', status: 'done' },
  { id: 2, title: 'Deploy simple Node app', status: 'in-progress' },
  { id: 3, title: 'Write Terraform plan', status: 'pending' }
];
let nextId = tasks.length + 1;

const sendJson = (res, statusCode, payload) => {
  res.writeHead(statusCode, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(payload));
};

const parseBody = (req) =>
  new Promise((resolve, reject) => {
    let body = '';
    req.on('data', (chunk) => {
      body += chunk.toString();
      if (body.length > 1e6) {
        req.connection.destroy();
        reject(new Error('Payload too large'));
      }
    });
    req.on('end', () => {
      if (!body) return resolve({});
      try {
        resolve(JSON.parse(body));
      } catch (err) {
        reject(err);
      }
    });
    req.on('error', reject);
  });

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  res.setHeader('X-App-Name', 'practice-node-app');

  if (req.method === 'GET' && url.pathname === '/') {
    return sendJson(res, 200, {
      message: 'Simple Node.js API running',
      routes: ['GET /health', 'GET /tasks', 'GET /tasks/:id', 'POST /tasks'],
    });
  }

  if (req.method === 'GET' && url.pathname === '/health') {
    return sendJson(res, 200, { status: 'ok', timestamp: new Date().toISOString() });
  }

  if (req.method === 'GET' && url.pathname === '/tasks') {
    return sendJson(res, 200, tasks);
  }

  if (req.method === 'GET' && url.pathname.startsWith('/tasks/')) {
    const id = Number(url.pathname.split('/')[2]);
    const task = tasks.find((t) => t.id === id);
    if (!task) return sendJson(res, 404, { error: 'Task not found' });
    return sendJson(res, 200, task);
  }

  if (req.method === 'POST' && url.pathname === '/tasks') {
    try {
      const body = await parseBody(req);
      if (!body.title) {
        return sendJson(res, 400, { error: 'title is required' });
      }
      const newTask = {
        id: nextId++,
        title: body.title,
        status: body.status || 'pending',
      };
      tasks.push(newTask);
      return sendJson(res, 201, newTask);
    } catch (err) {
      return sendJson(res, 400, { error: err.message || 'Invalid JSON body' });
    }
  }

  return sendJson(res, 404, { error: 'Route not found' });
});

if (require.main === module) {
  server.listen(PORT, () => {
    console.log(`Server listening on http://localhost:${PORT}`);
  });
}

module.exports = server;
