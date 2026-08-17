# Common Code Library

This directory contains shared code and resources that are used across multiple mods in the Balatro Modding Mono Repository.

## Purpose

The `_common` folder serves as a centralized location for reusable components, utilities, and assets that can be shared between different mods. This helps maintain consistency and reduces code duplication.

## Usage

When a mod is released via the CI/CD pipeline, the contents of this folder are automatically included as a subfolder named `common` inside the mod's directory.

This is **not** a standalone Steamodded mod: there is no `common.json` manifest, so Steamodded never scans the vendored `common/` folder as a mod. Instead, each mod bootstraps the library in its `src/init.lua`:

```lua
local chunk = SMODS.load_file('common/main.lua', self.mod_id)
if chunk then chunk() end
```

Initialization is gated by the `RIOSODU_SHARED` global: only the first mod to load actually initializes the library; subsequent mods skip it.

### Versioning

The internal version is hardcoded in `version.lua` and exposed at runtime as `RIOSODU_SHARED.version`. The canonical version lives in `CHANGELOG.md`; `sync-versions.sh` keeps `version.lua` in sync and bumps dependent mods when the library version changes.

## Structure

- `version.lua` - Hardcoded internal library version
- `config.lua` - Shared configuration defaults (persisted to `config/riosodu_shared.jkr`)
- `main.lua` - Library bootstrap (idempotent, gated on the `RIOSODU_SHARED` global)
- `utils/` - Utility functions and helpers
- `assets/` - Shared assets and resources
- `localization/` - Common localization utilities and shared strings
