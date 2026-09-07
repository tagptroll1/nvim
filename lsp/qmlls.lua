---@brief
---
--- https://doc.qt.io/qt-6/qtqml-tooling-qmlls.html
---
--- QML Language Server, shipped with Qt 6 (qt6.qtdeclarative).
---
--- Qt and Quickshell import paths come from `.qmlls.ini` in the project root -
--- quickshell rewrites that file itself on every run, so it is gitignored.
--- It does not cover quickshell's own `import qs.Foo` module syntax, so a
--- `.qmlls/qs -> ..` symlink next to it is passed as an extra import path.

---@type vim.lsp.Config
return {
	cmd = function(dispatchers, config)
		local args = { "qmlls" }
		local imports = config.root_dir and (config.root_dir .. "/.qmlls")
		if imports and vim.uv.fs_stat(imports) then
			vim.list_extend(args, { "-I", imports })
		end
		return vim.lsp.rpc.start(args, dispatchers, { cwd = config.root_dir })
	end,
	filetypes = { "qml", "qmljs" },
	root_markers = { ".qmlls.ini", ".git" },
}
