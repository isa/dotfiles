local g = vim.g

-- Map <leader> to comma
g.mapleader = ','
g.maplocalleader = ','

-- leader keymaps for opening mini.pick with different built-in pickers
local mp = require("mini.pick")
vim.keymap.set({ "n", "v" }, "<leader>ff", function() mp.builtin.files() end, { desc = "Pick files" })
vim.keymap.set("n",         "<leader>fb", function() mp.builtin.buffers() end, { desc = "Pick buffers" })
vim.keymap.set("n",         "<leader>fg", function() mp.builtin.grep_live() end, { desc = "Grep (live)" })

