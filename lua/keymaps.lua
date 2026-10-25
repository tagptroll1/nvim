local FzfLua = require("fzf-lua")

-- tmux owns <C-w>; s and v split the same way as in tmux.conf
vim.keymap.set('n', '<C-s>s', '<C-w>v', { desc = "Split side by side" })
vim.keymap.set('n', '<C-s>v', '<C-w>s', { desc = "Split top and bottom" })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = "Exit terminal input mode" })

vim.keymap.set('n', '<leader>o', ':update<CR> :source<CR>', { desc = "Save and source file" })
vim.keymap.set('n', '<leader>w', ':write<CR>', { desc = "Save file" })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = "Half page up, centered" })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = "Half page down, centered" })
vim.keymap.set('n', '<M-j>', 'ddp', { desc = "Move line down" })
vim.keymap.set('n', '<M-k>', 'ddkP', { desc = "Move line up" })
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>y', '"+y', { desc = "Yank to system clipboard" })
vim.keymap.set('x', '<C-S-c>', '"+y', { desc = "Copy selection to system clipboard" })
vim.keymap.set('n', '<Esc>', ':nohlsearch<CR>', { desc = "Clear search highlight" })
vim.keymap.set('n', '<leader>sf', FzfLua.files, { desc = "Search Files in project" })
vim.keymap.set('n', '<leader>sg', FzfLua.grep_project, { desc = "Search with ripGrep project" })
vim.keymap.set('n', '<leader>sk', FzfLua.keymaps, { desc = "Search Keymaps" })
vim.keymap.set('n', '<leader>sq', FzfLua.quickfix, { desc = "Search Quickfix" })
vim.keymap.set('n', '<leader>h', FzfLua.helptags, { desc = "Get Help" })
vim.keymap.set('n', '<leader>e', ":Oil<CR>", { desc = "Open Oil" })
vim.keymap.set('n', '<leader>up', vim.pack.update, { desc = "Update Plugins" })

-- buffer-local, so these exist and show in which-key only where they can act
local contextual = vim.api.nvim_create_augroup('ContextualKeymaps', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
	group = contextual,
	callback = function(ev)
		if not require('project').has_root(ev.buf) then
			return
		end
		for key, action in pairs({ t = "test", r = "run", b = "build", c = "check" }) do
			vim.keymap.set('n', '<leader>p' .. key, function()
				require('project').run(action)
			end, { buffer = ev.buf, desc = "Project " .. action })
		end
	end,
})

vim.api.nvim_create_autocmd('FileType', {
	group = contextual,
	pattern = 'markdown',
	callback = function(ev)
		-- own flag rather than the plugin's internal state, so modifiable flips in step with it
		vim.keymap.set('n', '<leader>m', function()
			local rendered = not vim.b.markdown_rendered
			vim.b.markdown_rendered = rendered
			require("render-markdown").set_buf(rendered)
			vim.bo.modifiable = not rendered
		end, { buffer = ev.buf, desc = "Toggle Markdown render" })
	end,
})

vim.api.nvim_create_autocmd('LspAttach', {
	group = contextual,
	callback = function(ev)
		local function map(lhs, rhs, desc)
			vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, desc = desc })
		end
		map('<leader>sc', FzfLua.lsp_document_symbols, "Search Code in document")
		map('<leader>sw', FzfLua.lsp_workspace_symbols, "Search code in Workspace")
		map('<leader>de', FzfLua.lsp_document_diagnostics, "Diagnostics Errors")
		map('<leader>dw', FzfLua.lsp_workspace_diagnostics, "Diagnostics erros in Workspace")
		map('<leader>f', vim.lsp.buf.format, "Format buffer")
		map('<leader>cr', vim.lsp.buf.rename, "Rename symbol")
		map('<leader>ca', FzfLua.lsp_code_actions, "Code action")
		map('gd', FzfLua.lsp_definitions, "Go to Definition")
		map('gr', FzfLua.lsp_references, "Go to References")
		map('gi', FzfLua.lsp_implementations, "Go to Implementations")
	end,
})

-- prefixes are not keymaps, so their popup label has to come from which-key
local wk = require("which-key")
wk.add({
	{ "<leader>d", group = "Diagnostics", icon = { icon = "󰓙 ", color = "red" } },
	{ "<leader>p", group = "Project", icon = { icon = "󱓞 ", color = "purple" } },
	{ "<leader>s", group = "Search", icon = { icon = "󰍉 ", color = "green" } },
	{ "<leader>c", group = "Code", icon = { icon = "󰅴 ", color = "orange" } },
	{ "<leader>u", group = "Update", icon = { icon = "󰚰 ", color = "azure" } },
	{ "<C-s>", group = "Split", icon = { icon = "󰯌 ", color = "blue" } },
})

-- real: an icon-only entry would otherwise list its key in buffers where the keymap is absent
wk.add({
	real = true,
	{ "<C-s>s", icon = { icon = "󰯌 ", color = "blue" } },
	{ "<C-s>v", icon = { icon = "󰯋 ", color = "blue" } },
	{ "<leader>o", icon = { icon = "󰑓 ", color = "cyan" } },
	{ "<leader>w", icon = { icon = "󰆓 ", color = "cyan" } },
	{ "<leader>h", icon = { icon = "󰋗 ", color = "blue" } },
	{ "<leader>e", icon = { icon = "󰉋 ", color = "yellow" } },
	{ "<leader>m", icon = { icon = "󰍔 ", color = "azure" } },
	{ "<leader>f", icon = { icon = "󰁨 ", color = "cyan" } },
	{ "<leader>sf", icon = { icon = "󰱼 ", color = "green" } },
	{ "<leader>sg", icon = { icon = "󱎸 ", color = "green" } },
	{ "<leader>sk", icon = { icon = "󰌌 ", color = "green" } },
	{ "<leader>sq", icon = { icon = "󰝖 ", color = "green" } },
	{ "<leader>sc", icon = { icon = "󰅩 ", color = "green" } },
	{ "<leader>sw", icon = { icon = "󰥨 ", color = "green" } },
	{ "<leader>de", icon = { icon = "󰀨 ", color = "red" } },
	{ "<leader>dw", icon = { icon = "󰀦 ", color = "red" } },
	{ "<leader>cr", icon = { icon = "󰑕 ", color = "orange" } },
	{ "<leader>ca", icon = { icon = "󰌵 ", color = "orange" } },
	{ "<leader>up", icon = { icon = "󰏖 ", color = "azure" } },
	{ "<leader>pr", icon = { icon = "󰐊 ", color = "purple" } },
	{ "<leader>pt", icon = { icon = "󰙨 ", color = "purple" } },
	{ "<leader>pb", icon = { icon = "󰣪 ", color = "purple" } },
	{ "<leader>pc", icon = { icon = "󰄭 ", color = "purple" } },
	{ "<leader>y", mode = { "n", "v" }, icon = { icon = "󰆏 ", color = "cyan" } },
})
