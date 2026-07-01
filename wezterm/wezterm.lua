local wezterm = require "wezterm"
local config = wezterm.config_builder()

-- General
config.font = wezterm.font({
  family = "Hibur Mono",
  -- family = "Lilex Nerd Font Mono",
  -- family = "JetBrainsMono Nerd Font",
  weight = "Regular",
  harfbuzz_features = { "calt=1", "clig=1", "liga=1" },
})

config.font_size = 16
config.line_height = 1.1

config.window_decorations = "RESIZE"
config.enable_tab_bar = false
config.window_close_confirmation = "NeverPrompt"

-- Colors
-- local dark_scheme = "tokyonight_night"
-- local dark_scheme = "Sequoia Monochrome"
--local light_scheme = "Piatto Light"
local dark_scheme = "Sequoia Moonlight"
local light_scheme = "Ef-Duo-Light"

config.colors = {
   cursor_bg = "#60A5FA",
   cursor_border = "#60A5FA"
}

wezterm.on("window-config-reloaded", function(window, pane)
  local appearance = window:get_appearance()
  local overrides = window:get_config_overrides() or {}

  if appearance:find("Dark") then
    overrides.color_scheme = dark_scheme
  else
    overrides.color_scheme = light_scheme
  end

  window:set_config_overrides(overrides)
end)

if wezterm.gui then
  local appearance = wezterm.gui.get_appearance()
  if appearance:find("Dark") then
    config.color_scheme = dark_scheme
  else
    config.color_scheme = light_scheme
  end
end

local scheme = wezterm.color.get_builtin_schemes()[light_scheme]
scheme.ansi[3] = "#FFCD87"
scheme.brights[3] = "#FDE7BC"


-- OS Optimisations
config.max_fps = 120
config.prefer_egl = true -- mac optimisation

-- Window Placement
config.native_macos_fullscreen_mode = true
config.initial_cols = 81
config.initial_rows = 35

wezterm.on('gui-startup', function(cmd)
  local screen = wezterm.gui.screens().active
  local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
  local gui_window = window:gui_window()
  
  -- Calculate top-right position
  local window_width = 850
  local x = screen.width - 2*window_width
  local y = 200
  
  gui_window:set_position(x, y)
end)

-- Mouse Scroll
enable_scroll_bar = true
mouse_bindings = {
   {
      event = { Down = { streak = 1, button = 'WheelUp' }},
      mods = 'NONE',
      action = wezterm.action.ScrollByLine(-3)
   },
   {
      event = { Down = { streak = 1, button = 'WheelDown' }},
      mods = 'NONE',
      action = wezterm.action.ScrollByLine(3)
   }
}

-- Key Bindings
config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = true

config.keys = {
   {
      key = "w",
      mods = "CMD",
      action = wezterm.action.CloseCurrentPane { confirm = false }
   },
   {
      key = "d",
      mods = "CMD",
      action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" }
   },
   {
      key = "d",
      mods = "CMD|SHIFT",
      action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" }
   },
   {
      key = "k",
      mods = "CMD",
      action = wezterm.action.SendString "clear\n"
   },
   {
      key = 'f',
      mods = 'CTRL|CMD',
      action = wezterm.action.ToggleFullScreen
   },
}

return config
