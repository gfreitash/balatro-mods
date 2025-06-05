# Balatro Mods Collection

## About This Project

Welcome to my Balatro mods collection! This repository houses all of my mods for the popular roguelike deckbuilder game Balatro. This is a personal hobby project that I'm passionate about, allowing me to combine my love for gaming with programming skills.

## For Players

### Getting Started with Mods

There are several ways to install and use these mods:

1. **Balatro Mod Manager (Recommended)**: The easiest way to install mods from this repository is through the [Balatro Mod Manager](https://github.com/skyline69/balatro-mod-manager/). This tool provides a user-friendly interface for browsing, installing, and managing mods.

2. **Manual Installation**: You can also download mods directly from the releases tab of this repository. Each mod has its own folder with specific installation instructions in its README file.

### Important Notes for Players

- **Clean Configuration on Updates**: When updating mods, it's recommended to clean your configuration files to prevent conflicts. This typically involves deleting or renaming the mod's configuration file in your Balatro save directory.

- **Mod Compatibility**: Some mods may not be compatible with each other or with certain versions of Balatro. Always check the compatibility information in each mod's documentation.

- **Repository Navigation**: 
  - Each mod has its own directory in the repository
  - The `_common` folder contains shared code used across multiple mods
  - Check individual mod READMEs for specific features and configuration options

## Repository Structure

- **Individual mod directories**: Each contains mod-specific code and assets
- **`_common/`**: Shared code library used across multiple mods
- **`lib/`**: Essential modding resources and documentation

## Contributing

While this is primarily a personal project, I welcome feedback, bug reports, and suggestions through GitHub issues.

### Setting Up Local Development (Linux)

To set up the development environment on Linux:

1. **Install Prerequisites**:
   - Ensure you have `rsync` installed (used by the sync script)
   - Install Balatro using Steam with compatibility mode (Proton)

2. **Setup Lovely Injector**:
   - Install the Lovely Injector by copying the DLL to your Balatro game folder (same as on Windows)

3. **Development Workflow**:
   - Fork this repo and clone it to your linux environment.
   - Make your changes to the mods.
   - Keep the changelog updated. You can make this more seamless by always annotating unreleased changes in the `##[Unreleased]` section
   - Run `./sync-mods.sh && steam steam://rungameid/2379780` to:
     * Sync your changes to the game's mod folder
     * Launch Balatro directly through Steam
   - Commit your changes and open a PR

---

Check the releases tab for each mod download. Installation instructions can be found in each mod folder's README.
