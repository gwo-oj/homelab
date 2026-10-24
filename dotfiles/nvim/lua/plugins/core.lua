return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      integrations = { telescope = true, gitsigns = true, cmp = true,
                       treesitter = true, which_key = true, mason = true },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = { theme = "catppuccin", globalstatus = true,
                  section_separators = "", component_separators = "│" },
      sections = {
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "diagnostics", "filetype" },
      },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make",
        cond = function() return vim.fn.executable("make") == 1 end },
    },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>",  desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>",   desc = "Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>",     desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>",   desc = "Help" },
      { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
      { "<leader>fr", "<cmd>Telescope resume<CR>",      desc = "Resume" },
    },
    opts = {
      defaults = {
        file_ignore_patterns = { "%.git/", "node_modules/", "%.task/", "charts/" },
        path_display = { "truncate" },
      },
    },
    config = function(_, opts)
      require("telescope").setup(opts)
      pcall(require("telescope").load_extension, "fzf")
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "yaml", "json", "toml", "bash", "lua", "markdown", "markdown_inline",
        "dockerfile", "hcl", "go", "python", "gitcommit", "diff", "regex", "vim",
      },
      highlight = { enable = true },
      indent = { enable = true, disable = { "yaml" } },  -- treesitter yaml indent is unreliable
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = { add = { text = "┃" }, change = { text = "┃" }, delete = { text = "▁" } },
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function m(l, r, d) vim.keymap.set("n", l, r, { buffer = buf, desc = d }) end
        m("]c", gs.next_hunk,    "Next hunk")
        m("[c", gs.prev_hunk,    "Prev hunk")
        m("<leader>hp", gs.preview_hunk, "Preview hunk")
        m("<leader>hb", function() gs.blame_line({ full = true }) end, "blame")
      end,
    },
  },
  { "folke/which-key.nvim", event = "VeryLazy", opts = { preset = "helix" } },
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics list" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<CR>",      desc = "Quickfix" },
    },
    opts = {},
  },
  {
    "stevearc/oil.nvim",
    lazy = false,
    keys = { { "-", "<cmd>Oil<CR>", desc = "Parent directory" } },
    opts = { view_options = { show_hidden = true } },
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path",
      { "L3MON4D3/LuaSnip", build = "make install_jsregexp" },
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp, luasnip = require("cmp"), require("luasnip")
      cmp.setup({
        snippet = { expand = function(a) luasnip.lsp_expand(a.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<C-e>"]     = cmp.mapping.abort(),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources(
          { { name = "nvim_lsp" }, { name = "luasnip" } },
          { { name = "buffer" }, { name = "path" } }
        ),
      })
    end,
  },
}
