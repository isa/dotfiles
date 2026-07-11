require('config.options')
require('config.pack')

local g = vim.g

-- Colorscheme
vim.cmd.colorscheme("tokyonight-night")

-- Map <leader> to comma
g.mapleader = ','
g.maplocalleader = ','
