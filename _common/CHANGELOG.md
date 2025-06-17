# Changelog

All notable changes to the Riosodu Commons shared library will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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