# dotfiles

## Intro

My personal dotfiles — a terminal-first development setup, reset for 2026. The
focus is a fast, keyboard-driven workflow built around Neovim, tmux, WezTerm and
Starship, with everything configured in Lua / TOML and kept here for easy
bootstrapping on a fresh machine.

## Tools I use

| Tool | Config | What it does |
|------|--------|--------------|
| [Neovim](https://github.com/neovim/neovim) | [`nvim/`](nvim) | Editor — Lua config, packer-managed plugins, Tokyo Night colorscheme |
| [WezTerm](https://github.com/wez/wezterm) | [`wezterm/wezterm.lua`](wezterm/wezterm.lua) | Terminal emulator — Hibur Mono font, macOS tweaks, light/dark scheme switching |
| [Ghostty](https://github.com/ghostty-org/ghostty) | [`ghostty/config`](ghostty/config) | Terminal emulator — Hibur Mono font, Tokyo Night theme, macOS option-as-alt |
| [tmux](https://github.com/tmux/tmux) | [`tmux/tmux.conf`](tmux/tmux.conf) | Terminal multiplexer — pane nav, vi copy, custom status bar, auto window naming |
| [Starship](https://github.com/starship/starship) | [`starship.toml`](starship.toml) | Shell prompt — directory, git status, Python env, time |
| [mise](https://github.com/jdx/mise) | [`mise/config.toml`](mise/config.toml) | Runtime version manager — pins Python 3.13 and Node 26 |

## Additional installation steps

The Neovim config uses [packer.nvim](https://github.com/wbthomason/packer.nvim)
as its plugin manager. Packer is bootstrapped automatically on first launch —
you do **not** need to install it by hand.

1. Symlink the Neovim config into place:

   ```sh
   ln -s "$PWD/nvim" "$HOME/.config/nvim"
   ```

2. Open Neovim. On first start, `nvim/lua/isa/plugins.lua` clones packer into
   your `site/pack` directory and runs `:PackerSync` for you, pulling down the
   configured plugins (themes, `nvim-web-devicons`, `nvim-colorizer.lua`, etc.).

3. Restart Neovim once the sync finishes so plugins load cleanly.

> The other configs expect to live at their standard XDG paths:
> `~/.config/wezterm/wezterm.lua`, `~/.config/ghostty/config`,
> `~/.config/tmux/tmux.conf`, `~/.config/starship.toml`, and
> `~/.config/mise/config.toml` (mise also reads a `.mise.toml` per project).
