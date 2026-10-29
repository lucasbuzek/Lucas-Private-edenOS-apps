/* AppleRAVEN onboarding: optional same-origin WebMCP demo tools.
 * Browser localStorage only; no AppleRAVEN OAuth, device access or cloud write.
 * Feature-detect the October 2026 Chrome document.modelContext API.
 */
(() => {
  const api = document.modelContext;
  if (!api || typeof api.registerTool !== 'function') return;
  const names = ['Personal', 'Business', 'Organization'];
  const key = s => 'appleraven_elysium_demo_2026_' + s;
  const read = space => {
    if (!names.includes(space)) return {error: 'Unsupported workspace'};
    try {
      const data = JSON.parse(localStorage.getItem(key(space)) || '[]');
      const tasks = Array.isArray(data) ? data.filter(x => typeof x === 'string').slice(0, 50) : [];
      return {workspace: space, tasks, count: tasks.length, storage: 'browser-local-demonstration'};
    } catch {
      return {error: 'Local demonstration data unavailable'};
    }
  };
  const controller = new AbortController();
  const listTool = {
    name: 'elysium_demo_list_tasks',
    description: 'Read the sample tasks in one local ELYSIUM demonstration workspace. This is not real ELYSIUM or Mac data.',
    inputSchema: {type: 'object', properties: {workspace: {type: 'string', enum: names}}, required: ['workspace'], additionalProperties: false},
    execute: async ({workspace}) => read(workspace),
    annotations: {readOnlyHint: true, destructiveHint: false, openWorldHint: false}
  };
  const addTool = {
    name: 'elysium_demo_add_task',
    description: 'Add one task to the browser-local demonstration using the visible task form. No cloud or Apple device changes.',
    inputSchema: {type: 'object', properties: {
      workspace: {type: 'string', enum: names},
      text: {type: 'string', minLength: 1, maxLength: 120}
    }, required: ['workspace', 'text'], additionalProperties: false},
    execute: async ({workspace, text}) => {
      if (!names.includes(workspace) || typeof text !== 'string' || !text.trim() || text.length > 120) {
        return {error: 'Invalid workspace or task'};
      }
      const existing = read(workspace);
      if (existing.error) return existing;
      if (existing.count >= 50) return {error: 'Local demonstration task limit reached'};
      const tab = [...document.querySelectorAll('[data-space]')].find(x => x.dataset.space === workspace);
      const form = document.getElementById('taskform');
      const input = document.getElementById('tasktext');
      if (!tab || !form || !input) return {error: 'Demonstration interface unavailable'};
      tab.click();
      input.value = text.trim();
      form.dispatchEvent(new Event('submit', {bubbles: true, cancelable: true}));
      return read(workspace);
    },
    annotations: {readOnlyHint: false, destructiveHint: false, openWorldHint: false}
  };
  Promise.all([
    api.registerTool(listTool, {signal: controller.signal}),
    api.registerTool(addTool, {signal: controller.signal})
  ]).catch(() => { controller.abort(); });
  window.addEventListener('pagehide', () => controller.abort(), {once: true});
})();
