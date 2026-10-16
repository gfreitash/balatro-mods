# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.10] - 2026-10-16
### Fixed
- Perishable Jokers are now debuffed the moment they expire, matching vanilla: a perishable Golden Joker (or any joker with an end-of-round dollar bonus) no longer pays its bonus on the round it expires.

### Changed
- Updated Riosodu Commons to v2.2.0.
- Riosodu Commons 2.2.0 adds a debug feature to swap the first card in the shop for a joker (keybind Q, debug features only).
- Clarified README wording: shop Joker restrictions are *introduced* earlier (Perishable at Blue, Rental at Orange) and keep applying at later stakes.

## [1.3.9] - 2026-10-14
### Changed
- Relaxed the required Lovely Injector version to v0.9.0 (the mod uses no 0.10.0-only features).

## [1.3.8] - 2026-10-13
### Changed
- Migrated distribution to ThunderStore (`Riosodu-Rebalanced_Stakes`); GitHub releases now ship a ThunderStore-compatible package.
- Added explicit Steamodded and Lovely dependencies to the mod metadata.

## [1.3.7] - 2026-08-17
### Changed
- Updated Riosodu Commons to v2.1.0.
- Riosodu Commons 2.1.0 adds a debug feature to swap the boss blind in the blind selection screen (keybind B, debug features only).

## [1.3.6] - 2026-08-17
### Changed
- Updated Riosodu Commons to v2.0.0.
- Riosodu Commons is no longer a standalone mod; fixes mods being disabled by default on launch when multiple mods bundle the shared library.

## [1.3.5] - 2025-10-23
### Changed
- Updated Riosodu Commons to v1.3.0.


## [1.3.4] - 2025-09-23

### Changed
- Updated Riosodu Commons to v1.2.4.
- Updated to use Talisman-compatible math functions from Riosodu Commons for better mod compatibility with large number handling

## [1.3.3] - 2025-09-02
### Changed
- Updated Riosodu Commons to v1.2.3.

## [1.3.2] - 2025-09-02
### Changed
- Updated Riosodu Commons to v1.2.2.

## [1.3.1] - 2025-09-01
### Changed
- Updated Riosodu Commons to v1.2.1.

## [1.3.0] - 2025-09-01
### Added
- Perishable jokers now become negative when they expire alongside being debuffed

### Changed
- Updated Riosodu Commons to v1.2.0.
- Interest system modifications via lovely patches moved to Riosodu Commons (_common module) for broader compatibility

## [1.2.10] - 2025-07-07
### Changed
- Updated Riosodu Commons to v1.1.0.

## [1.2.9] - 2025-06-17

### Changed
- Updated Riosodu Commons to v1.0.5.

## [1.2.8] - 2025-06-17

### Changed
- Updated Riosodu Commons to v1.0.4.

## [1.2.7] - 2025-06-07

### Changed
- Updated Riosodu Commons to v1.0.3.

## [1.2.6] - 2025-06-06

### Changed
- Updated Riosodu Commons to v1.0.2.

## [1.2.5] - 2025-06-06

### Changed
- Updated Riosodu Commons to v1.0.1.

## [1.2.4] - 2025-06-06

### Changed
- Updated Riosodu Commons to v1.0.0.

## [1.2.3] 2025-06-04
### Fixed
- Fixed improper version tagging in CHANGELOG

## [1.2.2] 2025-06-04
### Fixed
- Fixed initialization of the mod

### Added
- Added debug logs for initialization

## [1.2.1] 2025-06-04
### Added
- Added integration for mod-index

## [1.2.0] 2025-06-04
### Changed
- Updated README
- Migrated to take_ownership instead of lovely patches
- Removed Lovely patches for stake modifications
