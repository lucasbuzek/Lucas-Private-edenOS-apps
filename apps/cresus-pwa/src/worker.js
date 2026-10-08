import { verifyAccessJwt } from './auth.js';
import { generate } from './providers.js';
import { CRESUS_SYSTEM_PROMPT } from './prompt.js';
import { providerChoices, providerForUser, setProviderForUser, generateForProvider } from './provider-choice.js';

const HISTORY_TURNS = 12;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// The five canonical routes (12_COMMANDS.md). The user picks a depth; CRESUS still
// follows its own routing rules when intent is clearly different.
export const MODES = {
  simple: 'Requested depth: SIMPLE CRESUS. Use the Simple output shape from the canon.',
  expert: 'Requested depth: EXPERT (@cresus expert). Run the full Expert completion contract and end with a completion state: COMPLETE, PARTIALLY COMPARABLE or EXHAUSTED.',
  zacchaeus: 'Requested mode: ZACCHAEUS (@zacchaeus). Dividend/income collector; use the ZACCHAEUS calendar contract and distinguish declared from estimated.',
  strategy: 'Requested mode: STRATEGY LAB (@cresus strategy). Point-in-time strategy reasoning with bias checks.',
  council: 'Requested mode: THE GILDED ORDER (@cresus council). Apply the useful lenses; CRESUS synthesizes.',
};

const json = (data, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { 'content-type': 'application/json', 'cache-control': 'no-store' },
  });

const today = () => new Date().toISOString().slice(0, 10);

async function setting(env, key, fallback) {
  const row = await env.DB.prepare('SELECT value FROM settings WHERE key = ?').bind(key).first();
  return row ? row.value : fallback;
}

async function usageToday(env, email) {
  const row = await env.DB.prepare('SELECT count FROM usage WHERE email = ? AND day = ?')
    .bind(email, today()).first();
  return row ? row.count : 0;
}

// Who is calling, and are they allowed in?
async function resolveUser(request, env) {
  const email = await verifyAccessJwt(request, env);
  if (!email) return { error: json({ error: 'Not signed in' }, 401) };

  const owner = (env.OWNER_EMAIL || '').toLowerCase();
  if (email === owner) {
    await env.DB.prepare(
      `INSERT INTO users (email, role, status, added_by) VALUES (?, 'admin', 'active', 'owner')
       ON CONFLICT(email) DO UPDATE SET role='admin', status='active', last_seen=datetime('now')`
    ).bind(email).run();
    return { email, role: 'admin', owner: true };
  }

  const user = await env.DB.prepare('SELECT * FROM users WHERE email = ?').bind(email).first();
  if (!user || user.status !== 'active') {
    return { error: json({ error: 'This account has not been given access.', email }, 403) };
  }
  await env.DB.prepare("UPDATE users SET last_seen = datetime('now') WHERE email = ?").bind(email).run();
  return { email, role: user.role, owner: false };
}

// Optional: keep the Cloudflare Access group in step with the app's user list,
// so you only manage people in one place (the Admin screen).
async function syncAccessGroup(env) {
  if (!env.CF_API_TOKEN || !env.CF_ACCOUNT_ID || !env.ACCESS_GROUP_ID) return { synced: false };
  const url = `https://api.cloudflare.com/client/v4/accounts/${env.CF_ACCOUNT_ID}/access/groups/${env.ACCESS_GROUP_ID}`;
  const headers = { Authorization: `Bearer ${env.CF_API_TOKEN}`, 'content-type': 'application/json' };

  const current = await (await fetch(url, { headers })).json();
  if (!current.success) return { synced: false, error: 'Could not read Access group' };

  const { results } = await env.DB.prepare("SELECT email FROM users WHERE status = 'active'").all();
  const emails = new Set(results.map((r) => r.email));
  if (env.OWNER_EMAIL) emails.add(env.OWNER_EMAIL.toLowerCase());

  const res = await fetch(url, {
    method: 'PUT',
    headers,
    body: JSON.stringify({
      name: current.result.name,
      include: [...emails].map((email) => ({ email: { email } })),
    }),
  });
  const body = await res.json();
  return { synced: !!body.success, error: body.success ? undefined : 'Access group update failed' };
}

async function handleChat(request, env, user) {
  const { conversationId, clientId, message, mode = 'simple' } = await request.json();
  const text = String(message || '').trim();
  if (!text) return json({ error: 'Empty message' }, 400);
  if (text.length > 8000) return json({ error: 'Message too long (8,000 characters max)' }, 400);
  if (!UUID_RE.test(conversationId || '') || !UUID_RE.test(clientId || '')) {
    return json({ error: 'Bad request' }, 400);
  }
  if (!MODES[mode]) return json({ error: 'Unknown mode' }, 400);

  // The client creates conversation ids, so a retried "first message" can't fork a chat.
  const conv = await env.DB.prepare('SELECT email FROM conversations WHERE id = ?').bind(conversationId).first();
  if (conv && conv.email !== user.email) return json({ error: 'Conversation not found' }, 404);

  // Idempotent retry: the same clientId never runs the model twice.
  const prior = await env.DB.prepare(
    "SELECT id FROM messages WHERE conversation_id = ? AND client_id = ? AND role = 'user'"
  ).bind(conversationId, clientId).first();
  if (prior) {
    const answer = await env.DB.prepare(
      "SELECT content, mode FROM messages WHERE conversation_id = ? AND role = 'assistant' AND id > ? ORDER BY id LIMIT 1"
    ).bind(conversationId, prior.id).first();
    if (answer) return json({ conversationId, reply: answer.content, mode: answer.mode, replayed: true });
    return json({ error: 'Still working on this message — try again in a moment.', retryable: true }, 409);
  }

  // Daily per-person cap, so the free model allowance is shared fairly
  const limit = Number(await setting(env, 'daily_message_limit', '40'));
  if (!user.owner && (await usageToday(env, user.email)) >= limit) {
    return json({ error: `Daily limit of ${limit} messages reached. Resets at 02:00 SAST.` }, 429);
  }

  if (!conv) {
    await env.DB.prepare('INSERT INTO conversations (id, email, title) VALUES (?, ?, ?)')
      .bind(conversationId, user.email, text.slice(0, 60)).run();
  }

  await env.DB.prepare(
    'INSERT INTO messages (conversation_id, role, content, client_id, mode) VALUES (?, ?, ?, ?, ?)'
  ).bind(conversationId, 'user', text, clientId, mode).run();

  const { results } = await env.DB.prepare(
    'SELECT role, content FROM messages WHERE conversation_id = ? ORDER BY id DESC LIMIT ?'
  ).bind(conversationId, HISTORY_TURNS * 2).all();
  const history = results.reverse();

  let reply;
  try {
    reply = await generateForProvider(env, await providerForUser(env, user.email), `${CRESUS_SYSTEM_PROMPT}\n\n${MODES[mode]}`, history);
  } catch (err) {
    // Remove the unanswered message so a retry starts clean.
    await env.DB.prepare('DELETE FROM messages WHERE conversation_id = ? AND client_id = ?')
      .bind(conversationId, clientId).run();
    const msg = String(err?.message || err);
    const quota = /neuron|4006|daily|quota|limit/i.test(msg);
    return json({
      error: quota
        ? "Today's free AI allowance is used up. It resets at 02:00 SAST."
        : 'CRESUS could not answer right now.',
      retryable: !quota,
    }, 502);
  }

  await env.DB.batch([
    env.DB.prepare('INSERT INTO messages (conversation_id, role, content, mode) VALUES (?, ?, ?, ?)')
      .bind(conversationId, 'assistant', reply, mode),
    env.DB.prepare("UPDATE conversations SET updated_at = datetime('now') WHERE id = ?").bind(conversationId),
    env.DB.prepare(
      `INSERT INTO usage (email, day, count) VALUES (?, ?, 1)
       ON CONFLICT(email, day) DO UPDATE SET count = count + 1`
    ).bind(user.email, today()),
  ]);

  return json({ conversationId, reply, mode });
}

// "User data outlives software": everything a person wrote, as one Markdown file.
async function handleExport(env, user) {
  const { results: convs } = await env.DB.prepare(
    'SELECT id, title, created_at FROM conversations WHERE email = ? ORDER BY created_at'
  ).bind(user.email).all();
  let out = `# CRESUS export — ${user.email}\n\nExported ${new Date().toISOString()}\n`;
  for (const c of convs) {
    const { results: msgs } = await env.DB.prepare(
      'SELECT role, content, mode, created_at FROM messages WHERE conversation_id = ? ORDER BY id'
    ).bind(c.id).all();
    out += `\n\n---\n\n## ${c.title}\n\n_Started ${c.created_at} UTC_\n`;
    for (const m of msgs) {
      const who = m.role === 'user' ? 'You' : `CRESUS${m.mode && m.mode !== 'simple' ? ` · ${m.mode}` : ''}`;
      out += `\n**${who}** (${m.created_at} UTC)\n\n${m.content}\n`;
    }
  }
  return new Response(out, {
    headers: {
      'content-type': 'text/markdown; charset=utf-8',
      'content-disposition': `attachment; filename="cresus-export-${today()}.md"`,
      'cache-control': 'no-store',
    },
  });
}

async function handleAdmin(request, env, user, path) {
  if (user.role !== 'admin') return json({ error: 'Admins only' }, 403);

  if (request.method === 'GET' && path === '/api/admin/users') {
    const { results } = await env.DB.prepare(
      'SELECT email, role, status, created_at, last_seen FROM users ORDER BY created_at'
    ).all();
    return json({
      users: results,
      maxUsers: Number(await setting(env, 'max_users', '2')),
      dailyMessageLimit: Number(await setting(env, 'daily_message_limit', '40')),
      accessSync: !!env.CF_API_TOKEN,
    });
  }

  if (request.method === 'POST' && path === '/api/admin/users') {
    const body = await request.json();
    const email = String(body.email || '').trim().toLowerCase();
    if (!EMAIL_RE.test(email)) return json({ error: 'Enter a valid email address' }, 400);
    const role = body.role === 'admin' ? 'admin' : 'member';

    const maxUsers = Number(await setting(env, 'max_users', '2'));
    const { n } = await env.DB.prepare(
      "SELECT COUNT(*) AS n FROM users WHERE status = 'active' AND email != ?"
    ).bind(email).first();
    if (n >= maxUsers) return json({ error: `User limit reached (${maxUsers}). Raise it first.` }, 409);

    await env.DB.prepare(
      `INSERT INTO users (email, role, status, added_by) VALUES (?, ?, 'active', ?)
       ON CONFLICT(email) DO UPDATE SET role = excluded.role, status = 'active'`
    ).bind(email, role, user.email).run();
    return json({ ok: true, ...(await syncAccessGroup(env)) });
  }

  if (request.method === 'DELETE' && path.startsWith('/api/admin/users/')) {
    const email = decodeURIComponent(path.split('/').pop()).toLowerCase();
    if (email === (env.OWNER_EMAIL || '').toLowerCase()) {
      return json({ error: 'The owner cannot be removed' }, 400);
    }
    await env.DB.prepare("UPDATE users SET status = 'disabled' WHERE email = ?").bind(email).run();
    return json({ ok: true, ...(await syncAccessGroup(env)) });
  }

  if (request.method === 'PUT' && path === '/api/admin/settings') {
    if (!user.owner) return json({ error: 'Only the owner can change limits' }, 403);
    const body = await request.json();
    const updates = [];
    if (body.maxUsers !== undefined) {
      const v = Math.floor(Number(body.maxUsers));
      if (!(v >= 1 && v <= 50)) return json({ error: 'User limit must be 1–50 (free Access tier)' }, 400);
      updates.push(['max_users', String(v)]);
    }
    if (body.dailyMessageLimit !== undefined) {
      const v = Math.floor(Number(body.dailyMessageLimit));
      if (!(v >= 1 && v <= 1000)) return json({ error: 'Daily limit must be 1–1000' }, 400);
      updates.push(['daily_message_limit', String(v)]);
    }
    await env.DB.batch(updates.map(([k, v]) =>
      env.DB.prepare('INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value').bind(k, v)
    ));
    return json({ ok: true });
  }

  return json({ error: 'Not found' }, 404);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    if (!path.startsWith('/api/')) return env.ASSETS.fetch(request);

    const user = await resolveUser(request, env);
    if (user.error) return user.error;

    try {
      if (path === '/api/me') {
        return json({
          email: user.email, role: user.role, owner: user.owner,
          usedToday: await usageToday(env, user.email),
          dailyLimit: user.owner ? null : Number(await setting(env, 'daily_message_limit', '40')),
        });
      }
      if (path === '/api/intelligence' && request.method === 'GET') {
        return json({ provider: await providerForUser(env, user.email), choices: providerChoices(env) });
      }
      if (path === '/api/intelligence' && request.method === 'PUT') {
        const body = await request.json();
        return json(await setProviderForUser(env, user.email, body.provider));
      }
      if (path === '/api/chat' && request.method === 'POST') return handleChat(request, env, user);
      if (path === '/api/export' && request.method === 'GET') return handleExport(env, user);

      if (path === '/api/conversations' && request.method === 'GET') {
        const { results } = await env.DB.prepare(
          'SELECT id, title, updated_at FROM conversations WHERE email = ? ORDER BY updated_at DESC LIMIT 100'
        ).bind(user.email).all();
        return json({ conversations: results });
      }

      const convMatch = path.match(/^\/api\/conversations\/([\w-]+)$/);
      if (convMatch) {
        const id = convMatch[1];
        const conv = await env.DB.prepare('SELECT id FROM conversations WHERE id = ? AND email = ?')
          .bind(id, user.email).first();
        if (!conv) return json({ error: 'Not found' }, 404);
        if (request.method === 'DELETE') {
          await env.DB.batch([
            env.DB.prepare('DELETE FROM messages WHERE conversation_id = ?').bind(id),
            env.DB.prepare('DELETE FROM conversations WHERE id = ?').bind(id),
          ]);
          return json({ ok: true });
        }
        const { results } = await env.DB.prepare(
          'SELECT role, content, mode, created_at FROM messages WHERE conversation_id = ? ORDER BY id'
        ).bind(id).all();
        return json({ messages: results });
      }

      if (path.startsWith('/api/admin/')) return handleAdmin(request, env, user, path);

      return json({ error: 'Not found' }, 404);
    } catch (err) {
      return json({ error: 'Server error', retryable: true }, 500);
    }
  },
};
