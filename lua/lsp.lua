vim.lsp.enable({
	"lua_ls",
	"ts_ls",
	"svelte",
	"gopls",
	"jsonls",
	"yamlls",
	"zls",
	"html",
	"cssls",
	"nginx",
	"nixd",
	"bashls",
	"marksman",
})

-- Configure snippets
require("luasnip.loaders.from_vscode").lazy_load()
require("blink.cmp").setup({
	fuzzy = {
		implementation = "prefer_rust",
		prebuilt_binaries = {
			download = true,
			force_version = "v1.9.1",
		},
	},
	signature = { enabled = true },
	completion = {
		documentation = { auto_show = true, auto_show_delay_ms = 500 },
		menu = {
			auto_show = true,
			draw = {
				treesitter = { "lsp" },
				columns = { { "kind_icon", "label", "label_description", gap = 1 }, { "kind" } },
			},
		},
	},
})
