---
name: gdscript-lint
description: "Run GDScript formatting and lint checks using gdtoolkit (gdformat + gdlint). Use before committing GDScript code."
disable-model-invocation: true
allowed-tools:
  - Bash
  - Glob
  - Read
---

# GDScript Lint

Run gdtoolkit checks on GDScript files.

## Quick Start

```bash
gdformat --check .   # Check formatting (exit 1 if violations)
gdlint .             # Check lint rules (member ordering, naming, etc.)
```

## Auto-Fix

```bash
gdformat .           # Fix formatting in place
```

gdlint has no auto-fix — violations must be fixed manually.

## Prerequisites

```bash
pipx install "gdtoolkit==4.*"
```

Requires Python 3. On macOS, install via Xcode CLT or Homebrew.
