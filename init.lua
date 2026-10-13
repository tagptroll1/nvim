require "opts"

vim.pack.add({
	{ src = "https://github.com/catppuccin/nvim" },
	-- palette-driven scheme, fed the current omarchy theme by _G.OmarchyTheme below
	{ src = "https://github.com/bjarneo/aether.nvim", version = "v3" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
	-- master is archived and breaks on nvim 0.12 query directives; main is the 0.12+ branch
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
	{ src = "https://github.com/ibhagwan/fzf-lua" },
	{ src = "https://github.com/LuxVim/nvim-luxmotion" },
	{ src = "https://github.com/L3MON4D3/LuaSnip" },
	{ src = "https://github.com/rafamadriz/friendly-snippets" },
	{ src = "https://github.com/Saghen/blink.cmp" },
	-- C-hjkl crosses nvim splits and tmux panes alike
	{ src = "https://github.com/christoomey/vim-tmux-navigator" },
	{ src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
	{ src = "https://github.com/folke/which-key.nvim" },
})

-- require "nvim-treesitter".setup({
-- 	install_dir = vim.fn.stdpath("data") .. "/site",
-- })

local ts_languages = {
	"svelte", "typescript", "javascript", "go", "rust",
	"lua", "nix", "yaml", "json", "html", "css", "zig",
	"bash", "markdown", "markdown_inline",
	"gdscript", "godot_resource", "gdshader",
	"vim", "python", "xml",
}

-- main has no auto_install, so every parser is listed. Async; run :TSUpdate after plugin updates.
require "nvim-treesitter".install(ts_languages)

vim.api.nvim_create_autocmd("FileType", {
	pattern = ts_languages,
	callback = function()
		if not pcall(vim.treesitter.start) then
			return
		end
		vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		vim.wo[0][0].foldexpr = "v.lua.vim.treesitter.foldexpr()"
	end,
})
require "oil".setup()
-- pruned by rg itself, so projects without a .gitignore don't walk these trees
local noise_dirs = {
	"node_modules", "target", "dist", "build", ".svelte-kit", ".next",
	"zig-out", ".zig-cache", ".godot", ".direnv", ".venv", "__pycache__", ".cache",
}
local noise_glob = [[-g "!{]] .. table.concat(noise_dirs, ",") .. [[}"]]
require "fzf-lua".setup({
	keymap = { fzf = { ["ctrl-q"] = "select-all+accept" } },
	files = {
		rg_opts = [[--color=never --files -g "!.git" ]] .. noise_glob,
	},
	grep = {
		-- fzf-lua appends the pattern, so -e has to stay last
		rg_opts = "--column --line-number --no-heading --color=always --smart-case "
			.. "--max-columns=4096 " .. noise_glob .. " -e",
	},
})
-- one picker for every vim.ui.select prompt; code actions warn on each call otherwise
require "fzf-lua".register_ui_select()
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
-- off by default so markdown opens as raw source; <leader>m renders per buffer
require "render-markdown".setup({
	enabled = false,
	-- rendered view is read-only, so the cursor line stays rendered too:
	-- anti_conceal reveals the plugin's marks, concealcursor reveals nvim's own conceals
	anti_conceal = { enabled = false },
	win_options = { concealcursor = { rendered = "nvic" } },
})
-- helix preset anchors the popup to the lower right instead of a full-width bottom bar
require "which-key".setup({ preset = "helix" })

require "lsp"
require "keymaps"
require "autocmd"

-- omarchy-theme-set stages the picked theme's palette here and then calls
-- omarchy-theme-set-nvim, which invokes this over each running instance's socket.
-- Global so --remote-expr can reach it.
function _G.OmarchyTheme()
	local staged = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
	local ok, colors = pcall(dofile, staged)

	-- check a known key: a stale staged neovim.lua from before this was wired is a
	-- LazyVim spec, which is also a table but has nothing aether can use
	if ok and type(colors) == "table" and colors.bg then
		require("aether").setup({ colors = colors })
		vim.cmd.colorscheme("aether")
	else
		-- no omarchy theme staged, or the file is mid-write during a theme switch
		vim.cmd.colorscheme("catppuccin-mocha")
	end

	vim.cmd(":hi statusline guibg=NONE")
end

_G.OmarchyTheme()
