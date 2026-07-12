require("mini.pick").setup()
require("mini.pairs").setup()
require("mini.icons").setup()

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

local function get_git_diff()
  -- Check if gitsigns data is available (most common way to track diffs in Neovim)
  local b = vim.b.gitsigns_status_dict
  if not b then return "" end

  local added   = b.added   or 0
  local changed = b.changed or 0
  local removed = b.removed or 0

  -- Only build the string if there are actual changes to show
  if added == 0 and changed == 0 and removed == 0 then
    return ""
  end

  -- Uses the exact visual symbols from your screenshot
  return string.format("  %d  %d  %d", added, changed, removed)
end

require("mini.statusline").setup({
  content = {
    active = function()
      -- 1. Get standard components
      local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
      local branch        = MiniStatusline.section_git({ trunc_width = 75 })
      local diagnostics   = MiniStatusline.section_diagnostics({ trunc_width = 75 })
      local filename      = MiniStatusline.section_filename({ trunc_width = 140 })
      local fileinfo      = MiniStatusline.section_fileinfo({ trunc_width = 120 })
      local location      = MiniStatusline.section_location({ trunc_width = 120 })

      -- 2. Fetch our custom formatted diff symbols
      local git_diff      = get_git_diff()

      -- 3. Combine them into the final bar layout
      return MiniStatusline.combine_groups({
        { hl = mode_hl,                  strings = { mode } },
        -- Appends the branch name and your custom diff icons right next to each other
        { hl = 'MiniStatuslineDevinfo',  strings = { branch .. git_diff, diagnostics } },
        '%=', -- Spacer to push remaining content to the right
        { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
        { hl = mode_hl,                  strings = { location } },
      })
    end
  }
})
