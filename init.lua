-- [[ OPTIONS ]]
vim.g.mapleader = ','
vim.g.maplocalleader = ','
vim.g.have_nerd_font = false
vim.opt.number = true
vim.opt.mouse = 'a'
vim.opt.showmode = false
vim.opt.clipboard = 'unnamedplus'
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.wrap = true
vim.opt.textwidth = 120;
vim.cmd.colorscheme 'slate'

function nmap(keys, fn, desc)
  vim.keymap.set('n', '<leader>'..keys, fn, { desc = desc })
end

-- [[ KEYMAPS ]]
nmap('dp', vim.diagnostic.goto_prev, '[D]iagnostic ([P]revous)')
nmap('dp', vim.diagnostic.goto_next, '[D]iagnostic ([N]ext)')
nmap('do', vim.diagnostic.open_float, '[D]iagnostic ([O]pen)')

-- [[ PLUGINS ]]
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    config = function ()
      require('which-key').setup()
    end,
  },
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function ()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
    },
    config = function ()
      require('telescope').setup({
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      })

      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require('telescope.builtin')
      nmap('ff', builtin.find_files, '[F]ind [F]iles')
      nmap('fg', builtin.live_grep, '[F]ind [G]rep')
      nmap('fr', builtin.resume, '[F]ind [R]resume')
      nmap('fo', builtin.oldfiles, '[F]ind [O]ld files')
      nmap('fb', builtin.buffers, '[F]ind [B]ltin.find_files')
    end
  },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    opts = {
      ensure_installed = { 'lua', 'vim', 'bash', 'javascript', 'php', 'markdown', 'json' },
      auto_install = true,
      highlight = {
        enable = true,
      },
      indent = { enable = true },
    },
    config = function(_, opts)
      require('nvim-treesitter.install').prefer_git = true
      require('nvim-treesitter.configs').setup(opts)
      vim.opt.foldmethod = 'expr'
      vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
      vim.opt.foldenable = false
    end
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
    },
    config = function ()
      local lspconfig = require('lspconfig')
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())
      require('mason').setup()
      require('mason-tool-installer').setup({
        ensure_installed = { 'lua_ls', 'tsserver', 'intelephense' },
      })
      require('mason-lspconfig').setup({
        handlers = {
          function (server_name)
            lspconfig[server_name].setup({ capabilities = capabilities })
          end
        }
      })
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function (event)
          nmap('ca', vim.lsp.buf.hover, '[C]ode [A]ction')
          nmap('rn', vim.lsp.buf.rename, '[R]e[n]ame' )
          nmap('hd', vim.lsp.buf.hover, '[H]over [D]ocumentation'  )
        end
      })
    end,
  },
  {
     'stevearc/conform.nvim',
     opts = {},
     notify_on_error = true,
     format_on_save = function (_bufnr)
       return {
         timeout_ms = 500,
         lsp_fallback = true,
       }
     end,
     formatters_by_ft = {
       lua = { 'stylua' },
       javascript = { { 'prettierd', 'prettier' } },
     },
  },
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'L3MON4D3/LuaSnip',
    },
    config = function ()
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      luasnip.setup()
      cmp.setup({
        snippet = {
          expand = function (args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = 'menu,menuone,noinsert' },
        mapping = cmp.mapping.preset.insert({
          ['<C-n>'] = cmp.mapping.select_next_item(),
          ['<C-p>'] = cmp.mapping.select_prev_item(),
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-y>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping.confirm({ select = true }),
          ['<C-Space>'] = cmp.mapping.complete(),
        }),
        sources = {
          { name = 'nvim_lsp' },
          { name = 'path' },
          { name = 'luasnip' },
        }
      })
  end
  },
})

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
