---@brief
---
--- https://github.com/godotengine/godot
---
--- Language server for GDScript, served by a running Godot editor.
--- Godot must be open on the project; it listens on 127.0.0.1:6005 by default.

local port = os.getenv("GDScript_Port") or "6005"

---@type vim.lsp.Config
return {
	cmd = vim.lsp.rpc.connect("127.0.0.1", tonumber(port)),
	filetypes = { "gdscript" },
	root_markers = { "project.godot", ".git" },
}
