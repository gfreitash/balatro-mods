# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Ankh rework (beta): now removes only the vanilla Eternal, Perishable and Rental stickers. Modded stickers and Pinned are left untouched, and the tooltip uses each sticker's badge colour.

### Fixed
- Ankh rework (beta): removing an expired Perishable Joker now clears its disabled state, and removing a Rental restores the Joker's cost and sell value.

## [1.13.1] - 2026-10-22
### Added
- Strength rework (beta): requires selecting 2 cards; the lower rank card is raised to the higher rank.

### Changed
- Canio rework (beta): now destroys played face cards (including cards outside the scoring hand) and gains X0.5 Mult per destroyed face card (was X0.25).
- Yorick's default multiplier is now X1.23 (was X1.5).
- Updated the Mr. Bones, Matador, Splash and Loyalty Card tooltips.
- Ankh's cleanup now juices each Joker whose stickers are removed, then the two newly Eternal Jokers, in order.

## [1.13.0] - 2026-10-22
### Added
- Planet Merchant rework (beta): Planet Merchant and Planet Tycoon now replace their shop Planet-rate bonus with a chance to create the played hand's equivalent Planet card (1 in 4 for Planet Merchant, 1 in 2 for Planet Tycoon, which replaces Planet Merchant's effect). Nothing is created when the consumable area is full or the hand has no equivalent Planet.
- Wraith rework (beta): creates a copy of a random Joker and makes every other Joker Perishable (Eternal Jokers excluded). The random Rare Joker and the money-to-$0 clause were removed.
- Ankh rework (beta): removes all stickers (including modded ones) from all Jokers, then two random Jokers become Eternal.
- The Lovers two-card enhancement (beta): The Lovers now enhances up to 2 selected cards into Wild Cards.
- Hex rework (beta): still adds Polychrome to a random Joker, but now also gives that same Joker a random applicable sticker instead of destroying the other Jokers.
- Matador rework (beta): earns $5 for each hand played during a Boss Blind, paid at the end of the round like Satellite.
- Red Card rework (beta): gains +1 Mult for each Booster Pack opened and +2 Mult for each Booster Pack skipped.
- Bull buff (beta): gives +3 Chips for each $1 (was +2).
- Mr. Bones rework (beta): always prevents Death, then self-destructs and Cripples the run (money set to $0, -1 Ante, -1 hand, -1 hand size, -1 discard); costs $10.

### Changed
- Onyx Agate rework (beta): scored Clubs now permanently gain +3 Mult (was +5).

### Fixed
- Seance rework (beta): only a hand that actually matched the played hand can trigger it. Previously every played hand triggered, because undiscovered secret hands are always listed (as empty entries) in the scoring context; this also removes a potential `handname 'top' not found!` crash when the internal `top` marker reached the poker-hand visibility check.

## [1.12.3] - 2026-10-16
### Fixed
- Hit the Road rework: the deck shuffle now runs after the discarded Jacks are returned to the deck, so repeated discards no longer draw back the same Jacks in the same order.
- Fixed a potential crash in the 8 Ball and Space Joker value callbacks when the game loaded with that feature disabled (the callback indexed a state object that was never created).
- Fixed the same potential crash in the Wheel of Fortune value callback when the game loaded with the Wheel rework disabled (the callback indexed a state object that was never created).
- Wildcard fix: Paperback's Da Capo joker no longer debuffs Wild Cards or same-shade cards under Smeared Joker (the boss-debuff protection now only intercepts the boss's own suit check instead of every suit check made while the blind evaluates debuffs). One known edge remains: when Da Capo's rotating suit matches the boss's debuffed suit, the two checks are indistinguishable and those cards are still debuffed by Da Capo.

### Changed
- Updated Riosodu Commons to v2.2.0.
- Riosodu Commons 2.2.0 adds a debug feature to swap the first card in the shop for a joker (keybind Q, debug features only).

## [1.12.2] - 2026-10-14
### Fixed
- Fixed a crash in the Onyx Agate beta rework when a Club scored: the effect returned the Joker center instead of the card, causing a `juice_up` error during scoring.
- Fixed the same latent crash in the Seance beta rework when it triggered on a secret hand.

## [1.12.1] - 2026-10-14
### Changed
- Relaxed the required Lovely Injector version to v0.9.0 (the mod uses no 0.10.0-only features).

## [1.12.0] - 2026-10-14
### Added
- Beta features: options can now be marked as beta, appearing in orange in the config menu and shipping disabled by default.
- Configurable Space Joker (beta): its level-up chance is now adjustable, defaulting to 1 in 3.
- Steel Joker buff (beta): now gives X0.25 Mult per Steel Card (was X0.2).
- Spectral created cards can have seals (beta): cards created by Familiar, Grim and Incantation have a chance to come with a Seal, and with a paper clip when Paperback is installed.
- Marble Joker now also gains X0.1 Chips for every Stone card added to the deck (any source, including its own effect, shops, packs and DNA, but not in-place transformations).
- Seance rework (beta): triggers on Straight Flush or any secret hand (including modded ones) and is now Rare ($8 instead of $6).
- Canio rework (beta): destroys scored face cards and gains X0.25 Mult per destroyed face card (the destroying is not blueprint compatible).
- Onyx Agate rework (beta): played Club cards permanently gain +5 Mult when scored.

### Changed
- 8 Ball Joker now defaults to a 1 in 3 chance (was 1 in 4).
- Square Joker now gives +2 Chips on 4-card hands (was +4); each scoring card still has a 1 in 2 chance to give +4 more Chips.
- Loyalty Card rework (third iteration, beta): now a scaling Joker that starts at X1 Mult, gains X0.5 Mult after finishing a blind, and redeems back to X2 after finishing a blind at X4. The rounds mode and cheat-on-skip mechanics were removed.
- Stone Joker now gives +4 Mult for each Stone Card in the full deck instead of +25 Chips.
- Erosion now scales at X0.175 Mult per card below starting amount (was X0.15).
- DNA is now Uncommon rarity ($6 instead of $8) and Pareidolia is now Common rarity ($4 instead of $5) (both beta, disabled by default).
- Updated Erosion's documentation and config info to match its scaling value.

## [1.11.2] - 2026-10-14
### Fixed
- Fixed a crash on run start with Paperback 0.9.0+ when the Castle rework was enabled: Paperback removed `PB_UTIL.is_suit`, so suit shade checks now use Steamodded's suit shade metadata (`SMODS.Suits`) with Paperback fallbacks.
- Smeared Joker with the wildcard fix no longer treats light and dark suits as the same suit (e.g. a Spades card matching a Stars card), and suitless cards (e.g. Stone Cards) no longer match any suit.
- Removed the legacy `PB_UTIL.is_suit` wrapper that broke Paperback's Da Capo joker.

## [1.11.1] - 2026-10-13
### Changed
- Migrated distribution to ThunderStore (`Riosodu-QoL_Bundle`); GitHub releases now ship a ThunderStore-compatible package.
- Added explicit Steamodded and Lovely dependencies to the mod metadata.

## [1.11.0] - 2026-09-03
### Added
- Loyalty Card Rounds Mode: Loyalty Card now triggers by rounds instead of hands, becoming active for a whole round after every 3 rounds played. Skipping a blind counts twice toward the next activation, but raises the chance of the card being permanently disabled on that redeem (a clean redeem lowers it again).

### Fixed
- Castle no longer activates on one extra opposite suit (#10).

### Changed
- Castle's suit group now follows your deck composition, so suit fixing makes Castle increasingly reliable and a checkered deck always counts the same group.

## [1.10.2] - 2026-08-28
### Fixed
- Fixed the Erosion rework not applying (ownership function failing to load).

## [1.10.1] - 2026-08-19
### Changed
- Reworded the mod description (manifest and README) to reflect that the mod provides balance and gameplay changes, configurable per feature.

## [1.10.0] - 2026-08-17
### Changed
- Magic Trick voucher now uses a separate localization string when Paperback is present, showing that shop cards can also appear with paper clips.
- Added `1.23` option to the Yorick X-mult cycle. A nod to the 23 years Yorick was buried, so `x1.23` Mult.
- Removed trailing periods from localization text, since vanilla Jokers don't use periods in their descriptions.
- Improved localization wording.

## [1.9.4] - 2026-08-17
### Changed
- Updated Riosodu Commons to v2.1.0.
- Riosodu Commons 2.1.0 adds a debug feature to swap the boss blind in the blind selection screen (keybind B, debug features only).

## [1.9.3] - 2026-08-17
### Changed
- Wildcard/Smeared fix no longer relies on a lovely patch: it is now applied dynamically via the Blind:debuff_card override, so toggling it no longer requires a restart.
- Fixed boss debuffs (e.g. Crimson Heart, modded bosses) being broken by the outdated Blind:debuff_card override; the modern implementation (recalc_debuff callbacks, crimson_heart_chosen) is preserved.
- Card:is_suit now delegates to the Steamodded-aware implementation for non-wildcard cases, restoring compatibility with modded suits.
- Updated Riosodu Commons to v2.0.0.

## [1.9.2] - 2026-08-17
### Changed
- Updated Riosodu Commons to v2.0.0.
- Riosodu Commons is no longer a standalone mod; fixes mods being disabled by default on launch when multiple mods bundle the shared library.

## [1.9.1] - 2025-11-24
### Fixed
- Fixed missing talisman safe comparison in the satellite joker (closes #4)
- Updates the label in the interest on skip option to show that it requires a restart to apply

## [1.9.0] - 2025-10-23
### Changed
- Updated Riosodu Commons to v1.3.0.
- Splash joker now retriggers two random scoring cards instead of one (when retrigger option is enabled)
- Satellite joker rounds up instead of down when calculating half poker hand level for gold reward

### Fixed
- Fixed Satellite joker not triggering at the round evaluation screen
- Fixed Satellite joker causing performance issues due to being evaluated in wrong context
- Fixed Satellite joker evaluating multiple times per round
- Fixed Hit the Road shuffle seed to include total hands played for better uniqueness and consistency
- Fixed clipping in the config UI

## [1.8.4] - 2025-09-23
### Changed
- Updated Riosodu Commons to v1.2.4.
- Updated interest calculation logic to use Talisman-compatible math functions from Riosodu Commons for better mod compatibility

## [1.8.3] - 2025-09-18
### Fixed
- Fixed Ouija not applying correctly and causing crashes due to incorrect key string

## [1.8.2] - 2025-09-16
### Fixed
- Fixed wildcard fix regression where wildcards were still being debuffed by suit-based blinds

## [1.8.1] - 2025-09-11
### Fixed
- Fixed crash when using Ouija or Sigil

## [1.8.0] - 2025-09-08
### Added
- Castle now counts either Clubs and Spades or Hearts and Diamonds. Make it as reliable as in the checkered deck.
- If Paperback mod is installed, light suits or dark suits will be used instead.
- **Reworked Magic Trick and Illusion Vouchers**:
  - Magic Trick is now a "better" Illusion voucher, and Illusion's new goal is to upgrade your existing deck cards.
  - Enhanced Magic Trick voucher: playing cards in shop may appear with enhancements, seals and editions 
    - Seals now actually spawn, instead of the buggy vanilla Illusion voucher
  - New Illusion voucher: playing cards in shop are clones of cards in your deck with ability to reroll their enhancements, editions, and seals (but never lose them)
  - Improved shop card pricing for playing cards that accounts for enhancements, editions, and seals
  - Paperback compatibility for paper clips. Cards in shop can now get paper clips (same chance as seals),when Paperback mod is installed.

### Changed
- Nerfed Erosion to have a 0.15X mult per card below starting amount (was 0.2X)
- Yorick now gain a configurable amount (+1.5x for each 23 cards instead of +1x
- Smeared Joker now considers Crowns/Stars if Paperback mod is installed

### Fixed
- Removed `requires_restart = true` from Unweighted Editions option as it was not needed


## [1.7.2] - 2025-09-02
### Changed
- Updated Riosodu Commons to v1.2.3.

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
