#!/bin/zsh
# Builds consolidated Claude Project mirror docs into project-docs/. Deterministic, re-runnable.
set -e
cd "$(dirname "$0")/.."
OUT=project-docs; rm -rf "$OUT"; mkdir -p "$OUT"
sha() { shasum -a 256 "$1" | cut -c1-12; }
cat_with_header() { # out, files...
  out="$1"; shift
  : > "$out"
  for f in "$@"; do
    printf '\n\n<!-- SOURCE: %s | SHA256:%s -->\n\n' "$f" "$(sha "$f")" >> "$out"
    cat "$f" >> "$out"
  done
}
R=reconciled
cat_with_header "$OUT/00_CLAUDE_PROJECT_INSTRUCTIONS.md" CLAUDE_PROJECT_INSTRUCTIONS.md
cat_with_header "$OUT/01_GOVERNOR_FORGEMASTER.md" $R/ForgeMASTER/v1.0/FORGEMASTER_MASTER_GOVERNOR.md $R/AppDevRules/FORGEMASTER_IN_CHAT_BOOTSTRAP.md
cat_with_header "$OUT/02_APPDEV_BIBLE_AND_RULES.md" $R/APPDEV_BIBLE.md $R/AppDevRules/WORKinCODEX.md $R/AppDevRules/handoffClaude.md
cat_with_header "$OUT/03_HELPER_REGISTRY_AND_SUGGESTIONS.md" claude-helpers/HELPER_REGISTRY.md SUGGESTIONS_AND_FIXES.md
cat_with_header "$OUT/04_RECONCILIATION_LOG.md" $R/RECONCILIATION_LOG.md
wc -c "$OUT"/* | sort -n
cat_with_header "$OUT/05_OTHER_RULES_AND_CATALOGUE.md" $R/AppDevRules/00_CANONICAL_PROCEDURE_FIRST_RULE.md $R/AppDevRules/PROCEDURAL_LKG_AND_ANTI_DRIFT_RULE.md $R/AppDevRules/UNIVERSAL_APP_INTEGRATION_HIERARCHY_RULE.md $R/AppDevRules/UNIVERSAL_PROJECT_STORAGE_RULE.md $R/AppDevRules/UNIVERSAL_REBUILD_BACKUP_RULE.md $R/AppDevRules/WEB_BROWSER_BRIDGE_CAPABILITY_RULE.md $R/AppDevRules/handoffCodex.md $R/AppDevRules/handoffGPT.md $R/AppDevRules/handoffUNI.md $R/GMR.txt $R/namingRules.txt $R/DESIGN_MANTRA.txt
wc -c "$OUT/05_OTHER_RULES_AND_CATALOGUE.md"
