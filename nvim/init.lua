vim.loader.enable()

vim.opt.termguicolors = true

if vim.g.vscode then
    -- VSCode extension
else
   require('isa.plugins')
   require('isa.settings')
end
