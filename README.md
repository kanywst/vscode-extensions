![vscode-extensions — track & reinstall your VS Code setup](assets/banner.png)

[![CI](https://github.com/kanywst/vscode-extensions/actions/workflows/ci.yml/badge.svg)](https://github.com/kanywst/vscode-extensions/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

_English | [日本語](README.ja.md)_

Track the VS Code extension list in git and reinstall the same set on any machine.

`extensions.list` holds the extension IDs. The scripts in `bin/` write it from the editor, install from it, and report drift.

## Why a git-tracked list

Settings Sync and exported Profiles already move extensions between machines, so why keep a plain-text list in git? Because it covers cases they don't:

- **Offline / air-gapped / provisioning scripts** — no account sign-in needed, just clone and run.
- **A reviewable baseline** — the set lives in git history and moves through PRs, not a personal cloud account.
- **Plain text** — `grep`, `diff`, and code review work on it directly.
- **Editor-agnostic** — the same scripts drive `code`, `codium`, or `cursor` via `CODE_BIN`.

Only extension IDs are tracked, not `settings.json` or keybindings — it's complementary to Settings Sync, not a replacement.

## Usage

### 1. Record this machine and push

`extensions.list` already holds the extensions on this machine. Commit it and push to your own remote.

```bash
git remote add origin git@github.com:<you>/vscode-extensions.git
git add -A
git commit -m "init: track vscode extensions"
git push -u origin main
```

### 2. Reproduce on another machine

Clone the repo and install everything in the list. The whole list installs in a single editor launch, and re-running is safe — installed extensions are skipped.

```bash
git clone git@github.com:<you>/vscode-extensions.git ~/vscode-extensions
cd ~/vscode-extensions
bin/install.sh
```

### 3. After adding or removing an extension

When you install or uninstall something in VS Code, re-export and commit the diff.

```bash
bin/export.sh
git add extensions.list
git commit -m "chore: update extensions"
```

`bin/export.sh` mirrors the currently installed set exactly, so this is also how you **prune** an extension from the list. To add newly installed extensions without ever removing any, use `bin/export.sh --merge`.

### Check for drift

Compare the installed extensions against `extensions.list`. Exits non-zero when they differ, so it fits a CI step or pre-commit hook.

```bash
bin/diff.sh
```

### Lint the list

Verify `extensions.list` is in canonical form (lowercased, sorted, de-duplicated, no stray lines). Needs no editor, so it also runs in CI.

```bash
bin/lint.sh
```

### Keep the list in sync automatically

Install the pre-commit hook so newly installed extensions are added to `extensions.list` and staged on every commit.

```bash
ln -s ../../bin/pre-commit .git/hooks/pre-commit
```

The hook uses `bin/export.sh --merge` on purpose: committing on a machine that only has a subset of the tracked set installed adds new extensions but **never removes** any, so it can't silently wipe the baseline. Prune deliberately with `bin/export.sh` (no flag).

## Using another editor

For a CLI other than `code` (Cursor, VSCodium, Insiders), set `CODE_BIN`.

```bash
CODE_BIN=cursor bin/export.sh
CODE_BIN=codium bin/install.sh
```

Note the registry difference: `code` installs from the VS Code Marketplace, while Cursor, VSCodium, and Windsurf install from Open VSX. An ID exported from one editor may not exist on the other's registry (some Microsoft extensions are Marketplace-only, and Cursor ships its own replacements under different IDs). `bin/install.sh` doesn't abort on those — it installs what it can and lists whatever the target editor couldn't find.

## Notes

- The `code` command must be on `PATH`. Add it from the Command Palette: `Shell Command: Install 'code' command in PATH`.
- Only extension IDs (`publisher.name`) are tracked, not `settings.json` or keybindings.
- `bin/install.sh` runs `code --install-extension --force`, which also updates an already-installed extension to the latest version.
- `extensions.list` is written lowercased and sorted so diffs stay clean.
