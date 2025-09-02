# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.7.2] - 2025-09-02
### Changed
- Updated Riosodu Commons to v1.2.2.

## [1.7.1] - 2025-09-01
### Changed
- Updated Riosodu Commons to v1.2.1.

## [1.7.0] - 2025-09-01
### Added
- Flower Pot Wildcard Rework: Flower Pot now only appears in shop when Wildcard-enhanced cards exist in deck and triggers when scoring hand contains any Wildcard
- Baron Uncommon: Made Baron joker Uncommon rarity with reduced cost ($5 instead of $8)
- Mime Rare: Made Mime joker Rare rarity with increased cost ($6 instead of $5)  
- Satellite Joker Rework: Satellite now gives gold equal to half the highest poker hand level (rounded down)
- Controlled Sigil: Sigil now requires selecting a card first and converts all cards to selected card's suit instead of random suit
- Controlled Ouija: Ouija now requires selecting a card first and converts all cards to selected card's rank instead of random rank
- Loyalty Card Rounds Mode: Loyalty Card triggers based on rounds instead of hands played for more predictable timing and easier to plan around
- Splash Joker Retrigger: Splash Joker additionally retriggers a random scoring card
- Ceremonial Dagger Common: Made Ceremonial Dagger joker Common rarity with reduced cost ($3 instead of $6)
- Mail-In Rebate Uncommon: Nerfed Mail-In Rebate joker to Uncommon rarity (was Common rarity - makes it rarer)
- Fortune Teller Cheaper: Made Fortune Teller joker cheaper (cost $4 instead of $6)
- Erosion X Mult Rework: Changed Erosion from +4 Mult per card to X0.2 Mult per card below starting amount
- Interest on Skip: Gain interest when skipping blinds, calculated and awarded before obtaining the tag
- Paperback mod compatibility for jester_of_nihil joker

### Changed
- Updated Riosodu Commons to v1.2.0.
- Hit the Road and Square jokers now use dynamic localization that updates based on configuration
- Flower Pot, Satellite, Loyalty Card, Splash, and Erosion jokers now use dynamic localization that updates based on configuration  
- Sigil and Ouija spectral cards now use dynamic localization that updates based on configuration
- Reduced option boxes per page from 4 to 3 for better UI layout
- Refactored debug functions to use shared utilities from Riosodu Commons

## [1.6.3] - 2025-08-17
### Fixed
- More fixes to Hit the Road joker: more randomness to shuffle and prevent blueprint from drawing jacks again

## [1.6.2] - 2025-08-17
### Fixed
- Fixed the card duplication caused by drawing Jacks incorrectly when using Hit the Road Joker

## [1.6.1] - 2025-07-30
### Fixed
- Fixed configuration description for the wildcard fix to specify that it only prevent debuffs from suit debuffs

## [1.6.0] - 2025-07-30
### Changed
- Square Joker mechanics completely reworked again. From static 16 chips to dynamic 4 base + 1 in 2 chance to add +4 more chips per scoring card


### Fixed
- Hit the Road Joker configuration description now clarifies new effect is added alongside original
- Improved localization text formatting consistency

## [1.5.0] - 2025-07-29
### Added
- Added Portuguese (Brazil) localization

## [1.4.0] - 2025-07-07
### Added
- Added pagination to the settings tab, allowing users to navigate through multiple pages of configuration options.
- Added overhaul to the square joker
- Added "Nerf Photochad" configuration, making Photograph and Hanging Chad jokers Uncommon rarity.

### Changed
- Updated Riosodu Commons to v1.1.0.
- Updated README to reflect missing implmented features.

## [1.3.0] - 2025-06-23
### Added
- 8 Ball Joker Configuration: Introduced options to enable/disable and adjust the chance of the 8 Ball Joker spawning Tarot cards.
- Hit the Road Joker Rework: Implemented a rework for the Hit the Road Joker, allowing discarded Jacks to be returned to the deck alongside the current effect.

### Changed
- `Card:is_suit`: Commented out debug messages in the `Card:is_suit` function for cleaner output.

## [1.2.0] - 2025-06-23
### Added
- Wheel of Fortune no longer requires a restart to apply configuration changes

### Fixed
- Cleaned up the codebase to remove unused statements
- Moved code around to improve maintainability

## [1.1.3] - 2025-06-17

### Changed
- Test change (removed update note)

## [1.1.2] - 2025-06-17

### Changed
- Updated Riosodu Commons to v1.0.4.

## [1.1.1] - 2025-06-17

### Changed
- Updated README.md with description for Unweighted Base Editions.

## [1.1.0] - 2025-06-15

### Added
- Unweighted Base Editions: Implemented functionality to make Foil, Holo, and Polychrome editions equally likely when rolled, while preserving the original probability of Negative editions.


## [1.0.4] - 2025-06-07

### Changed
- Updated Riosodu Commons to v1.0.3.

## [1.0.3] - 2025-06-06

### Changed
- Updated Riosodu Commons to v1.0.2.

## [1.0.2] - 2025-06-06

### Changed
- Updated Riosodu Commons to v1.0.1.

## [1.0.1] - 2025-06-06

### Changed
- Updated Riosodu Commons to v1.0.0.

## [1.0.0] 2025-06-05
### Added
- Easier Wheel of Fortune functionality
- Wildcard/Smeared Joker fix
- Increased shop size by 1
- Initial README.md
- Initial manifest.json
- Initial localization (English)
- Initial CHANGELOG.md
- Initial index.meta.json
