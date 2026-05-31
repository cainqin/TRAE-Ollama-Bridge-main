const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const PORT = 35791;
const BASE = `http://127.0.0.1:${PORT}`;
const MODELS_FILE = path.join(__dirname, 'data', 'models.json');

let server;
let exitCode = 0;

function assert(condition, msg) {
  if (!condition) {
    console.error(`FAIL: ${msg}`);
    exitCode = 1;
  } else {
    console.log(`PASS: ${msg}`);
  }
}

function saveOriginalMappings() {
  let original = '{"mappings":[]}';
  try {
    if (fs.existsSync(MODELS_FILE)) {
      original = fs.readFileSync(MODELS_FILE, 'utf8');
    }
  } catch {}
  return original;
}

function restoreOriginalMappings(original) {
  try {
    fs.writeFileSync(MODELS_FILE, original);
  } catch {}
}

function resetMappings() {
  fs.writeFileSync(MODELS_FILE, '{"mappings":[]}');
}

async function waitForServer(url, timeoutMs = 10000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      await new Promise((resolve, reject) => {
        const req = http.get(url, (res) => {
          let data = '';
          res.on('data', chunk => data += chunk);
          res.on('end', () => resolve(data));
        });
        req.on('error', reject);
        req.setTimeout(1000, () => { req.destroy(); reject(new Error('timeout')); });
      });
      return true;
    } catch {
      await new Promise(r => setTimeout(r, 300));
    }
  }
  return false;
}

function httpRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const opts = {
      hostname: u.hostname,
      port: u.port,
      path: u.pathname,
      method: options.method || 'GET',
      headers: options.headers || { 'Content-Type': 'application/json' },
    };
    const req = http.request(opts, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        resolve({ status: res.statusCode, body: data });
      });
    });
    req.on('error', reject);
    if (options.body) req.write(options.body);
    req.end();
  });
}

async function fetchJSON(url, options = {}) {
  const res = await httpRequest(url, options);
  if (res.status >= 400) throw new Error(`HTTP ${res.status}: ${res.body}`);
  return JSON.parse(res.body);
}

async function main() {
  const originalMappings = saveOriginalMappings();
  resetMappings();

  console.log('Starting server for smoke test...');

  const env = Object.assign({}, process.env, {
    PORT: String(PORT),
    OLLAMA_BASE_URL: 'http://127.0.0.1:11434',
    ACCEPT_ANY_API_KEY: 'true',
    EXPECTED_API_KEY: '',
    STRIP_THINK_TAGS: 'false',
    HTTPS_ENABLED: 'false',
  });

  server = spawn('node', [path.join(__dirname, 'server.js')], {
    env,
    stdio: ['ignore', 'pipe', 'pipe'],
    cwd: __dirname,
  });

  server.stdout.on('data', d => process.stdout.write(`[server] ${d}`));
  server.stderr.on('data', d => process.stderr.write(`[server:err] ${d}`));

  const ready = await waitForServer(`${BASE}/health`);
  assert(ready, 'Server should start and respond to /health');

  if (!ready) {
    server.kill();
    restoreOriginalMappings(originalMappings);
    process.exit(1);
  }

  // Test /health
  const health = await fetchJSON(`${BASE}/health`);
  assert(health && health.ok === true, '/health should return { ok: true }');

  // Test /bridge/models (empty mappings)
  const models = await fetchJSON(`${BASE}/bridge/models`);
  assert(models && Array.isArray(models.mappings), '/bridge/models should return { mappings: [] }');
  assert(models.mappings.length === 0, 'Should start with 0 mappings');

  // Test creating a mapping
  const created = await fetchJSON(`${BASE}/bridge/models`, {
    method: 'POST',
    body: JSON.stringify({ id: 'test-model', model: 'test-local' }),
  });
  assert(created && created.ok === true, 'POST /bridge/models should create mapping');
  assert(created.mapping.id === 'test-model', 'Response should include mapping id');
  assert(created.mapping.model === 'test-local', 'Response should include mapping model');

  // Test listing mappings after creation
  const afterCreate = await fetchJSON(`${BASE}/bridge/models`);
  assert(afterCreate.mappings.length === 1, 'Should have 1 mapping after creation');
  assert(afterCreate.mappings[0].id === 'test-model', 'Mapping id should match');
  assert(afterCreate.mappings[0].model === 'test-local', 'Mapping model should match');

  // Test /v1/models
  const v1models = await fetchJSON(`${BASE}/v1/models`);
  assert(v1models && v1models.object === 'list', '/v1/models should return object list');
  assert(v1models.data.length === 1, '/v1/models should list 1 model');
  assert(v1models.data[0].id === 'test-model', '/v1/models should contain test-model');

  // Test deleting mapping
  const del = await fetchJSON(`${BASE}/bridge/models/test-model`, { method: 'DELETE' });
  assert(del && del.ok === true, 'DELETE /bridge/models/:id should succeed');

  const afterDelete = await fetchJSON(`${BASE}/bridge/models`);
  assert(afterDelete.mappings.length === 0, 'Should have 0 mappings after deletion');

  // Test 404
  const notFound = await httpRequest(`${BASE}/nonexistent`);
  assert(notFound.status === 404, 'GET /nonexistent should return 404 status');

  console.log(`\n${exitCode === 0 ? 'All tests passed!' : 'Some tests failed.'}`);
  server.kill();
  restoreOriginalMappings(originalMappings);
  process.exit(exitCode);
}

main().catch((err) => {
  console.error('Test error:', err);
  if (server) server.kill();
  restoreOriginalMappings(originalMappings);
  process.exit(1);
});
