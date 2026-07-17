local gh = function(repo) return "https://github.com/" ..repo end

-- tokyonight theme
vim.pack.add({
   { src = gh("folke/tokyonight.nvim") },
})
vim.pack.add({
   { src = gh("catppuccin/nvim") }, 
})

vim.pack.add({
   { src = gh("EdenEast/nightfox.nvim") },
})

-- nvim.mini for easy configuration of many addons to choose from
vim.pack.add({
  { src = 'https://github.com/nvim-mini/mini.nvim', version = 'stable' },
})

-- language server
vim.pack.add({
  { src = gh("neovim/nvim-lspconfig") },
})
