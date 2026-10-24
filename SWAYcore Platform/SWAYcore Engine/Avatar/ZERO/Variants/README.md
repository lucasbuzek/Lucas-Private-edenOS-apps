# ZERO variant lanes
Source owner: `../iOS TestHost/`; canonical pose source `../../../../SWAYcore Dance & Fitness/R2/App/SWAY/Views/StickFigureView.swift`; existing shared package `../../../../SWAYcore Dance & Fitness/R2/Packages/SWAYcoreEngine/`.
- `BASELINE_CANDIDATE/`: recovered minimum real app/stickman candidate; NOT cleanLKG until test and restoration/physical gates pass.
- `Claude/`: isolated Claude changes, design findings, tests and integration patches.
- `Gemini/`: isolated Gemini changes, design findings, tests and integration patches.
- `ChatGPT Work/`: isolated ChatGPT Work changes, design findings, tests and integration patches.
No shared provider write access is implied. Each must receive identical, SHA-pinned source only after qualification, then return scoped patch + file manifest + tests. Changes must be reconciled by ForgeMASTER; do not auto-merge, clone/overwrite R2 or silently create three independent duplicate masters.
