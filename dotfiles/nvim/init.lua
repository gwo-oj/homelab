vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local o = vim.opt
o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.scrolloff = 8
o.wrap = false
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.smartindent = true
o.list = true
o.listchars = { tab = "▸ ", trail = "·", nbsp = "␣" }
o.ignorecase = true
o.smartcase = true
o.splitright = true
o.splitbelow = true
o.undofile = true
o.swapfile = false
o.updatetime = 250
o.timeoutlen = 400
o.termguicolors = true
o.showmode = false
o.laststatus = 3
o.clipboard = "unnamedplus"
o.confirm = true

local map = vim.keymap.set
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })
map("n", "<C-h>", "<C-w>h"); map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k"); map("n", "<C-l>", "<C-w>l")
map("v", "<", "<gv"); map("v", ">", ">gv")
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")
map("x", "<leader>p", [["_dP]], { desc = "Paste without yanking" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end)
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end)
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })

local aug = vim.api.nvim_create_augroup("homelab", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = aug,
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

-- Encrypted SOPS files should be edited with `sops`, not directly.
vim.api.nvim_create_autocmd("BufRead", {
  group = aug,
  pattern = "*.sops.yaml",
  callback = function(ev)
    for _, l in ipairs(vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)) do
      if l:match("^sops:") then
        vim.bo[ev.buf].modifiable = false
        vim.notify("Encrypted file, edit with: sops " .. vim.fn.expand("%"), vim.log.levels.WARN)
        return
      end
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = aug,
  pattern = { "*/templates/*.yaml", "*/templates/*.tpl" },
  callback = function(ev) vim.bo[ev.buf].filetype = "helm" end,
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "catppuccin" } },
  checker = { enabled = false },
  change_detection = { notify = false },
})
