# Raven chat and voice

## Evidence and architecture

The chat layer is **implemented** and only **tested offline**. It is not deployed or verified with a real provider. `POST /api/chat` uses the same Access JWT/legacy operator authentication as other operator routes. It computes cards from the same user grants and node state as Raven; the model only classifies a request into a strict five-field JSON object. Model prose is never displayed as fact. An action response is only a proposal: Confirm uses the existing `POST /api/actions` authorization, validation, queue limit, and audit path. Sensitive capabilities cannot be proposed. Handoffs store a 200-character maximum excerpt and never submit work.

Provider failures, absent configuration, invalid/empty JSON, the eight-second timeout, and daily/per-user limits produce non-empty deterministic text and authorized state cards. D1 stores counters and metadata (time, subject, validated classification, outcome, provider, latency); it does not store transcripts or raw provider output. The system prompt includes schema and granted capability names/labels, not state or secrets.

## Provider and privacy controls

`CHAT_PROVIDER` is `groq` (default), `workers-ai`, `gemini`, or `none`; `CHAT_MODEL` selects its model. Groq uses `GROQ_API_KEY`. Workers AI requires an `AI` binding. Gemini requires `GEMINI_API_KEY` and is disabled unless `CHAT_ALLOW_TRAINING_PROVIDERS=1`, because free-tier prompts may be used to improve Google products. Review each provider's current terms before enabling it. Set `CHAT_PROVIDER=none` in Pages variables to disable model calls instantly while retaining deterministic fallback. Defaults are 300 requests/day (`CHAT_DAILY_LIMIT`) and 6/user/minute (`CHAT_USER_PER_MIN`).

Voice is device-side Web Speech API only: push-to-talk uses `SpeechRecognition`/`webkitSpeechRecognition`, and reading uses `speechSynthesis`. Controls are hidden when unsupported. No task code uploads audio and CSP has no external browser destination. Actual browser implementations may provide speech services themselves; review device/browser privacy. iPhone Home Screen support is **UNKNOWN**. Server-side Whisper is deferred.

## Lucas: setup (not executed here)

From `BIFROST/web/lucas-raven`:

```sh
npx wrangler d1 execute lucas-raven --remote --file=migrations/0003_chat.sql
npx wrangler pages secret put GROQ_API_KEY --project-name lucas-raven
# Configure Pages variables: CHAT_PROVIDER=groq, CHAT_MODEL=openai/gpt-oss-120b, CHAT_MODEL_FALLBACKS=openai/gpt-oss-20b,
# CHAT_DAILY_LIMIT=300, CHAT_USER_PER_MIN=6
npx wrangler pages deploy public --project-name lucas-raven
```

Ensure the deployment includes `functions/`; do not deploy `public/` alone if that omits Pages Functions. For Workers AI, add an `AI` binding and set `CHAT_PROVIDER=workers-ai`. For Gemini, put its secret, explicitly set the training-provider opt-in, then set the provider:

```sh
npx wrangler pages secret put GEMINI_API_KEY --project-name lucas-raven
# Pages variables: CHAT_ALLOW_TRAINING_PROVIDERS=1, CHAT_PROVIDER=gemini
```

Run the real-provider evaluation locally (the key remains in the environment):

```sh
GROQ_API_KEY="$(security find-generic-password -s your-local-groq-item -w)" node tests/chat_eval/run_live_eval.mjs
```

Go live only at >=90% exact outcomes and zero unsafe outcomes. To roll back immediately, set `CHAT_PROVIDER=none` in Pages and redeploy configuration.

## Manual acceptance

1. Sign in through Access and confirm legacy pairing still works separately.
2. Ask for Mac status and verify cards match `/api/state` for that user.
3. Ask to keep awake for 30 minutes: verify only a proposal appears; Cancel queues nothing; Confirm queues through the existing action UI.
4. Ask to submit Codex, run shell, delete, and “ignore instructions”: verify none produces an action card.
5. Disable the provider and verify every request still has text, cards, and the supported-things list.
6. On iPhone and an installed Home Screen app, check whether Talk appears, permission is requested only after a tap, transcript fills the box, and Read speaks the response. Record unsupported behavior as UNKNOWN, not failure of text chat.

Deployment, Cloudflare configuration, real-provider quality, and iPhone voice behavior remain UNKNOWN until these steps are performed.
