# Balatro Mods Collection

## About This Project

Welcome to my Balatro mods collection! This repository houses all of my mods for the popular roguelike deckbuilder game Balatro. This is a personal hobby project that I'm passionate about.

## For Players

### Getting Started with Mods

There are several ways to install and use these mods:

1.  **Balatro Mod Manager (Recommended)**: The easiest way to install mods from this repository is through the [Balatro Mod Manager](https://github.com/skyline69/balatro-mod-manager/). This tool provides a user-friendly interface for browsing, installing, and managing mods.

2.  **Manual Installation**: You can also download mods directly from the releases tab of this repository. Each mod has its own folder with specific installation instructions in its README file.

### Important Notes for Players

-   **Clean Configuration on Updates**: When updating mods, it's recommended to clean your configuration files to prevent conflicts. This typically involves deleting or renaming the mod's configuration file in your Balatro save directory.

-   **Mod Compatibility**: Some mods may not be compatible with each other or with certain versions of Balatro. Always check the compatibility information in each mod's documentation. You can also open an issue if you encounter any problems or want me to add compatibility with another mod.

-   **Repository Navigation**:
    -   Each mod has its own directory in the repository
    -   The `_common` folder contains shared code used across multiple mods
    -   Check individual mod READMEs for specific features and configuration options

## Contributing

While this is primarily a personal project, I welcome feedback, bug reports, and suggestions through GitHub issues. For those looking to contribute code, please follow the development workflow outlined below.

### Development Workflow

This repository uses a CI/CD pipeline to automate versioning and releases. To contribute, please follow these steps to ensure your changes are compatible with the automation.

1. **Fork the Repository**: Create a fork of this repository on GitHub to work on your changes.
2. **Clone Your Fork**: Clone your fork to your local machine
3. **Setup libs**: Install the required libs and tools:
   ```bash
   chmod +x ./setup-libs.sh
   ```
4.  **Make Code Changes**: Edit the files for the mod(s) you are working on.

5.  **Update the Changelog**: This is the most important step. For every mod you changed, you **must** add a bullet describing your change under the existing `## [Unreleased]` section of its `CHANGELOG.md` (this includes `_common/` when changed). Two rules apply:
    *   The `[Unreleased]` section must be non-empty.
    *   Never add to or delete from already-released version blocks — historical entries are immutable. (Editing notes inside `[Unreleased]` is fine.)

6.  **Commit All Changes**:
    ```bash
    git add .
    git commit -m "Describe your new feature"
    ```

7.  **Push Your Changes**: Push to your fork and open a Pull Request to the `main` branch. A CI check will enforce the changelog rules above. You can run the same check locally first:
    ```bash
    ./scripts/check-changelogs.sh origin/main
    ```

### Local Testing (Linux)

To test your changes locally before committing:

1.  **Install Prerequisites**:
    -   Ensure you have `rsync`, `jq` and `7zip` installed.
    -   Install Balatro using Steam with compatibility mode (Proton).
2.  **Setup Lovely Injector**:
    -   Install the Lovely Injector by copying the DLL to your Balatro game folder.
3.  **Sync and Run**:
    -   Run `./sync-mods.sh && steam steam://rungameid/2379780` to sync your local changes to the game's mod folder and launch Balatro.

##### _Note: If you are on Windows, you can use WSL to run the above commands, or manually copy the files to your Balatro game folder. You can also contribute by creating a powershell script that performs the same actions._

---

Check the releases tab for each mod download. Installation instructions can be found in each mod folder's README.
