const $ = (id) => document.getElementById(id);
const MAX_ATTEMPTS = 5;

// The five canonical routes (01_CRESUS_CANON, 02_OPERATING_MODES, 12_COMMANDS).
const MODES = {
  simple: {
    label: 'Simple', title: 'Simple CRESUS',
    desc: 'Concise conclusion, key numbers, positives, risks and evidence state. Same truth as Expert.',
    starters: ['Compare two dividend payers for income and valuation', 'What should I check before buying an ETF?', 'Explain dividend cover in plain terms'],
  },
  expert: {
    label: 'Expert', title: 'Expert examination',
    desc: 'A completion contract, not a longer answer: evidence matrix, retries, deterministic calculations, then COMPLETE, PARTIALLY COMPARABLE or EXHAUSTED.',
    starters: ['Examine a company as of today and finish the evidence matrix', 'Compare three banks on earnings, valuation and income'],
  },
  zacchaeus: {
    label: 'ZACCHAEUS', title: 'ZACCHAEUS — income collector',
    desc: 'Dividend and income calendar. Declared amounts are kept apart from estimates.',
    starters: ['Show upcoming declared income and distinguish estimates', 'Build an income calendar for my holdings'],
  },
  strategy: {
    label: 'Strategy Lab', title: 'Strategy Lab',
    desc: 'Point-in-time strategy reasoning with bias checks and stated assumptions.',
    starters: ['Test a dividend-growth screen from 2015–2025 with point-in-time safeguards', 'What biases could break a momentum backtest?'],
  },
  council: {
    label: 'Gilded Order', title: 'The Gilded Order',
    desc: 'Crassus, Gobseck, Scrooge, Cassandra and Sibyl challenge the case. CRESUS synthesizes.',
    starters: ['Challenge my thesis on a company', 'Run the Gilded Order on a high-yield share'],
  },
};

const store = {
  get(k, d) { try { return localStorage.getItem(k) ?? d; } catch { return d; } },
  set(k, v) { try { localStorage.setItem(k, v); } catch { /* private mode */ } },
};

const state = {
  me: null,
  presentation: store.get('cresus.presentation','standard') === 'expert' ? 'expert' : 'standard',
  convId: null,
  convTitle: '',
  busy: false,
  mode: MODES[store.get('cresus.mode', 'simple')] ? store.get('cresus.mode', 'simple') : 'simple',
};

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const uuid = () => crypto.randomUUID();

async function api(path, opts = {}) {
  const res = await fetch(path, {
    ...opts,
    headers: { 'content-type': 'application/json', ...(opts.headers || {}) },
    credentials: 'same-origin',
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw Object.assign(new Error(data.error || `Error ${res.status}`), {
      status: res.status, data, retryable: data.retryable === true || res.status >= 500,
    });
  }
  return data;
}

// ---------- Markdown → safe HTML (escape first, then format) ----------
const esc = (s) => s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

const FACT_LABELS = ['FACT', 'CALCULATION', 'INFERENCE', 'SCENARIO', 'UNCERTAINTY', 'MISSING'];
function inline(s) {
  let out = s
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/(^|[^*])\*([^*\s][^*]*)\*/g, '$1<em>$2</em>')
    .replace(/\[([^\]]+)\]\((https:\/\/[^)\s]+)\)/g, '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>');
  // Fact labels at the start of a line: "FACT: ..." / "**FACT:** ..."
  out = out.replace(new RegExp(`^(?:<strong>)?(${FACT_LABELS.join('|')}):(?:</strong>)?\\s*`), (_, l) =>
    `<span class="label l-${l.toLowerCase()}">${l}</span>`);
  // Completion and evidence states
  out = out
    .replace(/\bPARTIALLY COMPARABLE\b/g, '<span class="state s-partial">PARTIALLY COMPARABLE</span>')
    .replace(/\bCOMPLETE\b/g, '<span class="state s-complete">COMPLETE</span>')
    .replace(/\bEXHAUSTED\b/g, '<span class="state s-exhausted">EXHAUSTED</span>')
    .replace(/\bSTALE\b/g, '<span class="state s-stale">STALE</span>')
    .replace(/\bUNVERIFIED\b/g, '<span class="state s-unverified">UNVERIFIED</span>')
    .replace(/\bESTIMATE[SD]?\b/g, (m) => `<span class="state s-estimate">${m}</span>`);
  return out;
}

const isRow = (l) => /^\s*\|.*\|\s*$/.test(l);
const isSep = (l) => /^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?\s*$/.test(l);
const cells = (l) => l.trim().replace(/^\||\|$/g, '').split('|').map((c) => c.trim());
const numeric = (c) => /^[-+−]?[R$€£¥]?\s?[\d.,]+\s?(%|x|bn|m|k)?$/i.test(c.replace(/<[^>]+>/g, ''));

function md(src) {
  const parts = esc(src).split(/```/);
  return parts.map((block, i) => {
    if (i % 2) return `<pre><code>${block.replace(/^\w*\n/, '')}</code></pre>`;
    const lines = block.split('\n');
    let html = '';
    let list = null;
    const close = () => { if (list) { html += `</${list}>`; list = null; } };
    for (let j = 0; j < lines.length; j++) {
      const raw = lines[j];
      if (isRow(raw) && j + 1 < lines.length && isSep(lines[j + 1])) {
        close();
        const head = cells(raw);
        j += 2;
        const rows = [];
        while (j < lines.length && isRow(lines[j])) rows.push(cells(lines[j++]));
        j--;
        html += '<div class="table-wrap"><table><thead><tr>' +
          head.map((h) => `<th scope="col">${inline(h)}</th>`).join('') + '</tr></thead><tbody>' +
          rows.map((r) => '<tr>' + r.map((c) => `<td${numeric(c) ? ' class="num"' : ''}>${inline(c)}</td>`).join('') + '</tr>').join('') +
          '</tbody></table></div>';
        continue;
      }
      let m;
      if ((m = raw.match(/^\s*[-*•]\s+(.*)/))) { if (list !== 'ul') { close(); html += '<ul>'; list = 'ul'; } html += `<li>${inline(m[1])}</li>`; }
      else if ((m = raw.match(/^\s*\d+[.)]\s+(.*)/))) { if (list !== 'ol') { close(); html += '<ol>'; list = 'ol'; } html += `<li>${inline(m[1])}</li>`; }
      else if ((m = raw.match(/^(#{1,4})\s+(.*)/))) { close(); const n = Math.min(m[1].length + 1, 4); html += `<h${n}>${inline(m[2])}</h${n}>`; }
      else if ((m = raw.match(/^&gt;\s?(.*)/))) { close(); html += `<blockquote>${inline(m[1])}</blockquote>`; }
      else if (/^\s*(-{3,}|\*{3,})\s*$/.test(raw)) { close(); html += '<hr>'; }
      else if (raw.trim() === '') { close(); }
      else { close(); html += `<p>${inline(raw)}</p>`; }
    }
    close();
    return html;
  }).join('');
}

// ---------- Rendering ----------
const SEAL = '<svg class="seal" aria-hidden="true"><use href="#seal"/></svg>';

function scrollDown() { $('chat').scrollTop = $('chat').scrollHeight; }

function addUser(text, mode) {
  $('empty').hidden = true;
  const el = document.createElement('div');
  el.className = 'msg user';
  if (mode && mode !== 'simple') {
    const tag = document.createElement('span');
    tag.className = 'mode-tag';
    tag.textContent = MODES[mode]?.label ?? mode;
    el.appendChild(tag);
  }
  el.appendChild(document.createTextNode(text));
  $('messages').appendChild(el);
  scrollDown();
}

function cresusShell(mode) {
  $('empty').hidden = true;
  const el = document.createElement('div');
  el.className = 'msg cresus';
  const tag = mode && mode !== 'simple' ? `<span class="mode-tag">· ${esc(MODES[mode]?.label ?? mode)}</span>` : '';
  el.innerHTML = `<div class="folio-head">${SEAL}<span class="folio-name">CRESUS</span>${tag}</div><div class="body"></div>`;
  $('messages').appendChild(el);
  scrollDown();
  return el.querySelector('.body');
}

function addCresus(content, mode) {
  const body = cresusShell(mode);
  body.className = 'body prose';
  body.innerHTML = md(content);
  scrollDown();
}

function setTitle(t) {
  state.convTitle = t || '';
  $('convTitle').textContent = state.convTitle;
}

// ---------- Modes ----------
function renderModes() {
  const wrap = $('modes');
  wrap.innerHTML = '';
  for (const [key, m] of Object.entries(MODES)) {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'mode';
    b.textContent = m.label;
    b.setAttribute('aria-pressed', String(key === state.mode));
    b.onclick = () => { state.mode = key; store.set('cresus.mode', key); renderModes(); };
    wrap.appendChild(b);
  }
  const m = MODES[state.mode];
  $('modeCard').innerHTML = `<h2>${esc(m.title)}</h2><p>${esc(m.desc)}</p>`;
  const st = $('starters');
  st.innerHTML = '';
  for (const s of m.starters) {
    const b = document.createElement('button');
    b.className = 'starter';
    b.textContent = s;
    b.onclick = () => { $('input').value = s; $('input').focus(); autosize(); };
    st.appendChild(b);
  }
  $('input').placeholder = state.mode === 'simple' ? 'Ask CRESUS…' : `Ask CRESUS · ${m.label}…`;
}

// ---------- Sending, with safe automatic retry ----------
async function send(text) {
  text = text.trim();
  if (state.busy || !text) return;
  if (!navigator.onLine) { showNet(); return; }
  state.busy = true;
  updateSendState();

  const mode = state.mode;
  if (!state.convId) { state.convId = uuid(); setTitle(text.slice(0, 60)); }
  const payload = { conversationId: state.convId, clientId: uuid(), message: text, mode };
  addUser(text, mode);
  await deliver(payload, cresusShell(mode));

  state.busy = false;
  updateSendState();
}

async function deliver(payload, body) {
  body.className = 'body';
  body.innerHTML = '<div class="thinking"><span class="dots"><span></span><span></span><span></span></span><span class="what">Researching…</span></div>';
  const what = body.querySelector('.what');

  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    try {
      const data = await api('/api/chat', { method: 'POST', body: JSON.stringify(payload) });
      body.className = 'body prose';
      body.innerHTML = md(data.reply);
      scrollDown();
      loadConversations();
      refreshQuota();
      return;
    } catch (e) {
      const network = !e.status;
      const canRetry = network || e.retryable;
      if (!canRetry || attempt === MAX_ATTEMPTS) { showError(body, e, payload); return; }
      const wait = Math.min(1000 * 2 ** (attempt - 1), 8000);
      what.textContent = network ? `Connection lost — retrying (${attempt + 1} of ${MAX_ATTEMPTS})…` : `Retrying (${attempt + 1} of ${MAX_ATTEMPTS})…`;
      await sleep(wait);
      if (!navigator.onLine) await waitForOnline();
    }
  }
}

function showError(body, e, payload) {
  body.className = 'body';
  const msg = !e.status ? 'Could not reach CRESUS after several attempts.' : e.message;
  body.innerHTML = `<div class="err"><p>${esc(msg)}</p></div>`;
  if (!e.status || e.retryable) {
    const b = document.createElement('button');
    b.className = 'btn';
    b.textContent = 'Try again';
    b.onclick = async () => {
      if (state.busy) return;
      state.busy = true; updateSendState();
      await deliver(payload, body); // same clientId → never answered twice
      state.busy = false; updateSendState();
    };
    body.querySelector('.err').appendChild(b);
  }
  scrollDown();
}

function waitForOnline() {
  return new Promise((r) => {
    if (navigator.onLine) return r();
    window.addEventListener('online', () => r(), { once: true });
  });
}

// ---------- Connection state ----------
function showNet() { $('netState').hidden = navigator.onLine; updateSendState(); }
function updateSendState() { $('sendBtn').disabled = state.busy || !navigator.onLine; }
window.addEventListener('online', showNet);
window.addEventListener('offline', showNet);

// ---------- Drawer & conversations ----------
const mobile = () => matchMedia('(max-width: 959px)').matches;
function openDrawer(open) {
  $('drawer').classList.toggle('open', open);
  $('scrim').hidden = !open;
}
function markActive() {
  document.querySelectorAll('.conv').forEach((el) => el.classList.toggle('active', el.dataset.id === state.convId));
}
function resetChat() {
  state.convId = null;
  setTitle('');
  $('messages').innerHTML = '';
  $('empty').hidden = false;
  markActive();
  if (mobile()) openDrawer(false);
  $('input').focus();
}

async function loadConversations() {
  let conversations;
  try { ({ conversations } = await api('/api/conversations')); } catch { return; }
  const list = $('convList');
  list.innerHTML = '';
  if (!conversations.length) {
    list.innerHTML = '<div class="conv-empty">No inquiries yet.</div>';
    return;
  }
  for (const c of conversations) {
    const el = document.createElement('div');
    el.className = 'conv';
    el.dataset.id = c.id;
    const title = document.createElement('button');
    title.className = 'title';
    title.textContent = c.title;
    title.onclick = () => openConversation(c.id, c.title);
    const del = document.createElement('button');
    del.className = 'del';
    del.setAttribute('aria-label', `Delete “${c.title}”`);
    del.innerHTML = '<svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true"><path d="M5 7h14M10 11v6M14 11v6M7 7l1 12h8l1-12M9 7V4h6v3" stroke="currentColor" stroke-width="1.6" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>';
    del.onclick = async () => {
      const ok = await confirmAction('Delete this inquiry?', `“${c.title}” and all its messages will be removed. Export first if you want a copy.`, 'Delete');
      if (!ok) return;
      await api(`/api/conversations/${c.id}`, { method: 'DELETE' });
      if (state.convId === c.id) resetChat();
      loadConversations();
    };
    el.append(title, del);
    list.appendChild(el);
  }
  markActive();
}

async function openConversation(id, title) {
  const { messages } = await api(`/api/conversations/${id}`);
  state.convId = id;
  setTitle(title);
  $('messages').innerHTML = '';
  for (const m of messages) m.role === 'user' ? addUser(m.content, m.mode) : addCresus(m.content, m.mode);
  if (!messages.length) $('empty').hidden = false;
  markActive();
  if (mobile()) openDrawer(false);
}

async function refreshQuota() {
  try {
    const me = await api('/api/me');
    $('quota').textContent = me.dailyLimit == null
      ? (me.developmentAlpha ? `${me.usedToday} sent today · DEVELOPMENT_ALPHA (CRESUS cap off; provider limits apply)` : `${me.usedToday} sent today · owner (no daily cap)`)
      : `${Math.max(me.dailyLimit - me.usedToday, 0)} of ${me.dailyLimit} messages left today`;
  } catch { /* keep last value */ }
}

// ---------- Export (user owns their data) ----------
async function exportChats() {
  const res = await fetch('/api/export', { credentials: 'same-origin' });
  if (!res.ok) return;
  const blob = await res.blob();
  const name = `cresus-export-${new Date().toISOString().slice(0, 10)}.md`;
  const file = new File([blob], name, { type: 'text/markdown' });
  // On iPhone/Android this opens the share sheet (Save to Files, Notes, Mail…).
  if (navigator.canShare?.({ files: [file] })) {
    try { await navigator.share({ files: [file], title: 'CRESUS export' }); return; } catch { /* cancelled */ return; }
  }
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = name;
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}

// ---------- Confirm consequence ----------
function confirmAction(title, body, yesLabel = 'Confirm') {
  return new Promise((resolve) => {
    $('confirmTitle').textContent = title;
    $('confirmBody').textContent = body;
    $('confirmYes').textContent = yesLabel;
    const dlg = $('confirmDlg');
    const done = (v) => { dlg.close(); resolve(v); };
    $('confirmYes').onclick = () => done(true);
    $('confirmNo').onclick = () => done(false);
    dlg.oncancel = () => resolve(false);
    dlg.showModal();
  });
}

// ---------- Admin ----------
function adminMsg(text, kind = '') {
  $('adminMsg').textContent = text;
  $('adminMsg').className = `notice ${kind}`;
}
async function loadAdmin() {
  const d = await api('/api/admin/users');
  $('maxUsers').value = d.maxUsers ?? '';
  $('dailyLimit').value = d.dailyMessageLimit ?? '';
  const owner = state.me.owner;
  $('maxUsers').disabled = $('dailyLimit').disabled = $('saveLimits').disabled = !owner || !!d.developmentAlpha;
  const active = d.users.filter((u) => u.status === 'active');
  $('seatInfo').textContent = d.developmentAlpha
    ? `${active.length} accounts · DEVELOPMENT_ALPHA: CRESUS user/message caps disabled (external Access and provider limits remain).`
    : `${active.length} of ${d.maxUsers} seats in use${owner ? '' : ' · only the owner can change limits'}.`;
  $('syncNote').textContent = d.accessSync
    ? 'Changes here also update the Cloudflare Access sign-in list.'
    : 'Access sync is off: also add or remove the person in the Cloudflare Access group.';
  const ul = $('userList');
  ul.innerHTML = '';
  for (const u of d.users) {
    const li = document.createElement('li');
    const em = document.createElement('span');
    em.className = 'em';
    em.textContent = u.email;
    const tag = document.createElement('span');
    tag.className = `tag ${u.status === 'active' ? u.role : 'removed'}`;
    tag.textContent = u.status === 'active' ? u.role : 'removed';
    li.append(em, tag);
    if (u.status === 'active' && u.email !== state.me.email) {
      const rm = document.createElement('button');
      rm.className = 'rm';
      rm.textContent = 'Remove';
      rm.onclick = async () => {
        const ok = await confirmAction(`Remove ${u.email}?`, 'They will lose access immediately. Their chats are kept and return if you add them again.', 'Remove');
        if (!ok) return;
        try { await api(`/api/admin/users/${encodeURIComponent(u.email)}`, { method: 'DELETE' }); adminMsg('Removed.', 'good'); loadAdmin(); }
        catch (e) { adminMsg(e.message, 'bad'); }
      };
      li.append(rm);
    }
    ul.appendChild(li);
  }
}

// ---------- Persistent workspace rail ----------
const WORKSPACES = {
  overview: { mode: 'simple', prompt: 'Show my CRESUS overview. Summarize only context and data actually available; do not invent account state.' },
  research: { mode: 'expert', prompt: 'Open CRESUS Research. Start evidence-first security/company research. Ask for the security or question if missing, and distinguish known, unknown and conflicting evidence.' },
  watchlist: { mode: 'simple', prompt: 'Open my CRESUS Watchlist workflow. Use only securities supplied by me or available in authorized context. If none exist, ask which securities to add. Do not claim durable watchlist storage unless verified.' },
  portfolio: { mode: 'simple', prompt: 'Open my CRESUS Portfolio workflow. Use only holdings and transactions I have actually supplied or authorized. If none are available, ask for the data. Do not invent positions or claim brokerage connectivity.' },
  income: { mode: 'zacchaeus', prompt: 'Open ZACCHAEUS — dividend and investment income. Separate realized, declared, forward-indicated and estimated income; do not conflate their evidence states.' },
  strategy: { mode: 'strategy', prompt: 'Open CRESUS Strategy Lab. Establish the strategy, universe, period and data requirements, then specify point-in-time and bias safeguards. Do not claim a backtest ran unless it actually did.' },
  evidence: { mode: 'expert', prompt: 'Open CRESUS Evidence. Summarize only sources and research snapshots actually available in this conversation or verified storage. State if durable cross-session evidence is unavailable.' },
  providers: { mode: 'simple', prompt: 'Open CRESUS Provider Status. Distinguish configured, connected, available and tested. Report only provider states verifiable by this runtime; never expose secrets.' },
};

function selectWorkspace(key) {
  const item = WORKSPACES[key];
  if (!item) return;
  document.querySelectorAll('.workspace-btn').forEach((b) => {
    const active = b.dataset.workspace === key;
    b.classList.toggle('active', active);
    b.setAttribute('aria-pressed', String(active));
  });
  state.mode = item.mode;
  store.set('cresus.mode', item.mode);
  renderModes();
  $('input').value = item.prompt;
  autosize();
  // Run the selected workflow through the existing authenticated chat path.
  $('composer').requestSubmit();
  if (matchMedia('(pointer: coarse)').matches) $('chat').scrollTop = 0;
}


function renderPresentation() {
  const expert = state.presentation === 'expert';
  document.querySelectorAll('[data-presentation]').forEach(button => {
    const active = button.dataset.presentation === state.presentation;
    button.setAttribute('aria-pressed', String(active));
  });
  $('standardDesk').hidden = expert;
  $('expertDesk').hidden = !expert;
  $('presentationSummary').textContent = expert
    ? 'Advanced evidence, completion and strategy controls — same CRESUS data and permissions.'
    : 'Clear research, holdings and income — no invented balances or fabricated market data.';
}
document.querySelectorAll('[data-presentation]').forEach(button => {
  button.addEventListener('click', () => {
    state.presentation = button.dataset.presentation === 'expert' ? 'expert' : 'standard';
    store.set('cresus.presentation', state.presentation);
    state.mode = state.presentation === 'expert' ? 'expert' : 'simple';
    store.set('cresus.mode', state.mode);
    renderPresentation();
    renderModes();
  });
});
document.querySelectorAll('[data-cresus-workspace]').forEach(button =>
  button.addEventListener('click', () => selectWorkspace(button.dataset.cresusWorkspace))
);
document.querySelectorAll('[data-cresus-command]').forEach(button => button.addEventListener('click', () => {
  if (button.dataset.cresusCommand !== 'council') return;
  state.mode = 'council';
  store.set('cresus.mode', state.mode);
  renderModes();
  $('input').value = 'Run The Gilded Order challenge on my investment thesis. If I have not supplied one, ask me for the security and investment case; do not invent it.';
  autosize();
  $('composer').requestSubmit();
}));

// ---------- Wiring ----------
function autosize() {
  const t = $('input');
  t.style.height = 'auto';
  t.style.height = `${Math.min(t.scrollHeight, 168)}px`;
}

document.querySelectorAll('.workspace-btn').forEach((b) => {
  b.addEventListener('click', () => selectWorkspace(b.dataset.workspace));
});

$('composer').addEventListener('submit', (e) => {
  e.preventDefault();
  const text = $('input').value;
  if (!text.trim() || state.busy) return;
  $('input').value = '';
  autosize();
  send(text);
});
$('input').addEventListener('input', autosize);
$('input').addEventListener('keydown', (e) => {
  if (e.key === 'Enter' && !e.shiftKey && !e.isComposing && !matchMedia('(pointer: coarse)').matches) {
    e.preventDefault();
    $('composer').requestSubmit();
  }
});
$('menuBtn').onclick = () => { openDrawer(true); loadConversations(); };
$('closeDrawer').onclick = $('scrim').onclick = () => openDrawer(false);
$('newBtn').onclick = $('newBtnSide').onclick = resetChat;
$('exportBtn').onclick = exportChats;
async function showIntelligence(firstLogin = false) {
  const d = await api('/api/intelligence');
  const select = $('intelligenceProvider');
  select.replaceChildren();
  for (const p of d.choices) {
    const option = document.createElement('option');
    option.value = p.id;
    option.textContent = p.label + (p.available ? '' : ' (not connected)');
    option.disabled = !p.available && p.id !== 'none';
    select.append(option);
  }
  select.value = d.provider || 'none';
  $('intelligenceStatus').textContent = firstLogin
    ? 'Choose your provider to start. You can also skip and configure it later.'
    : 'Only configured providers can be selected. Codex Cloud requires a verified account connector.';
  $('intelligenceDlg').showModal();
}
$('intelligenceBtn').onclick = () => showIntelligence().catch(e => alert(e.message));
$('intelligenceSave').onclick = async () => {
  try {
    const r = await api('/api/intelligence', {method:'PUT', body:JSON.stringify({provider:$('intelligenceProvider').value})});
    $('intelligenceStatus').textContent = 'Saved: ' + r.provider;
    $('intelligenceDlg').close();
  } catch(e) { $('intelligenceStatus').textContent = e.message; }
};
$('adminBtn').onclick = () => { openDrawer(false); adminMsg(''); $('adminDlg').showModal(); loadAdmin(); };
$('saveLimits').onclick = async () => {
  try {
    await api('/api/admin/settings', {
      method: 'PUT',
      body: JSON.stringify({ maxUsers: $('maxUsers').value, dailyMessageLimit: $('dailyLimit').value }),
    });
    adminMsg('Limits saved.', 'good');
    loadAdmin();
    refreshQuota();
  } catch (e) { adminMsg(e.message, 'bad'); }
};
$('addUser').addEventListener('submit', async (e) => {
  e.preventDefault();
  try {
    const r = await api('/api/admin/users', {
      method: 'POST',
      body: JSON.stringify({ email: $('newEmail').value, role: $('newRole').value }),
    });
    $('newEmail').value = '';
    adminMsg(r.error ? `Added, but ${r.error}.` : 'Added.', r.error ? 'bad' : 'good');
    loadAdmin();
  } catch (e2) { adminMsg(e2.message, 'bad'); }
});

(async function init() {
  renderModes();
  renderPresentation();
  showNet();
  try {
    state.me = await api('/api/me');
    $('verifiedRuntime').textContent = 'Signed in: ' + state.me.email + ' · AI capabilities checked separately; market data not verified.';
    $('whoami').textContent = state.me.email;
    $('adminBtn').hidden = state.me.role !== 'admin';
    refreshQuota();
    if (!mobile()) loadConversations();
    const intelligence = await api('/api/intelligence');
    if (intelligence.provider) $('verifiedRuntime').textContent = 'Signed in: ' + state.me.email + ' · Selected intelligence: ' + intelligence.provider + ' (inference not yet tested).';
    if (!intelligence.configured) await showIntelligence(true);
  } catch (e) {
    const body = cresusShell('simple');
    body.className = 'body';
    body.innerHTML = `<div class="err"><p>${
      e.status === 403
        ? `<strong>${esc(e.data?.email || 'This account')}</strong> has not been given access to CRESUS. Ask the owner to add you.`
        : e.status === 401 ? 'Your sign-in has expired. Reload to sign in again.' : 'CRESUS could not be reached. Check your connection and reload.'
    }</p></div>`;
    $('composer').hidden = true;
    $('modes').hidden = true;
  }
  if ('serviceWorker' in navigator) navigator.serviceWorker.register('/sw.js');
})();
