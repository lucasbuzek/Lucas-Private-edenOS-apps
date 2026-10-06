APPDEV CORE PRINCIPLES — v1.1 Owner: Lucas Buzek Status: Canonical
reconciliation update / Experimental Languages: English + Slovak in each
document

PURPOSE This package updates the shared EDEN/AppDev rules to incorporate
the established LEAN/TINY execution philosophy, deterministic-first
architecture, replaceable AI providers, local model capability
selection, and App identity/authority reconciliation.

FILES 01_AppDevRules_v1.1.txt 02_Design_Mantra_v1.1.txt
03_NamingRules_v1.1.txt 04_Software_Development_v1.1.txt
05_edenOS_Core_Philosophy_v1.1.txt
06_AI_Execution_and_Provider_Philosophy_v1.1.txt
07_App_Identity_and_Overlap_Reconciliation_v1.1.txt
08_Packaging_and_Release_Rules_v1.1.txt

SOURCE PRIORITY Newest explicit Lucas Buzek decisions override older
conflicts. Established identities are preserved unless explicitly
superseded. UIbasic is legacy/provenance and is superseded by LCAS —
Live Control, Activity & Status. Unknown or unresolved facts remain
UNKNOWN/UNRESOLVED rather than being invented.

CORE NEW RULE USE THE LOWEST SUFFICIENT CAPABILITY: DETERMINISTIC /
EXISTING → TINY SPECIALIST → LOCAL AI → LAN/SHARED AI → EXTERNAL API →
HYBRID.

The model/provider is replaceable. The EDEN capability and authoritative
application identity are not owned by the model/provider.

VERIFICATION These documents were generated as a reconciled policy
package from the current APPDEV MASTER handoff, recovered Design Mantra,
relevant AppDev project history, and the current explicit decisions in
appDev MASTER. They are documentation; they do not by themselves verify
software implementation.
