---
layout: default
title: Coding Standards
nav_order: 9
---

This project follows the standard Nix formatting and conventions.

## Formatting

All Nix code is formatted using `alejandra`.

## Naming Conventions

- **Hosts**: Hostnames should be lowercase and descriptive.
- **Modules**: Module files should be named after the main option they provide.
- **Packages**: Custom packages should be named according to the upstream package name.

## Best Practices

- Keep configurations modular and reusable.
- Use comments to explain complex or non-obvious code.
- Avoid hardcoding values; use variables and function arguments instead.
