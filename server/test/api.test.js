import { test, describe } from 'node:test';
import assert from 'node:assert';
import app from '../src/app.js';
import http from 'node:http';

describe('Express API Server Tests', () => {
  let server;
  let baseUrl;

  test('setup server listener', async () => {
    await new Promise((resolve) => {
      server = http.createServer(app);
      server.listen(0, () => {
        const port = server.address().port;
        baseUrl = `http://localhost:${port}/api/v1`;
        resolve();
      });
    });
  });

  test('GET /api/v1/health returns ok', async () => {
    const res = await fetch(`${baseUrl}/health`);
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.status, 'ok');
    assert.strictEqual(body.service, 'SportSphere API');
  });

  test('GET /api/v1/scores returns scoreboard data', async () => {
    const res = await fetch(`${baseUrl}/scores?league=soccer/eng.1`);
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.success, true);
    assert.ok(body.data);
  });

  test('GET /api/v1/scores/live returns live scores list', async () => {
    const res = await fetch(`${baseUrl}/scores/live`);
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.success, true);
    assert.ok(Array.isArray(body.data));
  });

  test('GET /api/v1/news returns news articles', async () => {
    const res = await fetch(`${baseUrl}/news?league=soccer/eng.1`);
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.success, true);
    assert.ok(Array.isArray(body.articles));
  });

  test('GET /api/v1/scores with shorthand eng.1 returns scoreboard data', async () => {
    const res = await fetch(`${baseUrl}/scores?league=eng.1`);
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.success, true);
    assert.strictEqual(body.league, 'soccer/eng.1');
    assert.ok(body.data);
  });

  test('GET /api/v1/news with shorthand eng.1 returns news articles', async () => {
    const res = await fetch(`${baseUrl}/news?league=eng.1`);
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.success, true);
    assert.strictEqual(body.league, 'soccer/eng.1');
    assert.ok(Array.isArray(body.articles));
  });

  test('GET /api/v1/favorites without auth returns 401 Unauthorized', async () => {
    const res = await fetch(`${baseUrl}/favorites`);
    assert.strictEqual(res.status, 401);
    const body = await res.json();
    assert.strictEqual(body.error, 'Unauthorized');
  });

  test('teardown server', async () => {
    await new Promise((resolve) => server.close(resolve));
  });
});
