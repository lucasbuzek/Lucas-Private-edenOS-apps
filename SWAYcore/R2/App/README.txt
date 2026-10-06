SWAYcore 0.9 Build 120 — recovery / goal-convergence candidate

Open SWAY.xcodeproj in Xcode. Run VERIFY_M12.command first if desired; it performs available source checks and an unsigned Xcode build when Xcode is installed.

This candidate preserves the Build 119 recovery work and corrects additional project-goal mismatches found by CONDUCTOR/FORGE audit. See PROJECT_GOAL_AUDIT_BUILD120.txt.

Evidence state: IMPLEMENTED + local static verification pending. Xcode/device acceptance is an external physical gate and must not be inferred from static checks.
