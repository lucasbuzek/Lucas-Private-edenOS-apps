# handoffGPT — ChatGPT AppDev Handoff

Status: AUTHORITATIVE APPDEV RULE
Base: `AppDevRules/handoffUNI.md`
Command: `@handoffGPT [goal/task]`

Apply `handoffUNI` in full, then specialize the transfer for ChatGPT.

## Access model
ChatGPT may have authenticated GitHub/connectors, current conversation files and approved development/testing plugins. Do not duplicate repository contents into the package when ChatGPT can retrieve the authoritative exact repo/ref/path. Use current connected sources and cite/record exact authority. Recover narrowly from conversation history only when a required project fact has not yet been migrated to authority.

Lucas's Mac has NO assumed GitHub connection. ChatGPT accesses GitHub through its authenticated GitHub connector and accesses the Mac through the authorized Mac/Remote Desktop bridge. Never require local GitHub access on the Mac merely because GitHub persistence is required.

## In-chat directive authority
AppDevRules are not merely files for local tools. They are directives for ChatGPT's in-chat AppDev behavior whenever the relevant authority is available in the active project/session context.

Before an AppDev response or action, apply `00_CANONICAL_PROCEDURE_FIRST_RULE.md` first: recover/check the applicable canonical procedure and authority, execute an established procedure literally, do not substitute an apparently equivalent mechanism, and do not report a state until its required evidence has actually been observed.

Chat memory/context may help recover a directive, but it is not the sole durable authority. Durable global AppDev rules are persisted in `lucasbuzek/Lucas-private-appDevDocs/AppDevRules`; the independent Mac copy lives at `~/edenOS/Projects/#appDev Bible/AppDevRules/`. ChatGPT explicitly reconciles the two through their respective connectors; never describe them as automatically synchronized.

## Package
Create an applicable-size `HANDOFF_GPT/` or archive containing `START_HERE.md`, exact project/goal/acceptance, authority/repository/ref pointers, LKG/candidate/evidence, relevant missing/local-only files, task-specific source/assets when connector access is insufficient, build/test instructions, expected return contract, manifest and checksums.

ChatGPT must not treat chat memory as durable project authority. Material discoveries/corrections that become project canon or implementation state must be persisted to the authoritative Project Bible/repository according to AppDev rules.

## Execution
Use available suitable tools/plugins directly when they advance the goal. GitHub is persistence/version control, not a substitute for actual build/runtime evidence. Mac/device bridge tools are for genuinely local execution/physical verification and for maintaining/reconciling the independent Mac authority copy; they are not a substitute for ChatGPT's GitHub connector.

Return cumulative implementation/evidence and persist durable results. Do not stop at a plan, status report, code snippets or a handoff description when safe executable work remains.