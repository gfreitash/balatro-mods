Balance and gameplay changes that feels good, configurable per feature. Bad mod name, too late now.

## Features

- **Easier Wheel of Fortune**: Configurable ease for the Wheel of Fortune tarot card. Adjust the chance of hitting the desired outcome (1 = 100% chance, 4 = vanilla 25% chance). Default is 3.
- **Wildcard Fix**: Prevents Wildcard and Smeared Joker from being negatively affected by suit debuffs when they could match a non-debuffed suit. When Paperback mod is installed, Smeared Joker considers light suits and dark suits, respectively, as the same suit.
- **Increased Shop Size**: Increases the base shop size by 1 (default is 2). This helps offset the dilution of the shop pool caused by other mods adding new cards and items.
- **Unweighted Base Editions**: Makes Foil, Holo, and Polychrome editions equally likely when rolled, while preserving the original probability of Negative editions.
- **Configurable 8 Ball Joker**: Adjust the chance of the 8 Ball Joker spawning Tarot cards (1 = 100% chance, 4 = vanilla 25% chance). Default is 3.
- **Configurable Space Joker** (beta): Adjust the chance of the Space Joker upgrading the played poker hand (1 = 100% chance, 4 = vanilla 25% chance). Default is 3.
- **Steel Joker Buff** (beta): Steel Joker gives X0.25 Mult per Steel Card in your deck (was X0.2).
- **Reworked Hit the Road Joker**: When enabled, discarded Jacks are returned to the deck alongside the current effect.
- **Square Joker Modification**: Reworks the Square Joker to give +2 chips if played hand has exactly 4 cards, with each scoring card having a 1 in 2 chance to add +4 more chips. Also changes rarity to Uncommon.
- **Flower Pot Wildcard Rework**: Flower Pot only appears in shop when Wildcard-enhanced cards exist in deck and triggers when scoring hand contains any Wildcard.
- **Baron Uncommon**: Makes Baron joker Uncommon rarity with reduced cost ($5 instead of $8).
- **Mime Rare**: Makes Mime joker Rare rarity with increased cost ($6 instead of $5).
- **DNA Uncommon** (beta): Makes DNA joker Uncommon rarity with reduced cost ($6 instead of $8).
- **Pareidolia Common** (beta): Makes Pareidolia joker Common rarity with reduced cost ($4 instead of $5).
- **Satellite Joker Rework**: Satellite now gives gold equal to half the highest poker hand level (rounded up).
- **Controlled Sigil**: Sigil now requires selecting a card first and converts all cards to selected card's suit instead of random suit.
- **Controlled Ouija**: Ouija now requires selecting a card first and converts all cards to selected card's rank instead of random rank.
- **Spectral Created Cards Can Have Seals** (beta): Cards created by Familiar, Grim and Incantation have a chance to come with a Seal (or a paper clip when Paperback is installed).
- **Loyalty Card Scaling Mode** (beta): Loyalty Card starts at X1 Mult, gains X0.5 Mult after finishing a blind, and redeems back to X2 after finishing a blind at X4.
- **Splash Joker Retrigger**: Splash Joker additionally retriggers two random scoring cards.
- **Ceremonial Dagger Common**: Makes Ceremonial Dagger joker Common rarity with reduced cost ($3 instead of $6).
- **Mail-In Rebate Uncommon**: Makes Mail-In Rebate joker Uncommon rarity (was Common rarity - makes it rarer).
- **Fortune Teller Cheaper**: Makes Fortune Teller joker cheaper (cost $4 instead of $6).
- **Erosion X Mult Rework**: Changes Erosion from +4 Mult per card to X0.175 Mult per card below starting amount.
- **Interest on Skip**: Gain interest when skipping blinds, calculated and awarded before obtaining the tag.
- **Paperback Compatibility**: Added compatibility for Paperback mod's Jester of Nihil joker and suit considerations for Smeared Joker.
- **Nerf Hanging Chad**: Makes Hanging Chad joker Uncommon rarity and more expensive (cost $7 instead of $6).
- **Castle Checkered Reliability**: Castle now counts either Clubs and Spades or Hearts and Diamonds. The suit group follows your deck composition, so suit fixing makes Castle more reliable and the checkered deck always counts the same group. If Paperback mod is installed, light suits or dark suits will be used instead.
- **Marble Joker X Chips**: Marble Joker keeps its original effect and also gains X0.1 Chips for every Stone card added to the deck (from any source, but not from in-place transformations).
- **Stone Joker Mult**: Stone Joker gives +4 Mult for each Stone Card in your full deck instead of +25 Chips.
- **Seance Rework** (beta): Seance triggers on Straight Flush or any secret hand (including modded ones) and is Rare ($8 instead of $6).
- **Canio Rework** (beta): Canio destroys scored face cards and gains X0.25 Mult per destroyed face card (the destroying is not blueprint compatible).
- **Onyx Agate Rework** (beta): Played Club cards permanently gain +3 Mult when scored.
- **Planet Merchant Rework** (beta): Planet Merchant and Planet Tycoon no longer boost the shop's Planet rate; instead each played hand has a 1 in 4 (Merchant) or 1 in 2 (Tycoon) chance to create its equivalent Planet card, if there is space.
- **Wraith Rework** (beta): Wraith creates a copy of a random Joker and makes every other Joker Perishable (Eternal Jokers are unaffected); it no longer creates a Rare Joker or sets money to $0.
- **Ankh Rework** (beta): Ankh removes all stickers (including modded ones) from all Jokers, then two random Jokers become Eternal.
- **The Lovers Two-Card Enhancement** (beta): The Lovers can enhance up to 2 selected cards into Wild Cards.
- **Hex Rework** (beta): Hex adds Polychrome and a random sticker to a random Joker instead of destroying the other Jokers.
- **Matador Rework** (beta): Matador earns $5 for each hand played during a Boss Blind, paid at the end of the round.
- **Red Card Rework** (beta): Red Card gains +1 Mult per Booster Pack opened and +2 Mult per Booster Pack skipped.
- **Bull Buff** (beta): Bull gives +3 Chips for each $1 (was +2).
- **Mr. Bones Rework** (beta): Mr. Bones always prevents Death, then self-destructs and Cripples the run (money set to $0, -1 Ante, -1 hand, -1 hand size, -1 discard) and costs $10.
- **Yorick Enhancement**: Yorick now gains a configurable amount (+1.5x for each 23 cards instead of +1x).
- **Reworked Magic Trick and Illusion Vouchers**: 
    - Magic Trick is now a "better" Illusion voucher with playing cards in shop appearing with enhancements, editions and seals (actually spawn instead of the bugged vanilla). 
    - Illusion now shows cards that are clones of cards in your deck with ability to reroll their enhancements, editions, and seals (but never lose them).
    - Improved shop card pricing accounts for enhancements, editions, and seals. Baseline is more expensive and can go up to $6
    - **Paper Clips Support**: Magic Trick and Illusion vouchers now may apply paper clips to shop playing cards (same as seals) when Paperback mod is installed.

## Installation

1.  **Requirements**: [Steamodded](https://github.com/Steamodded/smods) and [Lovely](https://github.com/ethangreen-dev/lovely-injector) (mod managers install both automatically)
2.  **Recommended**: Install from [Thunderstore](https://thunderstore.io/c/balatro/p/Riosodu/QoL_Bundle/) using the Thunderstore Mod Manager or r2modman
3.  **Manual**: Download the latest release and extract its contents into a new folder inside your Balatro `Mods` directory (e.g. `Mods/QoL_Bundle` on Windows: `%appdata%\Balatro\Mods`) — do not extract directly into the `Mods` root

## Support

For issues, suggestions, or contributions, please visit the [GitHub repository](https://github.com/gfreitash/balatro-mods).
