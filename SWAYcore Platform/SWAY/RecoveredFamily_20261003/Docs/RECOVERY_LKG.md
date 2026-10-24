# Recovery / Last Known Good
- `preserve_lkg <product>` copies the previous *verified* output (`Build/Output/<product>/.verified`) to `Build/LKG/<product>/<timestamp>/` before each build.
- `preserve_assets_lkg` copies validated `Assets/` to `Build/LKG/Assets/<timestamp>/` before regeneration.
- Failures are never deleted: logs persist under `Build/logs/<timestamp>/`; reports under `Build/report/`.
- Assets regeneration is skipped when inputs are unchanged (`Assets/.validated` holds the input hash) and re-validated instead.
- No script deletes `Build/`.
- Stores: `JSONFileStore` and `StudioStore` keep a `.bak` of the previous save and fall back to it on corruption.
