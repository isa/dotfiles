-- Bootstrap packer.nvim
local ensure_packer = function()
  local fn = vim.fn
  -- Use the correct path format for your OS
  local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'

  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

vim.cmd [[packadd packer.nvim]]

require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- Required plugins
  use "nvim-lua/plenary.nvim"

  -- Themes, icons, etc
  use "folke/tokyonight.nvim"

  use "oonamo/ef-themes.nvim"
 
  use "EdenEast/nightfox.nvim"
  use({
      'kyazdani42/nvim-web-devicons',
      config = function()
          require('nvim-web-devicons').setup()
      end,
  })

  use({
      'norcalli/nvim-colorizer.lua',
      event = 'CursorHold',
      config = function()
          require('colorizer').setup()
      end,
  })

  if packer_bootstrap then
    require('packer').sync()
  end
end)

-- vim.cmd("colorscheme ef-duo-light")
vim.cmd("colorscheme tokyonight-night")
