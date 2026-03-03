local function au(typ, callback, g, desc)
	vim.api.nvim_create_autocmd(typ, { callback = callback, group = g, desc = desc })
end

vim.cmd("set completeopt+=noselect")

-- Highlight yanked text
local highlight_yank = vim.api.nvim_create_augroup('HighlightYank', { clear = true })
au('TextYankPost', function() vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 150 }) end,
	highlight_yank,
	'highlight yanked text'
)

local group = vim.api.nvim_create_augroup('OoO', {})
au({ 'CursorHold', 'InsertLeave' }, function()
	local opts = {
		focusable = false,
		scope = 'cursor',
		close_events = { 'BufLeave', 'CursorMoved', 'InsertEnter' },
	}
	vim.diagnostic.open_float(nil, opts)
end, group)
au('InsertEnter', function() vim.diagnostic.enable(false) end, group)
au('InsertLeave', function() vim.diagnostic.enable(true) end, group)

vim.api.nvim_create_autocmd('BufWritePre',{
  pattern = {"*.zig", "*.zon"},
  callback = function(ev)
		vim.lsp.buf.format()
    vim.lsp.buf.code_action({
      context = { only = { "source.fixAll" } },
      apply = true,
    })
		vim.lsp.buf.code_action({
      context = { only = { "source.organizeImports" } },
      apply = true,
    })
  end
})
