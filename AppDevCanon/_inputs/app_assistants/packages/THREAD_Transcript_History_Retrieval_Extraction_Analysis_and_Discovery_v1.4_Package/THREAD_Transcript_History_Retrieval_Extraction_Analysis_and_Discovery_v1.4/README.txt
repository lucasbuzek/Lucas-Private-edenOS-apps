THREAD — Transcript History Retrieval, Extraction, Analysis & Discovery — v1.4.1

FUNCTIONAL MEANING
Transcript History Retrieval, Extraction, Analysis & Discovery.

CONCEPTUAL MEANING
A thread connects separate pieces into a continuous line. THREAD follows information across conversations, projects, files, remembered context, decisions, versions and related work to reconstruct the history of a subject as completely and accurately as available sources permit.

PURPOSE
THREAD is a reusable conversation-history retrieval and reconstruction framework for recovering prior project work, decisions, versions, files, requirements and context.

MAJOR CAPABILITIES
• Multi-pass historical retrieval
• Alias and renamed-project discovery
• Timeline reconstruction
• Decision-state recovery
• Version and branch tracing
• File-reference discovery
• Gap and contradiction detection
• Exact-data safeguards
• Structured handoff to ARGOS, CASPER, FORGE, IRIS, READ, AOS and WEAVER

IMPORTANT LIMITATION
THREAD cannot grant itself access to raw chats or sources that the current ChatGPT environment does not expose. It must state what was retrieved, reconstructed, not found or inaccessible.

QUICK START
Open THREAD_v1.4_MASTER.txt and invoke:
@THREAD AUTO [your request]

DIRECTORY
README.txt — this entry point
THREAD_v1.4_MASTER.txt — authoritative framework
THREAD_v1.4_INSTRUCTIONS.txt — detailed use
THREAD_v1.4_QUICKSTART.txt — copy/paste commands
THREAD_v1.4_MODULES.txt — modes/modules
THREAD_v1.4_CHANGELOG.txt — release history
prompts/ — specialized reusable prompts
templates/ — handoff/output templates
examples/ — realistic examples
docs/ — design and validation notes

DEPENDENCIES
No mandatory external framework. THREAD can hand off to established external frameworks when available.

v1.4 DESIGN UPDATE
THREAD now applies the project Design Mantra to retrieval work:
• one authoritative current reconstruction;
• less repeated work;
• progressive disclosure;
• explicit retrieval/validation state;
• recovery-first continuation;
• persistent validated checkpoints;
• migrate rather than reset;
• minimum processing/storage overhead;
• formal packaging when useful or at final completion.

v1.4 LCAS UPDATE
• LCAS — Live Control, Activity & Status integrated as THREAD's external presentation/control protocol.
• TINY, COMPACT, FULL and AUTO modes.
• Truthful progress/state mapping.
• State-aware recommended next action.
• Blocker/recovery/checkpoint presentation.
• No duplicate retrieval or progress engine.

v1.4 LCAS NORMALIZATION
• LCAS — Live Control, Activity & Status is canonical for live control/status.
• All superseded control/status naming is normalized to LCAS.
• New commands, prompts, panels, pipelines, artifacts, handoffs and packages use LCAS.
• Unrelated established assistants retain their canonical identities.

v1.4 SELF + SUBORDINATES PACKAGE
• Added THREAD_v1.4_ABOUT_SELF_AND_SUBORDINATES.txt.
• Added dedicated prompts for 12 THREAD internal subordinate roles.
• Preserved LCAS as canonical live control/status layer.
• Preserved established external specialist identities and application boundaries.
• No new framework identity introduced.
