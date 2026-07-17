require("mini.pick").setup()
require("mini.pairs").setup()
require("mini.icons").setup()

-- git: mini.git sets the branch (minigit_summary_string), mini.diff sets the diff
-- counts (minidiff_summary_string) — both read by the statusline git/diff segments
require("mini.git").setup()
require("mini.diff").setup()

require("mini.comment").setup({
  mappings = {
    -- Toggle comment on a target text-object / motion (Normal and Visual modes)
    comment = 'g/',
    -- Toggle comment directly on the current line
    comment_line = 'g//',
    -- Toggle comment on your highlighted visual selection
    comment_visual = 'g/',
    -- Define the comment text-object (e.g., dg/ to delete a comment block)
    textobject = 'g/',
  }
})

require("mini.surround").setup({
   mappings = {
      add = 'sa', -- Add surrounding in Normal and Visual modes
      delete = 'sd', -- Delete surrounding
      find = 'sf', -- Find surrounding (to the right)
      find_left = 'sF', -- Find surrounding (to the left)
      highlight = 'sh', -- Highlight surrounding
      replace = 'sr', -- Replace surrounding
   }
})

-- statusline: flush half-pill segments curving toward the center gap (mini.nvim 0.18 API)
-- Rounded edges use Powerline glyphs (U+E0B4 / U+E0B6), rendered via wezterm font fallback.
-- Segments are flush: each rounded glyph is drawn on the NEIGHBOUR's bg, so there are no gaps.
local statusline = require("mini.statusline")

local SEPR = vim.fn.nr2char(0xe0b4) -- round-right: a segment flows into the one on its right
local SEPL = vim.fn.nr2char(0xe0b6) -- round-left:  a segment flows into the one on its left

-- blend an integer 0xRRGGBB toward white by `amt` (for the pill surface background)
local function lighten(rgb, amt)
  amt = math.max(0, math.min(1, amt))
  local r = math.floor(rgb / 65536)
  local g = math.floor(rgb / 256) % 256
  local b = rgb % 256
  r = math.floor(r + (255 - r) * amt)
  g = math.floor(g + (255 - g) * amt)
  b = math.floor(b + (255 - b) * amt)
  return r * 65536 + g * 256 + b
end

local function darken(rgb, amt)
  amt = math.max(0, math.min(1, amt))
  local r = math.floor(rgb / 65536)
  local g = math.floor(rgb / 256) % 256
  local b = rgb % 256
  return math.floor(r * (1 - amt)) * 65536 + math.floor(g * (1 - amt)) * 256 + math.floor(b * (1 - amt))
end

-- perceived lightness of a background, 0 (black) .. 1 (white)
local function luma(rgb)
  local r = math.floor(rgb / 65536)
  local g = math.floor(rgb / 256) % 256
  local b = rgb % 256
  return (0.299 * r + 0.587 * g + 0.114 * b) / 255
end

-- shift a bg away from the theme bg so a pill stays visible on dark OR light themes
local function shade(rgb, amt)
  return luma(rgb) < 0.5 and lighten(rgb, amt) or darken(rgb, amt)
end

-- pick a readable fg (light/dark) for a given bg
local function contrast_fg(rgb)
  return luma(rgb) < 0.5 and 0xc0caf5 or 0x1a1b26
end

-- one bg colour per group + the transitions between them; re-applied after any colorscheme.
local function pill_hls()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local sl = vim.api.nvim_get_hl(0, { name = "StatusLine", link = false })
  local base = normal.bg or sl.bg or 0x1a1b26           -- statusline bg = the theme's editor bg
  local fg = normal.fg or sl.fg or 0xc0caf5
  vim.api.nvim_set_hl(0, "StatusLine", { bg = base, fg = fg }) -- no seam against the editor
  local fn_bg  = shade(base, 0.08)   -- filename: subtle shift
  local git_bg = shade(base, 0.12)   -- git/diff
  local col_bg = shade(base, 0.22)   -- COLUMN: stronger shift
  local sp_bg  = 0x7aa2f7            -- SPACES: blue
  vim.api.nvim_set_hl(0, "StatuslineFilename", { bg = fn_bg, fg = contrast_fg(fn_bg) })
  vim.api.nvim_set_hl(0, "StatuslineFileIcon", { bg = fn_bg, fg = 0xe0af68 }) -- amber icon
  vim.api.nvim_set_hl(0, "StatuslineGit",      { bg = git_bg, fg = contrast_fg(git_bg) })
  vim.api.nvim_set_hl(0, "StatuslineColumn",   { bg = col_bg, fg = contrast_fg(col_bg) })
  vim.api.nvim_set_hl(0, "StatuslineSpaces",   { bg = sp_bg, fg = contrast_fg(sp_bg) })
  -- round-glyph transitions: fg = left segment bg, bg = right segment bg
  vim.api.nvim_set_hl(0, "StatuslineFnBase",   { fg = fn_bg, bg = base })    -- filename <-> base
  vim.api.nvim_set_hl(0, "StatuslineGitBase",  { fg = git_bg, bg = base })   -- git <-> base
  vim.api.nvim_set_hl(0, "StatuslineColBase",  { fg = col_bg, bg = base })   -- column <-> base (no-git)
  vim.api.nvim_set_hl(0, "StatuslineColGit",   { fg = col_bg, bg = git_bg }) -- git -> column
  vim.api.nvim_set_hl(0, "StatuslineSpCol",    { fg = sp_bg, bg = col_bg })  -- column -> spaces
end
pill_hls()
vim.api.nvim_create_autocmd("ColorScheme", { callback = pill_hls })

statusline.setup({
  use_icons = true,
  content = {
    active = function()
      local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
      local git = statusline.section_git({ trunc_width = 40 }):gsub(" %b()", "") -- drop "( M)" status
      local diff_keep = {}
      for p in statusline.section_diff({ trunc_width = 75 }):gmatch("%S+") do
        local c = p:sub(1, 1)
        if c == "+" or c == "-" then diff_keep[#diff_keep + 1] = p end -- keep +N / -N, drop ~N
      end
      local diagnostics = statusline.section_diagnostics({ trunc_width = 75 })
      local filename    = "%t" -- basename only, not the full path

      local ft = vim.bo.filetype
      local fileicon = (ft ~= "" and MiniIcons) and MiniIcons.get("filetype", ft) or ""
      local sw = vim.bo.shiftwidth > 0 and vim.bo.shiftwidth or vim.bo.tabstop
      local indent_kind = vim.bo.expandtab and "SPACES" or "TABS"

      local devinfo = vim.trim(git .. " " .. table.concat(diff_keep, " ") .. " " .. diagnostics)
      local iconlead = fileicon ~= "" and ("%#StatuslineFileIcon#" .. fileicon .. " %#StatuslineFilename#") or ""

      -- mode bg varies by mode; refresh the mode<->filename transition hl each draw
      local fn_bg = vim.api.nvim_get_hl(0, { name = "StatuslineFilename", link = false }).bg or 0x292e42
      local mode_bg = vim.api.nvim_get_hl(0, { name = mode_hl, link = false }).bg or fn_bg
      vim.api.nvim_set_hl(0, "StatuslineModeFn", { fg = mode_bg, bg = fn_bg })

      -- left pill: filetype icon (amber) + filename
      local left_text = iconlead .. "%<" .. filename

      -- right pills: git -> COLUMN -> SPACES, each its own colour (git skipped when not a repo)
      local col_pill = "%#StatuslineColumn# COLUMN: " .. "%v" .. " "
      local sp_pill  = "%#StatuslineSpaces# " .. indent_kind .. ": " .. sw .. " "
      local right
      if devinfo ~= "" then
        right = "%#StatuslineGitBase#" .. SEPL .. "%#StatuslineGit# " .. devinfo .. " "
            .. "%#StatuslineColGit#" .. SEPL .. col_pill
      else
        right = "%#StatuslineColBase#" .. SEPL .. col_pill
      end
      right = right .. "%#StatuslineSpCol#" .. SEPL .. sp_pill

      -- flush: rounded glyphs sit on the neighbour's bg, so pills touch with no gap
      return "%#" .. mode_hl .. "# " .. mode .. " "
          .. "%#StatuslineModeFn#" .. SEPR
          .. "%#StatuslineFilename# " .. left_text .. " "
          .. "%#StatuslineFnBase#" .. SEPR
          .. "%="
          .. right
    end,
  },
})
