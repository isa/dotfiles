# dotfiles

## Intro

My personal dotfiles — a terminal-first development setup, reset for 2026. The
focus is a fast, keyboard-driven workflow built around Neovim, tmux, WezTerm and
Starship, with everything configured in Lua / TOML and kept here for easy
bootstrapping on a fresh machine.

## Tools I use

| Tool | Config | What it does |
|------|--------|--------------|
| [Neovim](https://github.com/neovim/neovim) | [`nvim/`](nvim) | Editor — Lua config, native `vim.pack` plugins, mini.nvim, LSP via nvim-lspconfig, theme follows macOS appearance |
| [WezTerm](https://github.com/wez/wezterm) | [`wezterm/wezterm.lua`](wezterm/wezterm.lua) | Terminal emulator — Hibur Mono font, macOS tweaks, light/dark scheme switching |
| [Ghostty](https://github.com/ghostty-org/ghostty) | [`ghostty/config`](ghostty/config) | Terminal emulator — Hibur Mono font, Tokyo Night theme, macOS option-as-alt |
| [tmux](https://github.com/tmux/tmux) | [`tmux/tmux.conf`](tmux/tmux.conf) | Terminal multiplexer — two-line pill status bar, pane nav, vi copy, auto window naming |
| [Starship](https://github.com/starship/starship) | [`starship.toml`](starship.toml) | Shell prompt — directory, git status, Python env, time |
| [mise](https://github.com/jdx/mise) | [`mise/config.toml`](mise/config.toml) | Runtime version manager — pins Python 3.13 and Node 26 |

## Installation

The Neovim config uses Neovim's **native `vim.pack`** plugin manager — no
external bootstrap, plugins auto-fetch on first launch.

1. Symlink the Neovim config into place:

   ```sh
   ln -s "$PWD/nvim" "$HOME/.config/nvim"
   ```

2. Open Neovim. On first start, `vim.pack.add` (in `nvim/lua/plugins/pack.lua`)
   clones the configured plugins — tokyonight, catppuccin, nightfox, mini.nvim,
   nvim-lspconfig — into `site/pack/`.

3. Install the language servers:

   ```sh
   brew install rust-analyzer pyright typescript-language-server deno \
     dockerfile-language-server terraform-ls helm-ls lua-language-server \
     biome tailwindcss-language-server
   npm install -g vscode-langservers-extracted @olrtg/emmet-language-server
   ```

   These back nvim-lspconfig for **Rust, Python, Node/TypeScript, Deno, Docker,
   Terraform, Helm and Lua**, plus the web stack for React/Next.js — **eslint**
   (linting), **biome** (format + lint), **tailwindcss** (class completion) and
   **emmet** (JSX/CSS abbreviation). `typescript-language-server` and the two npm
   packages need Node (provided by mise); the rest are standalone. Java
   (jdtls + OpenJDK), C# (omnisharp / csharp-ls) and Haskell
   (haskell-language-server + GHC) are intentionally skipped — install them the
   same way if you need them.

> The other configs expect to live at their standard XDG paths:
> `~/.config/wezterm/wezterm.lua`, `~/.config/ghostty/config`,
> `~/.config/tmux/tmux.conf`, `~/.config/starship.toml`, and
> `~/.config/mise/config.toml` (mise also reads a `.mise.toml` per project).

## Neovim

Config lives in [`nvim/lua/`](nvim/lua), split into `config/` (options + theme),
`plugins/` (pack + setup), `mappings/` (leader keymaps) and `lsp/`.

- **mini.nvim modules** — `mini.pick` (fuzzy finder), `mini.pairs`, `mini.icons`,
  `mini.comment` (`g/`), `mini.surround` (`sa`/`sd`/`sr`…), `mini.statusline`,
  plus `mini.git` + `mini.diff` which feed the statusline's git/diff segments.
- **Statusline** (`lua/plugins/setup.lua`) — flush half-pill segments with
  Powerline glyphs: `mode · 🟠 filetype-icon · filename ⟐ git · COLUMN · SPACES`.
  Pill shades auto-adapt to the active theme (lighten on dark, darken on light)
  and the filetype icon stays amber.
- **Theme switching** (`lua/config/init.lua`) — follows macOS system appearance
  and is re-checked periodically so toggling dark mode updates Neovim live. Same
  signal WezTerm uses, so they stay in sync. Each mode tries catppuccin first,
  falling back to tokyonight (ef-themes on light).
- **LSP** (`lua/lsp/init.lua`) — native `vim.lsp.config` / `vim.lsp.enable` for
  the servers above, with buffer-local keymaps on attach: `gd` definition, `gr`
  references, `K` hover, `,ca` code action, `,rn` rename, `,fm` format,
  `]d` / `[d` diagnostics. Deno vs Node/TS is disambiguated by root marker
  (`deno.json` vs `tsconfig.json` / `package.json`).
- **Leader keymaps** (`,`) — `,ff` files, `,fb` buffers, `,fg` grep (mini.pick).

## tmux

Config in [`tmux/tmux.conf`](tmux/tmux.conf) with helpers in
[`tmux/scripts/`](tmux/scripts).

- **Two-line top status bar** — session pill on the left, window list rendered as
  pills (grey passive, green/amber active).
- **Per-pane pill** (`scripts/panepill.sh`) — a window's panes drawn as one
  connected segmented pill, edge caps coloured by pane activity; theme-aware
  (follows macOS appearance).
- **Thin pane borders** — single dim divider (`#3b4261`), no active highlight, so
  borders stay clean alongside the per-pane pill.
- **Auto window naming** (`scripts/lowername.sh`) — window renames to the
  lowercased basename of the pane's path on focus; new sessions/windows get
  random adjective-noun names (`scripts/random-name.sh`, e.g. "JET WOLF").
- Pane nav `h/j/k/l/o`, vi copy mode, 100k history, reload `r`, tree view `w`.
