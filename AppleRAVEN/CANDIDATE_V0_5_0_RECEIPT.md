# AppleRAVEN v0.5.0 — isolated executable candidate receipt (2026-10-26)

**Identity:** owner-private Apple-and-raven dark design, NOT official edenOS. **BIFROST is not a runtime dependency.**

## Artifact and source authority

The current runnable package is a **conversation-created attachment** named `AppleRAVEN-private-v0.5.0-provider-MCP.zip` (SHA-256: `faa70cb6b9f6ec177ea51523900f555f67306a9c798ed2b9a6485b175ce4fe28`). It is intentionally **not** claimed to be synced to this older GitHub candidate branch or installed on a Mac. Preserve the prior v0.4.0 package as rollback. GitHub and Mac authority must be reconciled before promotion.

## What was actually executed

- Fresh unzip, independent 63/63 automated tests passed on Linux.
- Real modern 2026-07-28 and legacy 2025-06-18 stdio MCP process round-trips.
- Isolated actual installer passed, wrote an owner-only config and started the **installed** MCP with **20 tools**; duplicate install refused overwrite.
- 18 previous Apple/device/MCP tools preserved. Added `appleraven.models.status` and `appleraven.models.generate`.
- Provider request/response behavior verified through stand-ins: Ollama via real loopback HTTP socket, LM Studio OpenAI-compatible API, OpenAI, Anthropic, Gemini, Groq, OpenRouter, Mistral and DeepSeek request format mapping.
- No live provider accounts, Apple credentials, paid APIs, physical Mac/iPhone or iCloud systems were exercised.

## Security and connection contract

- Each model explicitly configured in the fixed MCP startup identity `allow_models`; defaults empty.
- Remote AI inference requires `allow_remote_inference: true` and a request argument `approve_remote: "SEND"`; HTTPS fixed domains only; credentials from environment, never source/profile.
- Local model routes use loopback only. No arbitrary URLs, no redirect, no background daemon or implicit remote binding.
- Cloud model response text is **never executed** as an Apple system action. HTTP MCP transport retains read-only default tool list.
- Real ChatGPT desktop local MCP use depends on ChatGPT's plugin local-app support; Codex CLI/Claude/Gemini CLI/Cursor/VS Code/LM Studio client setup is separate from provider API login.
- Latest protocol source: https://blog.modelcontextprotocol.io/posts/2026-07-28/ ; OpenAI local MCP plugin FAQ https://help.openai.com/en/articles/20001256-plugins-in-chatgpt .

## Remaining gates

1. Recover current physical original AppleRAVEN source, `#common` rules, Mac Project Bible, Git dirty state and accepted LKG; reconcile package rather than overwrite.
2. Install user-selected MCP host integration, physical macOS Shortcuts/iCloud/Bonjour/App Intents tests and per-provider API authorization.
3. Read/evaluate all 391 Dropbox saved references and their original live sources. Filename inventory != fullresearch.
4. Identity-isolated end-to-end workflow with real receipt and rollback before release.

**Evidence status:** source candidate implemented; local test & installer acceptance PASS; real target device/provider acceptance UNKNOWN; RELEASED = NO.
