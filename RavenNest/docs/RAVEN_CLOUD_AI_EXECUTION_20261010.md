# RavenNest cloud AI candidate

Status: Cloud Worker deployed (version 250a746a-1989-4e23-8669-6137e29aa3f2); Pages UI/API candidate not deployed; external AI provider not configured. A harmless cloud.state.refresh task completed on live D1; no AI provider call proven.

Cloudflare Pages acts as the authenticated gateway and D1 queue. The separate raven-cloud-node Worker consumes the cloud queue and sends text requests to a configured hosted model provider. The Mac bridge is not required.

Provider modes: groq or workers-ai, default disabled until explicit configuration. Worker secrets stay server-side. Cloud AI inference requires an explicit per-user grant targeting lucas-cloud and an individual consented text request.

Input: 2,000 characters maximum; output truncated to 6,900. Model text never becomes a shell command or coding-agent action. Queued prompts reside temporarily in D1; Worker and edge expiry paths redact params. AI result-text retention is now bounded to seven days by Worker cron. Per-user daily usage ceilings, external-provider usage/cost checks, and owner model authorization remain unfinished.

Required before deployment: verify Cloudflare Access, enroll lucas-cloud, configure provider key/binding/model, assess privacy/quotas, test user/device isolation, and preserve rollback. Physical iPhone use with the Mac offline and an actual provider response are required acceptance gates.

Do not conflate this cloud text-inference capability with Codex Cloud submission, interactive development, or an autonomous coding worker. Those need distinct cloud executors.
