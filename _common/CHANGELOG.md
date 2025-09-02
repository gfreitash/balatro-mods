# Changelog

All notable changes to the Riosodu Commons shared library will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.1] - 2025-09-01

### Fixed
- Fixed dependency requirement spacing in sync-versions.sh script (added space after >=)

## [1.2.0] - 2025-09-01

### Added
- **Enhanced debug utilities**:
  - `add_joker_and_modify_cards()` function for comprehensive card manipulation during testing and debugging
  - `print_table()` function with configurable depth and circular reference detection for better debugging output
  - Interactive joker input textbox system (F10 key) for adding jokers by key during debugging
  - Visual "nope" animation for failed debug operations
- **Localization system improvements**:
  - New `on_localization_reload` hook system for dynamic localization updates without game restart
  - Override system for `init_localization()` function to trigger custom localization hooks
- **Enhanced UI components**:
  - `requires_restart` option for configuration toggles with visual warning indicator
  - Automatic localized warning text for settings that require game restart
- **Core infrastructure additions**:
  - `RIOSODU_SHARED.original` namespace for storing original function references safely
  - `overrides.lua` system for global function overrides with proper chaining
  - `utils/utils.lua` include structure prepared for future utility expansions
- **Interest system rebalancing** (moved from rebalanced-stakes):
  - Interest calculation now starts at $1 instead of $5 (configurable via `interest_base = 5`)
  - Interest calculations now use dynamic `interest_base` instead of hardcoded values
  - Seed Money and Money Tree vouchers maintain same effective interest caps but use new calculation system
  - Comprehensive Lovely Injector patches for interest system modifications

### Changed
- **Hook system expansion**: Extended hooks table to include `on_localization_reload` events alongside existing `on_game_start`
- **Game start detection**: Improved hook trigger condition from `G.STATE == G.STATES.MENU` to `G.STAGE == G.STAGES.MAIN_MENU` for more reliable game state detection
- **Initialization order**: Added `overrides.lua` loading after hook system setup to ensure proper override chaining

## [1.1.0] - 2025-07-07
### Added
- Compatibility layer for SMODS GUI dynamic area

### Changed
- Updated `RIOSODU_SHARED.UIDEF.create_option_box` to use have a bigger padding and emboss

## [1.0.5] - 2025-06-17
This is a patch release to force update the dependent mods to ensure the use of the new `latest` syntax after CI fix.

## [1.0.4] - 2025-06-17
This is a patch release to force update the dependent mods to ensure the use of the new `latest` syntax.

## [1.0.3] - 2025-06-07
This is a patch release to force update the dependent mods to ensure the correct dependency syntax.

## [1.0.2] - 2025-06-06
This is a patch release to force update the dependent mods to ensure the CI is working correctly.

## [1.0.1] - 2025-06-06
This is a patch release to force update the dependent mods to ensure the CI is working correctly.

## [1.0.0] - 2025-06-05

This is the initial versioned release of the Riosodu Commons shared library, consolidating features developed across several mods.

### Added

-   **Event Hook System**
    -   Introduced a simple event hook system (`RIOSODU_SHARED.hooks`).
    -   Added an `on_game_start` hook, allowing mods to safely run code once the game's main menu is loaded.

-   **Mod Utilities**
    -   Added the `RIOSODU_SHARED.include_mod_file` utility function to provide a standardized way for mods to load their own Lua files.

-   **Centralized Debug System**
    -   Created a shared debug system (`debug.lua`) with a central logger (`RIOSODU_SHARED.utils.sendDebugMessage`) and keybind registration (`RIOSODU_SHARED.debug.register_keybind`).
    -   Added a shared configuration file (`config.lua`) to enable or disable debug features globally across all dependent mods.

-   **Shared UI Components**
    -   Created a reusable settings tab (`ui/tabs.lua`) to display and manage the shared debug configuration options.
    -   Extracted and centralized a UI component library (`ui/components.lua`) with helper functions for creating standard option boxes, toggles, and sliders.

-   **Core Library Structure**
    -   Established the core initialization logic (`main.lua`) and manifest (`common.json`) for the shared library.
    -   Created the initial `_common/README.md` to document the library's purpose and structure.

### Changed

-   **Debug Logger Improvement**
    -   Improved the `sendDebugMessage` function by making the `mod_id` parameter optional and improving the argument order for better usability.

-   **Load Priority**
    -   Set the mod `priority` to `-1` in `common.json` to ensure the shared library always loads before any dependent mods, preventing initialization errors.
