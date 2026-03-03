require "opts"

vim.pack.add({
	{ src = "https://github.com/catppuccin/nvim" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
	{ src = "https://github.com/ibhagwan/fzf-lua" },
	{ src = "https://github.com/LuxVim/nvim-luxmotion" },
	{ src = "https://github.com/L3MON4D3/LuaSnip" },
	{ src = "https://github.com/rafamadriz/friendly-snippets" },
	{ src = "https://github.com/Saghen/blink.cmp" },
})

require "nvim-treesitter.configs".setup({
	ensure_installed = {
		"svelte", "typescript", "javascript", "go",
		"lua", "nix", "yaml", "json", "html", "css", "zig",
		"bash", "markdown", -- generally useful on a server
	},
	highlight = { enable = true },
	sync_install = false,
	auto_install = true,
	ignore_install = {},
	modules = {},
})
require "oil".setup()
require "fzf-lua".setup({
	keymap = { fzf = { ["ctrl-q"] = "select-all+accept" } }
})
require "luxmotion".setup({
	cursor = {
		duration = 100,
		easing = "ease-out",
		enabled = true,
	},
	scroll = {
		duration = 100,
		easing = "ease-out",
		enabled = true,
	},
	performance = { enabled = true },
	keymaps = {
		cursor = true,
		scroll = true,
	},
})

require "lsp"
require "keymaps"
require "autocmd"

vim.cmd("colorscheme catppuccin-mocha")
vim.cmd(":hi statusline guibg=NONE")
