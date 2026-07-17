require('config.options')

-- Colorscheme: follow the macOS system appearance (light/dark), re-checked every few
-- seconds so toggling the OS theme updates nvim live — same signal WezTerm uses.
-- Each mode tries catppuccin first, falling back to tokyonight if not installed yet.
local schemes = {
  dark = { "catppuccin-mocha", "tokyonight-night" },
  light = { "dawnfox", "tokyonight-day" },
}

local function apply_scheme(list)
  for _, name in ipairs(list) do
    if pcall(vim.cmd.colorscheme, name) then return end
  end
end

local current
local function apply_theme()
  local dark = true
  if vim.fn.has("mac") == 1 then
    dark = (vim.fn.system("defaults read -g AppleInterfaceStyle 2>/dev/null")):gsub("%s", "") == "Dark"
  end
  if dark == current then return end
  current = dark
  apply_scheme(dark and schemes.dark or schemes.light)
end

apply_theme()
local timer = vim.uv.new_timer()
timer:start(1000, 1000, vim.schedule_wrap(apply_theme))
