

## Online research discovery (prototype)
`research_runner.py` searches GDELT and Google News RSS, optionally reads configured public RSS/Atom feeds, deduplicates results, fetches accessible article text and saves a timestamped JSON record. See `../02_RESEARCH/ONLINE_RESEARCH_RUNTIME.md`. It does not yet verify claims or write full posts. Use `python3 research_runner.py --query "topic" --hours 72 --limit 12` for a manual run. Research output is a set of leads; successful fetching never means a claim is verified.


## Automatic preparation pipeline (prototype)

`auto_pipeline.py` orchestrates discovery, a second pass for counterevidence/context leads, local topic-package generation, optional model-assisted research synthesis/drafting, and a local schedule proposal. It never submits, remotely schedules, or publishes. Every draft remains unverified and requires editorial and human approval.

Example discovery and package preparation:

```sh
cd "$HOME/edenOS/Projects/Social Media Intelligence/10_RUNTIME"
python3 auto_pipeline.py --query "your topic" --hours 72 --limit 5 --counter-topics 2 --no-model
```

For persona-based drafting, configure a real persona JSON first, then set the model provider only in the process environment (never in project files):

```sh
export OPENAI_API_KEY="your-key-from-your-secret-manager"
export OPENAI_MODEL="your-approved-model-id"
python3 auto_pipeline.py --persona ../03_PERSONAS/your-persona.json --config ../02_RESEARCH/your-research-config.json
```

This optional adapter makes paid external model requests and should only be used after the owner has configured their own API access and spending limits. Do not paste keys into chat, persona JSON, shell history, or source control. If the model is not configured, the pipeline saves research packages and marks drafting blocked. Platform-specific schedule cadence, account connections, review UI, and live provider scheduling remain unimplemented. A proposed time is local metadata only.


## Persona Studio

Create a persona interactively (new profiles are saved under `03_PERSONAS/Profiles/`):

```sh
cd "$HOME/edenOS/Projects/Social Media Intelligence/10_RUNTIME"
python3 persona_studio.py new --id my-brand
python3 persona_studio.py validate ../03_PERSONAS/Profiles/my-brand.json
python3 persona_studio.py activate ../03_PERSONAS/Profiles/my-brand.json --reviewer "Lucas"
python3 persona_studio.py edit ../03_PERSONAS/Profiles/my-brand.json
```

Creation and edits remain `CONFIGURED_PENDING_REVIEW`. Only an explicitly activated persona is accepted by the automatic pipeline. Updates create a revision snapshot under `03_PERSONAS/Profiles/history/` and append an audit event. The wizard deliberately does not expose auto-publishing or credentials.


The Persona Studio also collects a local publishing cadence (posts per week, preferred weekdays, preferred local times and minimum gap). The pipeline converts that into a rolling, local-only calendar proposal when configured. It never schedules remotely; every slot is still subject to per-post human review. If cadence is blank, the calendar remains `NOT_CONFIGURED`.


## Private ChatGPT adapter and Apple on-device drafting (2026-10-19)
`inchat_gateway.py` is a JSON stdin/--request-file command contract for capability discovery, supplied-persona validation, local calendar preview, and workspace-policy evaluation. This is NOT a live remote MCP server or verified BIFROST authentication endpoint. Neither ELYSIUM nor any social-account data can be accessed through it.
`workspace_policy.py` requires an externally verified actor assertion and time/purpose/action-scoped consent for any ELYSIUM workspace; it never authenticates real credentials. Treat caller-supplied `session_authenticated` and consent records as TEST FIXTURES until the BIFROST signature/identity bridge is verified.
`AppleFoundationWriter.swift` compiles on macOS 27/Xcode 27 and uses `SystemLanguageModel.default`, with no cloud fallback. The internal test binary is regenerable under `~/edenOS/Temporary/Social Media Intelligence/apple-foundation-writer-internal`; it is NOT an installed daemon or distribution release. Smoke-test JSON generation succeeded; actual claim-quality acceptance is pending.
`auto_pipeline.py --local-model-bin <verified-internal-binary>` selects this model explicitly. It requires a configured ACTIVE persona and enough retrieved article text to attempt a draft; generated claims always remain unverified. Cloud model requests need BOTH `persona.model_routing.cloud_allowed=true` and `--allow-cloud-model`; no credentials belong in project files.

