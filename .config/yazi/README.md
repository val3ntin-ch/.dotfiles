# Yazi — File Manager

Terminal file manager with full preview support (images, video, PDF, archives),
plugin system, and Catppuccin Mocha theming.

---

## Table of Contents

1. [Features](#features)
2. [Plugins](#plugins)
3. [Keybindings](#keybindings)
4. [Image preview](#image-preview)

---

## Features

- Three-pane layout (1:2:4 ratio), dirs first
- Git status via `git.yazi` plugin (linemode decorations)
- Fast MIME detection via `mime-ext.yazi` (extension DB, not `file(1)`)
- Size linemode, symlink display, scrolloff=5
- Catppuccin Mocha via `theme.toml` + `Catppuccin-mocha.tmTheme` (bat syntax)

---

## Plugins

Plugins installed via `ya pkg install` (reads `package.toml`). Not committed — reinstall on new machine.

| Plugin | Key | Description |
|---|---|---|
| `git.yazi` | — | Git status in file listing |
| `mime-ext.yazi` | — | Fast MIME detection |
| `smart-filter.yazi` | `f` | Live filter with regex |
| `jump-to-char.yazi` | `F` | Jump to file by first char |
| `chmod.yazi` | `gx` | Change file permissions |
| `diff.yazi` | `gd` | Diff selected files |

---

## Keybindings

Custom bindings (in addition to yazi defaults):

| Key | Action |
|---|---|
| `f` | Smart filter |
| `F` | Jump to char |
| `gd` | Diff selected |
| `gx` | Chmod selected |
| `Ctrl+h` | Toggle hidden files |
| `!` | Open shell in current dir |

---

## Image preview

Yazi detects the best available image protocol:

| Context | Protocol | Quality |
|---|---|---|
| Ghostty (direct) | Kitty Graphics Protocol | Full resolution |
| Inside herdr | Kitty Graphics Protocol, passed through by herdr (`[terminal] kitty_graphics = true`) | Full resolution |

---

