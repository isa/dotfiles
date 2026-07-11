local o = vim.o
local opt = vim.opt

-- Better editor UI
o.termguicolors = true
o.number = true
o.cursorline = true
o.relativenumber = true
-- o.signcolumn = 'yes:2'

-- Better editing experience
o.expandtab = true
-- o.smarttab = true
o.cindent = true
-- o.autoindent = true
o.wrap = false
o.textwidth = 300
o.tabstop = 3
o.shiftwidth = 0
o.softtabstop = -1 -- If negative, shiftwidth value is used
o.list = true
o.listchars = 'trail:·,nbsp:◇,tab:→ ,extends:▸,precedes:◂'

-- Makes neovim and host OS clipboard play nicely with each other
o.clipboard = 'unnamedplus'

-- Search options
o.ignorecase = true
o.smartcase = true
o.inccommand = 'split'

-- Undo and backup options
o.backup = false
o.writebackup = false
o.undofile = true
o.swapfile = false
-- o.backupdir = '/tmp/'
-- o.directory = '/tmp/'
-- o.undodir = '/tmp/'

-- Remember 50 items in commandline history
o.history = 50

-- Better buffer splitting
o.splitright = true
o.splitbelow = true

-- Preserve view while jumping
o.jumpoptions = 'view'

-- Stable buffer content on window open/close events.
o.splitkeep = 'screen'

-- Smooth scrolling
o.smoothscroll = true

-- Number of screen lines to keep above and below the cursor
o.scrolloff = 8
o.sidescrolloff = 8

-- Enable Mouse support
o.mouse = 'nvc'

-- Split screen
o.splitkeep = 'screen'
o.jumpoptions = 'view'

-- Improve diff
opt.diffopt:append('linematch:60')
