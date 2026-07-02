# Ghostty Terminal Configuration

A GPU-accelerated terminal emulator by Mitchell Hashimoto. Minimal config —
Ghostty has sensible defaults for almost everything. Only deviations from
defaults are committed.

---

## Table of Contents

1. [How Ghostty reads config](#how-ghostty-reads-config)
2. [Config reference](#config-reference)
3. [Shell integration](#shell-integration)
4. [Font setup](#font-setup)
5. [Themes](#themes)
6. [Keybindings](#keybindings)
7. [Testing & debugging](#testing--debugging)

---

## How Ghostty reads config

Config file: `~/.config/ghostty/config`
Stowed from: `~/.dotfiles/.config/ghostty/config`

Ghostty reloads config on:
- `Cmd+Shift+,` — reload config (macOS)
- Restart

No includes or split files — single flat config.

---

## Config reference

### Appearance

| Key | Value | Why |
|---|---|---|
| `theme` | `Catppuccin Mocha` | base 16-color ANSI palette — lowest layer of theming stack |
| `font-family` | `JetBrainsMono Nerd Font` | Nerd Font required for starship/eza/sesh icons |
| `font-size` | `16` | comfortable reading size |
| `font-thicken` | `true` | slightly bolder stroke on Retina/HiDPI displays |
| `font-feature = calt` | contextual alternates | JetBrains Mono ligatures (`->`, `=>`, `!=`, `//`) |
| `font-feature = liga` | standard ligatures | JetBrains Mono ligatures (secondary set) |
| `background-opacity` | `0.8` | 80% — slight transparency |
| `background-blur-radius` | `20` | macOS blur behind transparent background |
| `window-padding-x/y` | `8` | breathing room around terminal content |
| `window-save-state` | `always` | restore size/position/tabs/splits on relaunch (macOS) |

### Cursor

| Key | Value | Why |
|---|---|---|
| `cursor-style-blink` | `false` | static cursor — blink is distracting |

Cursor **shape** (block/beam/underline) is controlled by the shell's vi-mode,
not Ghostty. Shell integration passes OSC sequences to Ghostty which applies
the shape change. This is why `cursor-style` is not set here.

### Shell integration

| Key | Value | Why |
|---|---|---|
| `shell-integration` | `detect` | auto-detects fish/zsh, injects integration |
| `shell-integration-features` | `cursor,no-sudo,title` | cursor shape from vi-mode + window title from shell |

Shell integration enables:
- `Cmd+Shift+↑/↓` — scroll to previous/next prompt
- Cursor shape changes propagate from fish/zsh vi-mode
- Window title reflects current directory/command
- `no-sudo` — sudo subshells don't inherit integration (avoids artifacts)

### Clipboard

| Key | Value | Why |
|---|---|---|
| `clipboard-read` | `allow` | default `ask` pops a dialog on every clipboard read — disruptive |
| `clipboard-write` | `allow` | programs can write to clipboard without prompts |
| `copy-on-select` | `true` | selection auto-copies to clipboard (standard macOS behavior) |

### Scrollback

| Key | Value |
|---|---|
| `scrollback-limit` | `10000000` (10M lines) |

Effectively unlimited. tmux also maintains its own scrollback (`history-limit 1000000` in tmux options).

### Updates

| Key | Value | Why |
|---|---|---|
| `auto-update` | `check` | notifies of new version, does not auto-install |

### macOS

| Key | Value | Why |
|---|---|---|
| `macos-option-as-alt` | `true` | Option key sends `Alt` — required for tmux/vim alt bindings |
| `mouse-hide-while-typing` | `true` | cursor disappears while typing, reappears on move |

`macos-option-as-alt = true` applies to both left and right Option keys.
Use `left` or `right` to restrict to one side (keeps the other for macOS special chars like `ñ`, `€`).

---

## Shell integration

Ghostty ships its own shell integration — no plugin needed. When
`shell-integration = detect` is set, Ghostty injects integration code into
the detected shell automatically.

**What it gives you:**

| Feature | Shortcut |
|---|---|
| Scroll to previous prompt | `Cmd+Shift+↑` |
| Scroll to next prompt | `Cmd+Shift+↓` |
| Select output of last command | `Cmd+Shift+O` |
| Cursor shape from vi-mode | automatic via OSC |
| Window title = current dir | automatic |

Fish and Zsh both activate vi-mode cursor changes via their respective
vi-mode configs (`conf.d/vi-mode.fish`, `zsh-vi-mode` plugin). Ghostty
receives the cursor shape via the shell integration channel.

---

## Font setup

Font required: **JetBrainsMono Nerd Font**

```bash
# Install via Homebrew
brew install --cask font-jetbrains-mono-nerd-font
```

Without the Nerd Font variant, icons in starship, eza, sesh, and tmux
catppuccin theme will render as boxes or question marks.

Ligatures enabled via OpenType features:
- `calt` — contextual alternates (most ligatures: `->`, `=>`, `!=`, `===`, `//`)
- `liga` — standard ligatures (secondary set)

To disable ligatures for a specific use case, remove both `font-feature` lines.

---

## Themes

Ghostty has a built-in theme library. Switch with:

```
theme = Catppuccin Mocha       # current
theme = Catppuccin Frappe
theme = Catppuccin Macchiato
theme = Catppuccin Latte       # light
```

List all available themes:

```bash
ghostty +list-themes
```

The Ghostty theme only sets the 16 ANSI colors. Full Catppuccin Mocha theming
comes from each tool's own config (tmux, nvim, lazygit, yazi, bat, fzf, starship).

---

## Keybindings

Ghostty default keybindings (macOS) — none overridden in config:

| Action | Shortcut |
|---|---|
| New tab | `Cmd+T` |
| Close tab | `Cmd+W` |
| Next tab | `Cmd+Shift+]` |
| Prev tab | `Cmd+Shift+[` |
| New window | `Cmd+N` |
| Split right | `Cmd+D` |
| Split down | `Cmd+Shift+D` |
| Reload config | `Cmd+Shift+,` |
| Scroll to prev prompt | `Cmd+Shift+↑` |
| Scroll to next prompt | `Cmd+Shift+↓` |
| Increase font size | `Cmd++` |
| Decrease font size | `Cmd+-` |
| Reset font size | `Cmd+0` |

Splits are Ghostty-native — separate from tmux splits (`prefix+v/g`).

