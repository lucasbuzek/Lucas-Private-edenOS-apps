"use strict";
(() => {
  const $ = (id) => document.getElementById(id);
  let current = null;
  function status(message, error = false) {
    $("status").textContent = message;
    $("status").className = error ? "alert" : "ok";
  }
  function output(value) {
    $("result").textContent = JSON.stringify(value, null, 2);
  }
  async function call(path, data) {
    const cloudAccess = document.body.dataset.famaAccess === "1";
    const token = $("token").value;
    if (!cloudAccess && (!token || token.length < 32)) throw Error("Enter your configured owner session token");
    const headers = {"Content-Type":"application/json"};
    if (!cloudAccess) headers.Authorization = "Bearer " + token;
    const response = await fetch(path, {
      method: "POST", cache: "no-store", credentials: "same-origin",
      headers, body: JSON.stringify(data)
    });
    const result = await response.json();
    if (!response.ok) throw Error(result.error || "Request failed (" + response.status + ")");
    return result;
  }
  async function act(fn) {
    try { status("Working with the original FAMA runtime…"); await fn(); }
    catch (error) { status(error.message || "Operation failed", true); }
  }
  function isoFromLocal() {
    const input = $("publish_at").value;
    if (!input) throw Error("Choose a proposed publish time");
    const date = new Date(input);
    if (!Number.isFinite(date.valueOf())) throw Error("Invalid publish time");
    return date.toISOString();
  }
  function toLocalInput(iso) {
    const date = new Date(iso);
    return Number.isFinite(date.valueOf()) ?
      new Date(date.valueOf() - date.getTimezoneOffset() * 60000).toISOString().slice(0, 16) : "";
  }
  function urls() {
    return $("source_urls").value.split(/\r?\n/).map(s => s.trim()).filter(Boolean);
  }
  function appendURL(url) {
    const list = urls();
    if (!list.includes(url)) list.push(url);
    $("source_urls").value = list.join("\n");
    status("Source URL added to draft. Verify the underlying article before approval.");
  }
  function renderLeads(candidates) {
    const area = $("leads");
    area.replaceChildren();
    if (!Array.isArray(candidates) || candidates.length === 0) {
      const p = document.createElement("p"); p.textContent = "No leads returned by the public providers.";
      area.append(p); return;
    }
    for (const lead of candidates) {
      if (!lead || !lead.url || !/^https?:\/\//i.test(lead.url)) continue;
      const item = document.createElement("div"); item.className = "lead";
      const link = document.createElement("a");
      link.href = lead.url; link.target = "_blank"; link.rel = "noopener noreferrer";
      link.textContent = lead.title || lead.url; item.append(link);
      const meta = document.createElement("p"); meta.className = "subtle";
      meta.textContent = [lead.discovery_source, lead.published_at || "date unavailable",
        lead.claim_verification_status || "NOT_VERIFIED"].join(" · ");
      item.append(meta);
      const button = document.createElement("button"); button.type = "button";
      button.textContent = "Use source URL";
      button.addEventListener("click", () => appendURL(lead.url));
      item.append(button); area.append(item);
    }
  }
  async function listPosts(selectId) {
    const response = await call("/api/queue", {operation:"list"});
    const items = response.result || [];
    const select = $("post_select"); const previous = selectId || select.value;
    select.replaceChildren();
    const empty = document.createElement("option"); empty.value = "";
    empty.textContent = "Select saved draft"; select.append(empty);
    for (const post of items) {
      const option = document.createElement("option");
      option.value = post.post_id;
      option.textContent = [post.post_id, post.platform, post.state].join(" · ");
      select.append(option);
    }
    if (items.some(x => x.post_id === previous)) select.value = previous;
    status(items.length + " original FAMA review-queue post(s) loaded");
    return items;
  }
  async function openPost() {
    const id = $("post_select").value;
    if (!id) throw Error("Select a saved post");
    const response = await call("/api/queue", {operation:"show", post_id:id});
    current = response.result;
    $("review_detail").textContent = JSON.stringify(current, null, 2);
    $("draft_id").value = current.post_id;
    $("persona_id").value = current.persona_id;
    $("platform").value = current.platform;
    $("account_id").value = current.account_id;
    $("audience").value = current.audience;
    $("draft_text").value = current.text;
    $("source_urls").value = (current.source_urls || []).join("\n");
    $("publish_at").value = toLocalInput(current.proposed_publish_at);
    status(current.state + " · " + current.post_id + " · no external action");
  }
  async function createDraft() {
    const id = $("draft_id").value.trim() || "fama-" + Date.now();
    const data = {
      operation:"create", post_id:id, persona_id:$("persona_id").value.trim(),
      platform:$("platform").value.trim(), account_id:$("account_id").value.trim(),
      audience:$("audience").value.trim(), text:$("draft_text").value.trim(),
      source_urls:urls(), proposed_publish_at:isoFromLocal()
    };
    const response = await call("/api/queue", data); output(response);
    await listPosts(id); await openPost();
  }
  async function editDraft() {
    if (!current) throw Error("Open an existing draft first");
    if (!window.confirm("Update this exact draft? Any existing approval will be invalidated.")) return;
    const response = await call("/api/queue", {operation:"edit",post_id:current.post_id,
      text:$("draft_text").value.trim(),source_urls:urls(),
      proposed_publish_at:isoFromLocal()});
    output(response); await listPosts(current.post_id); await openPost();
  }
  async function transition(operation) {
    if (!current) throw Error("Open a saved draft first");
    if (operation === "approve") {
      if (current.state !== "READY_FOR_REVIEW") throw Error("Mark draft ready for review first");
      const reviewer = $("reviewer").value.trim();
      if (!reviewer) throw Error("Enter the real human reviewer identity");
      const question = ["Approve this exact source-grounded draft for LOCAL schedule preparation?",
        "Post: " + current.post_id, "Platform: " + current.platform,
        "Account: " + current.account_id, "SHA-256: " + current.content_hash,
        "No external publishing will occur."].join("\n");
      if (!window.confirm(question)) return;
      const expires = new Date(Date.now() + 60 * 60 * 1000).toISOString();
      const response = await call("/api/queue", {operation:"approve",
        post_id:current.post_id, reviewer, action:"PREPARE_SCHEDULE",
        account_id:current.account_id, platform:current.platform,
        content_hash:current.content_hash, expires_at:expires, note:"Approved from owner-local FAMA browser"});
      output(response);
    } else {
      if (!window.confirm(operation === "ready" ?
          "Mark selected draft ready for human review?" :
          "Prepare the approved draft's local schedule proposal? No publishing occurs.")) return;
      const response = await call("/api/queue", {operation,post_id:current.post_id});
      output(response);
    }
    await listPosts(current.post_id); await openPost();
  }
  if (document.body.dataset.famaAccess === "1") {
    $("token").closest("label").hidden = true;
    status("Sign in through the Cloudflare owner access screen to continue.");
  }
  const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);
  $("publish_at").value = toLocalInput(tomorrow.toISOString());
  // The original upstream analyzer is Python and remains local-only until the
  // cloud adapter has an independently verified, license-preserving implementation.
  const captionAction = $("caption_audit");
  if (document.body.dataset.famaAccess === "1") {
    captionAction.disabled = true;
    captionAction.title = "Available in the authenticated local FAMA studio; not yet in cloud preview";
  } else {
    captionAction.addEventListener("click", () => act(async () => {
      const response = await call("/api/caption-audit", {text:$("draft_text").value});
      output(response);
      status("Original Instagram Agent caption analysis ready · editorial heuristic, not platform clearance");
    }));
  }
  $("research").addEventListener("click", () => act(async () => {
    const response = await call("/api/research",
      {query:$("query").value.trim(),hours:72,limit:5});
    output(response); renderLeads(response.candidates || []);
    status(response.run_status || "Source discovery complete; claims remain unverified.");
  }));
  $("capabilities").addEventListener("click", () => act(async () => {
    const response = await call("/api/capabilities", {});
    output(response); status("Authenticated local runtime checked");
  }));
  $("refresh").addEventListener("click", () => act(() => listPosts()));
  $("save").addEventListener("click", () => act(createDraft));
  $("edit").addEventListener("click", () => act(editDraft));
  $("open_post").addEventListener("click", () => act(openPost));
  $("post_select").addEventListener("change", () => { current = null; $("review_detail").textContent = "Open selected draft to review exact content."; });
  $("ready").addEventListener("click", () => act(() => transition("ready")));
  $("approve").addEventListener("click", () => act(() => transition("approve")));
  $("schedule").addEventListener("click", () => act(() => transition("schedule-proposal")));
  if (document.modelContext?.registerTool) {
    const controller = new AbortController();
    document.modelContext.registerTool({
      name:"fama_discover_public_sources",
      description:"Discover unverified public source leads via authenticated FAMA research runner; no social posting.",
      inputSchema:{type:"object", properties:{query:{type:"string",minLength:2,maxLength:120}},
        required:["query"],additionalProperties:false},
      annotations:{readOnlyHint:true,destructiveHint:false,openWorldHint:true},
      async execute({query}) {
        const result = await call("/api/research",{query,hours:72,limit:5});
        return {content:[{type:"text",text:JSON.stringify(result)}]};
      },
      signal:controller.signal
    });
    window.addEventListener("pagehide",() => controller.abort(),{once:true});
  }
})();
