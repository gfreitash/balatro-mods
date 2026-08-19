# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.4.0] - 2026-08-19
### Added
- New "Retrigger Black Seal Effect" option: when disabled, the seal effect only fires on the first scoring of the card, so retriggers (e.g. Red Seal, Seltzer) no longer launch additional events. Enabled by default to preserve previous behavior.
- New "Keep Black Seals in Hand" option: when disabled, every black seal in the run is removed when one is triggered, including those in hand (e.g. from DNA). Enabled by default to preserve previous behavior.
- The seal's description now reflects whether black seals in hand are kept or removed.

### Fixed
- Fixed retriggered effects targeting a joker that a previously queued event already made negative; eligibility is now re-checked when the event executes.
- The seal is no longer consumed when no eligible joker exists at play time (no events are queued at all).

## [3.3.9] - 2026-08-19
### Changed
- Reworded the mod description and README to clarify the seal is a rare single-use seal that adds negative to a random joker.
- Documented that the spawn chance is absolute: the remaining seal pool's weights are normalized to stay proportional.

## [3.3.8] - 2026-08-17
### Changed
- Updated Riosodu Commons to v2.1.0.
- Riosodu Commons 2.1.0 adds a debug feature to swap the boss blind in the blind selection screen (keybind B, debug features only).

## [3.3.7] - 2026-08-17
### Changed
- Updated Riosodu Commons to v2.0.0.
- Riosodu Commons is no longer a standalone mod; fixes mods being disabled by default on launch when multiple mods bundle the shared library.

## [3.3.6] - 2025-10-23
### Changed
- Updated Riosodu Commons to v1.3.0.

## [3.3.5] - 2025-09-23
### Changed
- Updated Riosodu Commons to v1.2.4.

## [3.3.4] - 2025-09-02
### Changed
- Updated Riosodu Commons to v1.2.3.

## [3.3.3] - 2025-09-02
### Changed
- Updated Riosodu Commons to v1.2.2.

## [3.3.2] - 2025-09-01
### Fixed
- Fixed Ectoplasm text localization to use proper localization keys instead of hardcoded strings
- Fixed negative joker event timing by adding proper trigger configuration

### Changed  
- Updated Riosodu Commons to v1.2.0.
- Refactored debug keybind to use shared utility functions
- Moved Ectoplasm text updates to proper game initialization hook

### Added
- Added Black Seal tooltip integration showing Negative edition info

## [3.3.1] - 2025-07-30
### Fixed
- Fixed localization key naming to match SMODS convention for proper seal menu display
- Fixed negative joker effect timing by moving set_edition call inside event function

## [3.3.0] - 2025-07-29
### Added
- Added Portuguese (Brazil) localization

## [3.2.10] - 2025-07-07
### Changed
- Updated Riosodu Commons to v1.1.0.

## [3.2.9] - 2025-06-23

### Fixed
- The seal calculation now is properly done after initialization

## [3.2.8] - 2025-06-17
### Changed
- Updated Riosodu Commons to v1.0.5.

## [3.2.7] - 2025-06-17
### Changed
- Updated Riosodu Commons to v1.0.4.

## [3.2.6] - 2025-06-07
### Changed
- Updated Riosodu Commons to v1.0.3.

## [3.2.5] - 2025-06-06
### Changed
- Updated Riosodu Commons to v1.0.2.

## [3.2.4] - 2025-06-06
### Changed
- Updated Riosodu Commons to v1.0.1.

## [3.2.3] - 2025-06-06
### Changed
- Updated Riosodu Commons to v1.0.0.

## [3.2.2] 2025-05-25
### Added
- Added files for integration with Balatro Mod Manager

## [3.2.1] 2025-05-25
### Changed
- Made small negligible change to test CI workflow

## [3.2.0] 2025-04-26
### Added
- Added option to add a black seal to a card when the ectoplasm spectral card is applied, instead of directly applying negative
- Added an option to disable hand size reduction when the ectoplasm effect is overridden

## [3.1.1] 2025-04-25
### Fixed
- Fixed a bug where seals were not being properly cleaned

## [3.1.0] 2025-04-25
### Added
- Added a configurable spawn chance related to other seals

### Changed
- Updated mod file structure. Should have no impact for users

## [2.1.0] 2025-04-24
### Added
- Seals in hand are now kept, except played seal. Seals in deck are still removed

### Fixed
- Fixed bugs related to seals being removed even when the application was not successful

## [2.0.0] 2025-04-24
### Changed
- Updated to SMODS >1.0.0
