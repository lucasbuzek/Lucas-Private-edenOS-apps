# Raven chat — AI provider options (free or limited use)

Status: reference for the Raven chat layer (Task 3). Researched 2026-10-09; free tiers change often, so re-check before relying on a number.
Evidence: provider facts are from the sources at the bottom (third-party summaries of official pages, read 2026-10-09). Nothing here has been live-tested from Raven yet: provider quality is UNKNOWN until `tests/chat_eval/run_live_eval.mjs` passes (>= 90% expected outcomes, zero unsafe).

## How Raven uses the model
The model only classifies a request into a fixed JSON shape (intent, topic, capability, params, node). Facts come from Raven's own state; actions need a tap to confirm; sensitive capabilities are never offered from chat; empty or broken replies fall back to plain status. So a small free model is enough, and switching providers is a settings change.

## Configured defaults (Pages variables)
- `CHAT_PROVIDER=groq` (options: `groq`, `workers-ai`, `gemini`, `none`)
- `CHAT_MODEL=openai/gpt-oss-120b`
- `CHAT_MODEL_FALLBACKS=openai/gpt-oss-20b` (comma list; tried in order only after a 429 rate limit or a 5xx error)
- Secret: `GROQ_API_KEY` (`npx wrangler pages secret put GROQ_API_KEY --project-name lucas-raven`)
- Instant off switch: `CHAT_PROVIDER=none`
- Verify the model ids in the Groq console before go-live.

## Options

| Provider | Free / limited models | Free limit | Privacy | Use for BIFROST |
|---|---|---|---|---|
| Groq | gpt-oss-120b, gpt-oss-20b, Qwen3.8 27B; Whisper | about 1,000 requests and 200k tokens per day per model; Whisper about 2,000/day; whole organization | no training without permission; logs up to 30 days unless Zero Data Retention | DEFAULT |
| Cloudflare Workers AI | Llama-class, Whisper, MeloTTS | 10,000 neurons/day, shared with CRESUS | no training | fallback only (gave empty/useless answers in CRESUS) |
| Google Gemini | 3.x Flash / Flash-Lite, Gemma 4 | per project (AI Studio) | free tier used to improve Google products; human review possible | off by default (`CHAT_ALLOW_TRAINING_PROVIDERS=1` to allow); no private data. Code default model id is outdated and must be set via `CHAT_MODEL` if enabled |
| Mistral | Small 4, Medium 3.5, Large 3, Codestral | monthly allowance (amount not published) | may train on free-plan data unless opted out | not wired; avoid for private data |
| OpenRouter | 25+ free models | 50 requests/day (1,000/day after a one-time $10 credit purchase) | depends on upstream provider | not wired; optional extra |
| NVIDIA NIM | Kimi K3, DeepSeek V4.1 Flash, Nemotron | about 40/min | trial: testing/evaluation only, not production | evaluation only |
| Cohere | Command R, R7B | 1,000 calls/month | trial keys not for production | evaluation only |
| Cerebras | gpt-oss-120b, Qwen | $5 trial credit for 30 days, card required | no retention | not a free tier |
| Apple on-device (Apple Intelligence) | system model | unlimited, private | stays on device | only in a native BIFROST app on a supported iPhone/Mac, not in the web interface |

Gone: Groq removed Llama 3.3 70B and Llama 3.1 8B from free plans on 2026-08-16. GitHub Models was retired on 2026-07-30.

Claude and ChatGPT stay underneath for heavy work: Claude's API is paid (a claude.ai plan does not include API access); a ChatGPT login has no API, so Codex (WORKinCODEX) is the ChatGPT-backed path.

## Sources
- AgentDeals, Best Free LLM APIs in 2026: https://agentdeals.dev/free-llm-apis
- AIReiter, Best Free AI APIs in 2026 (official limits and data policies): https://aireiter.com/blog/best-free-ai-api
- Cloudflare Workers AI pricing: https://developers.cloudflare.com/workers-ai/platform/pricing/
