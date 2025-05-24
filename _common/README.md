# Common Code Library

This directory contains shared code and resources that are used across multiple mods in the Balatro Modding Mono Repository.

## Purpose

The `_common` folder serves as a centralized location for reusable components, utilities, and assets that can be shared between different mods. This helps maintain consistency and reduces code duplication.

## Usage

When a mod is released via the CI/CD pipeline, the contents of this folder are automatically included as a subfolder named `common` inside the mod's directory.

## Guidelines

When adding code to this directory:

1. Ensure it's truly reusable across multiple mods
2. Document the purpose and usage of each component
3. Follow consistent naming conventions
4. Test compatibility with existing mods

## Structure

- `utils/` - Utility functions and helpers
- `assets/` - Shared assets and resources
- `localization/` - Common localization utilities and shared strings
