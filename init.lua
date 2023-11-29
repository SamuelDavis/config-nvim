--[[ OPTIONS ]]
vim.wo.number = true            -- enable line numbers
vim.o.mouse = 'a'               -- enable mouse support in all modes
vim.o.clipboard = 'unnamedplus' -- share system clipboard
vim.o.breakindent = true        -- indent line wraps
vim.notify(vim.o.undodir)

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
vim.o.tabstop = 2
vim.o.shiftwidth = 2

if vim.fn.has("persistent_undo") then
  vim.o.undofile = true
  vim.o.swapfile = false
  vim.o.undodir = vim.fn.stdpath('data') .. '/.undodir/'
  if not vim.fn.isdirectory(vim.o.undodir) then
    vim.fn.mkdir(vim.o.undodir, "p", 0700)
  end
end

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
local function on_attach(client, bufnr)
  local telescope = require('telescope.builtin')
  local wk = require('which-key')
  wk.register({
    x = { vim.cmd.Ex, 'e[x]plorer' },
    c = {
      name = '[c]ode',
      a = { vim.lsp.buf.code_action, '[a]ction' },
      r = { vim.lsp.buf.rename, '[r]ename' }
    },
    p = {
      name = '[p]retty',
      p = { vim.cmd.Prettier, '[p]rettier' },
      l = { vim.cmd.Format, '[l]sp' },
    },
    h = {
      name = '[h]over',
      s = { vim.lsp.buf.signature_help, '[s]ignature' },
      d = { vim.lsp.buf.hover, '[h]over [d]ocumentation' },
      t = { telescope.lsp_type_definitions, '[h]over [t]ype definition' },
    },
    f = {
      name = '[f]ind',
      g = { telescope.live_grep, '[g]rep' },
      f = { telescope.find_files, '[f]iles' },
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

  if client.name == 'tsserver' then
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.lsp.handlers['textDocument/publishDiagnostics'] = function(_, result, ctx, config)
      result['diagnostics'] = vim.tbl_filter(function(diagnostic)
        return diagnostic.message ~= "Cannot find name 'React'."
      end, result.diagnostics)
      vim.lsp.diagnostic.on_publish_diagnostics(_, result, ctx, config)
    end
  end
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
  -- autosave
  { 'pocco81/auto-save.nvim' },
  -- undo history
  {
    'mbbill/undotree',
    config = function()
      require('which-key').register({
        u = {
          name = '[u]ndo',
          s = { vim.cmd.UndotreeShow, '[s]how' },
          h = { vim.cmd.UndotreeHide, '[h]ide' },
          t = { vim.cmd.UndotreeToggle, '[t]oggle' },
        }
      }, { prefix = '<leader>' })
    end
  },
  -- formatting
  { 'prettier/vim-prettier', build = 'npm install', },
  -- quick-comment
  {
    'numToStr/Comment.nvim',
    opts = {
      toggler = {
        line = '<leader>/',
        block = '<leader>*',
      },
      opleader = {
        line = '<leader>/',
        block = '<leader>*',
      },
    }
  },
  -- auto tabstop/shiftwidth
  { 'tpope/vim-sleuth' },
  -- keybind help
  {
    'folke/which-key.nvim',
    opts = {}
  },
  -- gitsigns
  { 'lewis6991/gitsigns.nvim' },
  {
    -- Theme inspired by Atom
    'navarasu/onedark.nvim',
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'onedark'
    end,
  },
  -- status line
  {
    'nvim-lualine/lualine.nvim',
    opts = {
      options = {
        icons_enabled = false,
        component_separators = '|',
        section_separators = '',
        theme = 'onedark',
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
  gopls = {},
  bashls = {},
  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    }
  },
  eslint = {},
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
      filetypes = (servers[server_name] or {}).filetypes,
      root_dir = (servers[server_name] or {}).root_dir or function(fname)
        return lspconfig.util.find_git_ancestor(fname) or lspconfig.util.path.dirname(fname)
      end,
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
  ---@diagnostic disable-next-line: missing-fields
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

function client_is_active(name)
  local clients = vim.lsp.get_active_clients()
  for _, client in ipairs(clients or {}) do
    if client.name == name then
      return true
    end
  end

  return false
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client_id = args.data.client_id
    local client = vim.lsp.get_client_by_id(client_id)
    local bufnr = args.buf
    local wk = require('which-key')

    if client.name == 'tsserver' then
      vim.api.nvim_buf_create_user_command(bufnr, 'OrganizeImports', function(_)
        vim.lsp.buf.execute_command({
          command = '_typescript.organizeImports',
          arguments = { vim.api.nvim_buf_get_name(bufnr) },
          title = 'Organize Imports',
        })
      end, { desc = 'Sort and remove unused imports' })
      wk.register({
        i = { vim.cmd.OrganizeImports, '[i]mports' }
      }, { prefix = '<leader>p', buffer = bufnr })
    end
    if client.name == 'eslint' then
      vim.keymap.set('n', '<leader>pe', vim.cmd.EslintFixAll, {
        buffer = bufnr, desc = '[e]slint'
      })
      wk.register({
        e = { vim.cmd.OrganizeImports, '[e]slint' }
      }, { prefix = '<leader>p', buffer = bufnr })
    end

    if client_is_active('tsserver') and client_is_active('eslint') then
      wk.register({
        w = { function()
          for _, cmd in ipairs({
            'OrganizeImports',
            'EslintFixAll',
            'Prettier',
          }) do
            vim.cmd(cmd)
          end
        end, '[w]eb' }
      }, { prefix = '<leader>p', buffer = bufnr })
    end
  end
})

-- [[ SNIPPETS ]]
local ls = require('luasnip')
ls.add_snippets(nil, {
  html = {
    ls.snippet({
      trig = "favicon",
      namr = "Favicon",
      descr = "Empty HTML favicon",
    }, {
      ls.text_node({ '<link rel="icon" href="data:;base64,iVBORw0KGgo=">' }),
    })
  }
})
