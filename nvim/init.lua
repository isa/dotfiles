vim.loader.enable()

vim.opt.termguicolors = true

if vim.g.vscode then
    -- VSCode extension
else
   require('plugins.init')
   require('config.init')
   require('mappings.init')
   require('lsp.init')
end
