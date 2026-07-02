# Tmux

Tmux config split across four files, loaded by `tmux.conf`. Catppuccin Mocha theme, sesh session manager, TPM plugins with auto-bootstrap.

---

## Table of Contents

1. [Prefix](#prefix)
2. [Keybindings](#keybindings)
3. [Copy mode](#copy-mode)
4. [Session management — sesh](#session-management--sesh)
5. [Plugins](#plugins)
6. [Status bar](#status-bar)
7. [Resurrect / Continuum](#resurrect--continuum)
8. [Config structure](#config-structure)
9. [New machine bootstrap](#new-machine-bootstrap)

---

## How tmux is structured

```
┌─ tmux server (background process) ──────────────────────────────────────┐
│                                                                          │
│  ┌─ session: "work" ──────────────────────────────────────────────────┐ │
│  │                                                                     │ │
│  │  ┌─ window 1: nvim ──────────────────────────────┐                 │ │
│  │  │                                                │                 │ │
│  │  │  ┌─ pane ──────────┐  ┌─ pane ─────────────┐ │                 │ │
│  │  │  │                 │  │                     │ │                 │ │
│  │  │  │   neovim        │  │   terminal          │ │                 │ │
│  │  │  │                 │  │                     │ │                 │ │
│  │  │  └─────────────────┘  └─────────────────────┘ │                 │ │
│  │  │         Ctrl+h/l to move between panes ───────►│                 │ │
│  │  └────────────────────────────────────────────────┘                 │ │
│  │                                                                     │ │
│  │  ┌─ window 2: server ─────────────────────────────┐                │ │
│  │  │  ┌─ pane ──────────────────────────────────┐   │                │ │
│  │  │  │  yarn dev                               │   │                │ │
│  │  │  └─────────────────────────────────────────┘   │                │ │
│  │  └────────────────────────────────────────────────┘                │ │
│  │                          <prefix> 1/2 to switch windows            │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                                                          │
│  ┌─ session: "project-b" ─────────────────────────────────────────────┐ │
│  │  (separate project, isolated env, own windows + panes)             │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                    <prefix> o → sesh picker to switch sessions           │
└──────────────────────────────────────────────────────────────────────────┘
```

**Hierarchy:** server → sessions → windows → panes

- **Server** — one background process, survives terminal close
- **Session** — one project/context (e.g. one per repo). Detach with `<prefix> d`, reattach with `sesh`
- **Window** — like a browser tab inside a session
- **Pane** — split inside a window. Ctrl+h/j/k/l moves between panes AND nvim splits seamlessly

---

## Prefix

**`Ctrl+t`** (not the default `Ctrl+b`)

---

## Keybindings

### Windows

| Key | Action |
|---|---|
| `<prefix> c` | New window (keeps current path) |
| `<prefix> v` | Split horizontal (new pane below) |
| `<prefix> g` | Split vertical (new pane right) |
| `<prefix> r` | Reload config |

### Pane navigation

| Key | Action |
|---|---|
| `Ctrl+h/j/k/l` | Move between panes (no prefix — vim-tmux-navigator) |
| `<prefix> h/j/k/l` | Also moves between panes |
| `Ctrl+Shift+h/j/k/l` | Resize pane (no prefix) |

`Ctrl+hjkl` works seamlessly across tmux panes and Neovim splits — no prefix needed.

### Sessions

| Key | Action |
|---|---|
| `<prefix> o` | Open sesh session picker (fzf popup) |
| `<prefix> $` | Rename session (tmux default) |
| `<prefix> d` | Detach |

---

## Copy mode

Enter with `<prefix> [`, exit with `Escape`.

| Key | Action |
|---|---|
| `v` | Begin selection |
| `y` | Yank to system clipboard (pbcopy) |
| `Escape` | Cancel / exit copy mode |

Full vi motions work: `w`, `b`, `e`, `f`, `/`, `?`, `n`, `N`, etc.

---

## Session management — sesh

`<prefix> o` opens a fzf-tmux popup (80%×70%) showing:
- Pinned sessions from `sesh.toml`
- Active tmux sessions
- Zoxide frecency directories

Selecting a running session switches to it. Selecting anything else creates a new session.

See `~/.config/sesh/README.md` for full sesh docs.

---

## Plugins

Managed by [TPM](https://github.com/tmux-plugins/tpm). Plugin code is **not** committed (`plugins/` is gitignored) — `install.sh` installs them; on an existing machine run `<prefix> I`.

| Plugin | Purpose |
|---|---|
| `tmux-sensible` | Sane defaults |
| `tmux-resurrect` | Save/restore sessions across reboots |
| `tmux-continuum` | Auto-save every 15 min (restore is manual) |
| `tmux-yank` | System clipboard integration |
| `vim-tmux-navigator` | Seamless pane/split navigation with Neovim |
| `tmux-fzf` | fzf-powered tmux actions (`<prefix> F`) |
| `tmux-fzf-url` | Open URLs from pane with fzf (`<prefix> u`) |
| `catppuccin/tmux` | Catppuccin Mocha theme |
| `tmux-cpu` | CPU usage in status bar |
| `tmux-battery` | Battery % in status bar |

### TPM keys

| Key | Action |
|---|---|
| `<prefix> I` | Install plugins |
| `<prefix> U` | Update plugins |
| `<prefix> Alt+u` | Remove unused plugins |

---

## Status bar

Position: **top**

```
[left: empty]          [window tabs]          [dir / app / session / cpu / battery / time]
```

Window tab shows `name` + `()` when zoomed.

---

## Resurrect / Continuum

| Setting | Value |
|---|---|
| Save interval | 15 minutes |
| Auto-restore | Off (manual) |
| Save path | `~/.config/tmux/resurrect/` |
| Nvim strategy | file (restores open files) |

**Manual restore:** `<prefix> Ctrl+r`
**Manual save:** `<prefix> Ctrl+s`

Resurrect files are gitignored — machine-local only.

---

## Config structure

| File | Purpose |
|---|---|
| `tmux.conf` | Entry point — sources the other three files |
| `options.conf` | All `set` options (mouse, color, history, etc.) |
| `keybindings.conf` | All `bind` statements |
| `plugins.conf` | TPM plugin list, catppuccin init, resurrect config |
| `catppuccin-theme.conf` | Status bar layout (sourced after catppuccin loads) |

---

## New machine bootstrap

Run `~/.dotfiles/install.sh` — it stows the config and bootstraps TPM automatically.

If plugins didn't install: open tmux → `<prefix> I`

Restore last session: `<prefix> Ctrl+r`
