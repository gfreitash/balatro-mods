# Balatro Mods Collection

## About This Project

Welcome to my Balatro mods collection! This repository houses all of my mods for the popular roguelike deckbuilder game Balatro. This is a personal hobby project that I'm passionate about.

## For Players

### Getting Started with Mods

The easiest way to install these mods is through [Thunderstore](https://thunderstore.io/c/balatro/):

1.  **Thunderstore Mod Manager / r2modman (Recommended)**: Install a mod manager from [get.thunderstore.io](https://get.thunderstore.io/), select Balatro, and search for `Riosodu`. Steamodded and Lovely are installed automatically as dependencies.

2.  **Manual Installation**: You can also download the latest package from the releases tab of this repository. Thunderstore packages are flat zips: extract the contents into a new folder inside your Balatro `Mods` directory (e.g. `Mods/QoL_Bundle`), and make sure [Steamodded](https://github.com/Steamodded/smods) and [Lovely](https://github.com/ethangreen-dev/lovely-injector) are installed.

### Mods

| Mod | Thunderstore | Description |
| --- | --- | --- |
| QoL Bundle | [`Riosodu-QoL_Bundle`](https://thunderstore.io/c/balatro/p/Riosodu/QoL_Bundle/) | Balance and gameplay changes, configurable per feature |
| Black Seal | [`Riosodu-Black_Seal`](https://thunderstore.io/c/balatro/p/Riosodu/Black_Seal/) | Adds a rare single use seal that adds negative to a random joker |
| Rebalanced Stakes | [`Riosodu-Rebalanced_Stakes`](https://thunderstore.io/c/balatro/p/Riosodu/Rebalanced_Stakes/) | Reworks the higher stakes for a smoother difficulty curve |

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
    -   Ensure you have `rsync`, `jq`, `zip` and `7zip` installed.
    -   Install Balatro using Steam with compatibility mode (Proton).
2.  **Setup Lovely Injector**:
    -   Install the Lovely Injector by copying the DLL to your Balatro game folder.
3.  **Sync and Run**:
    -   Run `./sync-mods.sh && steam steam://rungameid/2379780` to sync your local changes to the game's mod folder and launch Balatro. Mods are installed under their Thunderstore package name (e.g. `Mods/QoL_Bundle`).

To test the exact Thunderstore artifact (including the bundled shared library and lovely patches):

```bash
./scripts/build-thunderstore-package.sh qol-bundle
# then install dist/qol-bundle__vX.Y.Z.zip via your mod manager's "Install from file" option,
# or extract it into a new folder inside your Balatro Mods directory
```

#### Integration Test Runs

The repository ships an end-to-end test harness that runs [BalatroIntegration](https://github.com/V-rtualized/BalatroIntegration) suites inside a real Balatro session (190 main tests + 13 Paperback-mode tests). Every launch builds a **clean Mods folder**: it backs up what it will wipe (Mods entries + your `config/`) to `lib/mod_folder_snapshots/`, wipes everything except `lovely/`, and installs exactly the declared mods plus the test infrastructure.

```bash
./scripts/run-integration-tests.sh --keep-open riosodu                          # full suite (PB-free)
./scripts/run-integration-tests.sh --keep-open --pb                             # Paperback-mode suite
./scripts/run-integration-tests.sh --dry-run                                    # show what a run would install/wipe
./scripts/run-integration-tests.sh --attach "riosodu/qol_bundle/hit_the_road"  # fast re-run in the live session
./scripts/run-integration-tests.sh --teardown                                   # run, then restore the pre-session state
./scripts/test-mods.sh teardown                                                 # restore the pending backup (game closed)
./scripts/check-test-evidence.sh qol-bundle black-seal rebalanced-stakes        # verify release evidence
```

Mods are declared as parameters, for example:

```bash
--mods "local:qol-bundle,thunderstore:PaperbackedProjects-Paperback@0.9.1,github:gfreitash/balatro-mods::qol-bundle/"
```

Specs: `local:<dir>`, `thunderstore:<ns>-<name>[@<ver>]`, `github:<owner>/<repo>[@<ref>][::<subdir>]`, `github-release:<owner>/<repo>@<tag>#<asset>`. Run `scripts/test-mods.sh --help` for the plan/setup/clean/status/prune commands.

Successful runs that cover a full suite also write a machine-readable report to `test-reports/`. Releases are gated on it: CI (and `./scripts/check-test-evidence.sh <mod>...`) verifies that a passing report exists whose content fingerprint still matches the code being released. Version bumps and changelog edits don't invalidate a report, but any change to mod code, tests, or the harness does — so commit a fresh report with your changes.

##### _Note: If you are on Windows, you can use WSL to run the above commands, or manually copy the files to your Balatro game folder. You can also contribute by creating a powershell script that performs the same actions._

## Thanks

- **infarctus** for creating the original Black Seal mod (ported and maintained here as [Black Seal](black-seal)).
- [**V-rtualized**](https://github.com/V-rtualized) for creating [BalatroIntegration](https://github.com/V-rtualized/BalatroIntegration), the integration testing framework that powers this repository's test suites.

---

Check the releases tab for each mod download, or install everything from [Thunderstore](https://thunderstore.io/c/balatro/). Installation instructions can be found in each mod folder's README.
