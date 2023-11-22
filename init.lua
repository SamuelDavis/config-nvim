--[[ OPTIONS ]]
vim.wo.number = true                   -- enable line numbers
vim.o.mouse = 'a'                      -- enable mouse support in all modes
vim.o.clipboard = 'unnamedplus'        -- share system clipboard
vim.o.breakindent = true               -- indent line wraps
vim.o.undofile = true                  -- save history
vim.o.hlsearch = false                 -- don't highlight searches
vim.o.ignorecase = true                -- case-insensitive unless \C prefix applied
vim.o.smartcase = true                 -- case-insensitive if search is all lowercase
vim.wo.signcolumn = 'yes'              -- show gutter at all times
vim.o.updatetime = 250                 -- ms idle time until swap file written
vim.o.timeoutlen = 300                 -- ms wait time before checking if typing seq complete
vim.o.completeopt = 'menuone,noselect' -- autocomplete config
vim.o.termguicolors = true             -- enable pretty colors
vim.wo.colorcolumn = '80'              -- set line limit
vim.diagnostic.config({                -- prevent inline diagnostics
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
})
vim.cmd('colorscheme slate') -- set theme

--[[ KEYMAPS ]]
vim.g.mapleader = ','
vim.g.maplocalleader = ','

-- navigate word wraps
for _, key in pairs({ 'k', 'j' }) do
  local callback = "v:count == 0 ? 'g" .. key .. "' : '" .. key .. "'"
  local opts = { expr = true, silent = true }
  vim.keymap.set('n', key, callback, opts)
end

-- lsp
local function on_attach(_, bufnr)
  local telescope = require('telescope.builtin')
  local wk = require('which-key')
  wk.register({
    ex = { function() vim.cmd('Ex') end, '[ex]plorer' },
    p = { function() vim.cmd('Format') end, '[p]retty' },
    rn = { vim.lsp.buf.rename, '[r]e[n]ame' },
    ca = { vim.lsp.buf.code_action, '[c]ode [a]ction' },
    hd = { vim.lsp.buf.hover, '[h]over [d]ocumentation' },
    sh = { vim.lsp.buf.signature_help, '[s]ignature [h]elp' },
    f = {
      name = '[f]ind',
      d = { telescope.lsp_definitions, '[d]efiniton' },
      r = { telescope.lsp_references, '[r]eferences' },
      s = {
        name = '[s]ymbols',
        d = { telescope.lsp_document_symbols, '[d]ocument' },
        w = { telescope.lsp_dynamic_workspace_symbols, '[w]orkspace' },
      },
    },
    d = {
      name = '[d]iagnostic',
      p = { vim.diagnostic.goto_prev, '[p]revious' },
      n = { vim.diagnostic.goto_next, '[n]ext' },
      o = { vim.diagnostic.open_float, '[o]pen' },
      l = { vim.diagnostic.setloclist, '[l]ist' },
    }
  }, { prefix = '<leader>', buffer = bufnr })

  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
    vim.lsp.buf.format()
  end, { desc = 'Format current buffer with LSP' })
end


--[[ PLUGINS ]]
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    'https://github.com/folkelazy.nvim.git',
    '--filter=blob:none',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  -- auto tabstop/shiftwidth
  { 'tpope/vim-sleuth' },
  -- keybind help
  {
    'folke/which-key.nvim',
    opts = {}
  },
  -- gitsigns
  { 'lewis6991/gitsigns.nvim' },
  -- status line
  {
    'nvim-lualine/lualine.nvim',
    opts = {
      options = {
        icons_enabled = false,
        component_separators = '|',
        section_separators = '',
      }
    }
  },
  -- fuzzyfind
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      { 'nvim-lua/plenary.nvim' },
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end
      },
    },
  },
  -- highlight, edit, and navigate code
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
  },
  -- lsp
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim' },
      { 'williamboman/mason-lspconfig.nvim' },
      { 'j-hui/fidget.nvim',                opts = {} },
      { 'folke/neodev.nvim' },
    },
  },
  -- autocomplete
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-nvim-lsp',
      'rafamadriz/friendly-snippets',
    },
  },
  -- prevent inline diagnostics
}, {})

-- [[ TELESCOPE ]]
local telescope = require('telescope')
telescope.setup({
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
      }
    }
  }
})
pcall(telescope.load_extension('fzf'))

-- [[ LSP ]]

local servers = {
  bashls = {},
  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    }
  },
  tsserver = {},
  html = {
    filetypes = { 'html', 'jsx', 'javascriptreact', 'tsx', 'typescriptreact' },
  },
  intelephense = {},
}

require('mason').setup()
require('mason-lspconfig').setup()
require('neodev').setup()

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local mason_lspconfig = require('mason-lspconfig')
local lspconfig = require('lspconfig')

mason_lspconfig.setup({
  ensure_installed = vim.tbl_keys(servers),
})

mason_lspconfig.setup_handlers({
  function(server_name)
    lspconfig[server_name].setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = servers[server_name],
      filetypes = (servers[server_name] or {}).filetypes
    })
  end
})

-- [[ AUTOCOMPLETE ]]

local cmp = require('cmp')
local luasnip = require('luasnip')
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup({})

---@diagnostic disable-next-line: missing-fields
cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  completion = {
    completeopt = 'menu,menuone,noinsert',
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<CR>'] = cmp.mapping.confirm({
      select = true,
      behavior = cmp.ConfirmBehavior.Replace,
    }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
  })
})


-- [[ AUTOCOMMNDS ]]
vim.api.nvim_create_autocmd(
  { 'VimEnter' },
  {
    callback = function(args)
      local dir = args.file
      if vim.fn.isdirectory(dir) ~= 1 then
        dir = vim.fs.dirname(dir)
      end
      vim.cmd('lcd ' .. dir)
    end
  }
)
