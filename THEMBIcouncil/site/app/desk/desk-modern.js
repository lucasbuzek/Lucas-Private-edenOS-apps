/* ELYSIUM / THEMBIcouncil — protected Desk interaction layer.
 * Works only after the existing /app/api/me session check succeeds.
 * Never caches, copies, fabricates or transfers private records.
 */
(() => {
  'use strict';
  const byId = id => document.getElementById(id);
  const workspace = byId('workspace');
  const nav = byId('desk-sidebar');
  const toggle = byId('sidebar-toggle');
  const backdrop = byId('sidebar-backdrop');
  const dialog = byId('desk-command');
  const searchButton = byId('desk-search');
  const searchInput = byId('command-filter');
  const results = byId('command-results');
  const close = byId('command-close');
  if (!workspace || !nav || !toggle || !backdrop || !dialog || !searchInput || !results) return;
  const authenticated = () => !workspace.hidden;
  let priorFocus = null;

  function setOpen(open, restore = false) {
    const next = Boolean(open) && authenticated();
    document.body.classList.toggle('nav-open', next);
    toggle.setAttribute('aria-expanded', String(next));
    backdrop.setAttribute('aria-hidden', String(!next));
    if (next) nav.querySelector('a.active, a')?.focus();
    if (!next && restore) toggle.focus();
  }
  toggle.addEventListener('click', () => setOpen(!document.body.classList.contains('nav-open'), true));
  backdrop.addEventListener('click', () => setOpen(false, true));
  nav.querySelectorAll('a').forEach(a => a.addEventListener('click', () => setOpen(false)));
  window.addEventListener('resize', () => { if (window.innerWidth > 900) setOpen(false); });

  // Discover only real navigation links in the existing authenticated menu.
  // No provider reads or cross-tenant searches are performed here.
  const destinations = [...nav.querySelectorAll('nav a')].map(a => ({
    label: a.textContent.trim(),
    url: a.getAttribute('href')
  })).filter(x => x.label && x.url && x.url.startsWith('/') && !x.url.startsWith('//'));

  function draw(query = '') {
    results.replaceChildren();
    const q = query.trim().toLocaleLowerCase();
    const items = destinations.filter(x => x.label.toLocaleLowerCase().includes(q));
    if (!items.length) {
      const empty = document.createElement('p');
      empty.textContent = 'No matching destination in your workspace.';
      results.append(empty);
      return;
    }
    for (const x of items) {
      const a = document.createElement('a');
      a.href = x.url;
      a.textContent = x.label;
      results.append(a);
    }
  }

  function openCommand() {
    if (!authenticated() || typeof dialog.showModal !== 'function') return;
    setOpen(false);
    priorFocus = document.activeElement;
    searchInput.value = '';
    draw();
    if (!dialog.open) dialog.showModal();
    searchInput.focus();
  }
  searchButton?.addEventListener('click', openCommand);
  close?.addEventListener('click', () => dialog.close());
  searchInput.addEventListener('input', () => draw(searchInput.value));
  dialog.addEventListener('close', () => { if (priorFocus?.isConnected) priorFocus.focus(); });
  dialog.addEventListener('click', e => { if (e.target === dialog) dialog.close(); });

  document.addEventListener('keydown', e => {
    if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
      if (!authenticated()) return;
      e.preventDefault();
      openCommand();
    }
    if (e.key === 'Escape' && document.body.classList.contains('nav-open')) {
      setOpen(false, true);
    }
    if (e.key === 'Tab' && document.body.classList.contains('nav-open')) {
      const focusables = [...nav.querySelectorAll('a[href],button:not([disabled])')];
      if (!focusables.length) return;
      const first = focusables[0], last = focusables[focusables.length - 1];
      if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
      else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
    }
  });
})();