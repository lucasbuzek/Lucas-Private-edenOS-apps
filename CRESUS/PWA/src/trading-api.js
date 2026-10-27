// Isolated, authenticated CRESUS trading extension; no live execution endpoint.
import { validatePaperDraft, assessPaperTrigger } from './trading-core.js';
const json = (body, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { 'content-type': 'application/json', 'cache-control': 'no-store' },
});
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export async function handleTradingApi(request, env, user, path) {
  if (!user?.email) return json({ error: 'Authentication required' }, 401);
  if (path === '/api/trading/status' && request.method === 'GET')
    return json({ guided: 'PAPER_CANDIDATE', automated: 'SIMULATION_ONLY', live: 'DISABLED',
      brokerConnected: false, schedulerRunning: false, quoteProviderConnected: false });
  if (path === '/api/trading/preview' && request.method === 'POST') {
    try { return json({ draft: validatePaperDraft(await request.json()) }); }
    catch (e) { return json({ error: String(e.message) }, 422); }
  }
  if (path === '/api/trading/automation/check' && request.method === 'POST') {
    try {
      const body = await request.json();
      return json({ evaluation: assessPaperTrigger(body.rule, body.quote),
        effect: 'NO_ORDER_CREATED', schedulerRunning: false });
    } catch (e) { return json({ error: String(e.message) }, 422); }
  }
  if (path === '/api/trading/paper' && request.method === 'GET') {
    const data = await env.DB.prepare(
      'SELECT id, payload_json, created_at FROM trading_paper_orders WHERE email = ? ORDER BY created_at DESC LIMIT 50'
    ).bind(user.email).all();
    return json({ orders: data.results.map(r => ({
      id: r.id, createdAt: r.created_at, ...JSON.parse(r.payload_json),
    })) });
  }
  if (path === '/api/trading/paper' && request.method === 'POST') {
    const body = await request.json();
    if (body.confirm !== 'PAPER_ONLY' || !UUID.test(String(body.idempotencyKey || '')))
      return json({ error: 'Explicit paper confirmation and a UUID idempotency key are required.' }, 422);
    let draft;
    try { draft = validatePaperDraft(body.order); }
    catch (e) { return json({ error: String(e.message) }, 422); }
    const id = body.idempotencyKey.toLowerCase();
    // D1 uniqueness: no duplicated paper order after an interrupted retry.
    await env.DB.prepare('INSERT OR IGNORE INTO trading_paper_orders (id,email,payload_json) VALUES (?,?,?)')
      .bind(id, user.email, JSON.stringify(draft)).run();
    const row = await env.DB.prepare(
      'SELECT email, payload_json, created_at FROM trading_paper_orders WHERE id = ?'
    ).bind(id).first();
    if (!row || row.email !== user.email) return json({ error: 'Idempotency key belongs to another account.' }, 409);
    return json({ id, createdAt: row.created_at, ...JSON.parse(row.payload_json),
      status: 'PAPER_RECORDED_NOT_FILLED', liveSubmitted: false }, 201);
  }
  return json({ error: 'Trading endpoint not found.' }, 404);
}
