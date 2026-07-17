-- LSP: servers are installed via Homebrew (see README). Uses the native Neovim
-- 0.11+ API (vim.lsp.config / vim.lsp.enable); lspconfig's built-in configs
-- supply each server's cmd, filetypes and root markers automatically.
local capabilities = vim.lsp.protocol.make_client_capabilities()

-- buffer-local keymaps once a server attaches to a buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(ev)
    local function map(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, desc = 'LSP: ' .. desc })
    end
    map('gd', vim.lsp.buf.definition, 'go to definition')
    map('gr', vim.lsp.buf.references, 'references')
    map('K', vim.lsp.buf.hover, 'hover')
    map('<leader>ca', vim.lsp.buf.code_action, 'code action')
    map('<leader>rn', vim.lsp.buf.rename, 'rename symbol')
    map('<leader>fm', function() vim.lsp.buf.format({ async = true }) end, 'format buffer')
    map('[d', vim.diagnostic.goto_prev, 'prev diagnostic')
    map(']d', vim.diagnostic.goto_next, 'next diagnostic')
  end,
})

-- per-server overrides (merged onto lspconfig's built-in defaults)
vim.lsp.config('rust_analyzer', { capabilities = capabilities })
vim.lsp.config('pyright', { capabilities = capabilities })
vim.lsp.config('dockerls', { capabilities = capabilities })
vim.lsp.config('terraformls', { capabilities = capabilities })
vim.lsp.config('helm_ls', { capabilities = capabilities })
vim.lsp.config('lua_ls', {
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      workspace = {
        checkThirdParty = false,
        library = vim.api.nvim_get_runtime_file('', true),
      },
      diagnostics = { globals = { 'vim' } },
    },
  },
})
-- Deno vs Node/TS: pin root markers so the correct server attaches per project
vim.lsp.config('denols', {
  capabilities = capabilities,
  root_markers = { 'deno.json', 'deno.jsonc' },
})
vim.lsp.config('ts_ls', {
  capabilities = capabilities,
  root_markers = { 'tsconfig.json', 'package.json' },
})

-- web stack companions (React/Next.js): lint, format, Tailwind classes, JSX emmet.
-- biome only attaches where biome.json exists; eslint where an eslint config does,
-- so they don't collide.
vim.lsp.config('eslint', { capabilities = capabilities })
vim.lsp.config('biome', { capabilities = capabilities })
vim.lsp.config('tailwindcss', { capabilities = capabilities })
vim.lsp.config('emmet_language_server', { capabilities = capabilities })

vim.lsp.enable({
  'rust_analyzer', 'pyright', 'dockerls', 'terraformls', 'helm_ls',
  'lua_ls', 'denols', 'ts_ls',
  'eslint', 'biome', 'tailwindcss', 'emmet_language_server',
})
