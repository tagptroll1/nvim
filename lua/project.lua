local M = {}

function M.run(action)
	local saved, err = pcall(vim.cmd, "wall")
	if not saved then
		vim.notify("Command cancelled: could not save all files\n" .. tostring(err), vim.log.levels.ERROR)
		return
	end

	local ft = vim.bo.filetype
	local marker = ft == "rust" and "Cargo.toml" or ft == "go" and "go.mod" or "package.json"
	local root = vim.fs.root(0, marker)
	if not root then
		vim.notify("No " .. marker .. " found for current buffer", vim.log.levels.WARN)
		return
	end

	local cmd
	if ft == "rust" then
		cmd = { "cargo", action }
	elseif ft == "go" then
		cmd = { "go", action, action == "run" and "." or "./..." }
	else
		local ok, package = pcall(function()
			return vim.json.decode(table.concat(vim.fn.readfile(root .. "/package.json"), "\n"))
		end)
		if not ok or type(package) ~= "table" then
			vim.notify("Cannot read package.json", vim.log.levels.ERROR)
			return
		end
		local scripts = type(package.scripts) == "table" and package.scripts or {}
		local script = action == "run" and (scripts.dev and "dev" or "start") or action
		if type(scripts[script]) ~= "string" then
			vim.notify("No " .. script .. " script in package.json", vim.log.levels.WARN)
			return
		end
		local manager = vim.fs.root(root, "pnpm-lock.yaml") and "pnpm" or "npm"
		cmd = { manager, "run", script }
	end
	if vim.fn.executable(cmd[1]) == 0 then
		vim.notify(cmd[1] .. " is not installed", vim.log.levels.ERROR)
		return
	end

	local buf = vim.api.nvim_create_buf(false, true)
	local width = math.max(1, math.min(math.floor(vim.o.columns * 0.85), vim.o.columns - 4))
	local height = math.max(1, math.min(math.floor(vim.o.lines * 0.75), vim.o.lines - 4))
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
		col = math.max(0, math.floor((vim.o.columns - width) / 2)),
		style = "minimal",
		border = "rounded",
		title = " " .. table.concat(cmd, " ") .. " ",
		footer = " Any key closes and stops command ",
		footer_pos = "center",
	})
	vim.bo[buf].bufhidden = "wipe"
	local ns = vim.api.nvim_create_namespace("project-run-" .. buf)
	local job
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = buf,
		once = true,
		callback = function()
			vim.on_key(nil, ns)
			if job and job > 0 then
				vim.fn.jobstop(job)
			end
		end,
	})
	job = vim.fn.jobstart(cmd, {
		cwd = root,
		term = true,
		on_exit = function(_, code)
			job = nil
			vim.schedule(function()
				if vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_win_set_config(win, { footer = " Exit " .. code .. " | Any key closes " })
				end
			end)
		end,
	})
	if job <= 0 then
		vim.api.nvim_win_close(win, true)
		vim.notify("Failed to start " .. cmd[1], vim.log.levels.ERROR)
		return
	end
	vim.cmd.stopinsert()
	-- Consume input so dismissal cannot trigger editor mappings or reach the process.
	vim.on_key(function()
		if vim.api.nvim_get_current_win() == win then
			vim.schedule(function()
				if vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_win_close(win, true)
				end
			end)
			return ""
		end
	end, ns)
end

return M
