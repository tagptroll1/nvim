local M = {}

local function marker_for(ft)
	return ft == "rust" and "Cargo.toml" or ft == "go" and "go.mod"
		or ft == "python" and "pyproject.toml" or "package.json"
end

-- line scan, since nvim has no TOML parser; only needs section headers and script names
local function read_pyproject(root)
	local info, section = {}, nil
	for _, line in ipairs(vim.fn.readfile(root .. "/pyproject.toml")) do
		local header = line:match("^%s*%[([^%]]+)%]")
		if header then
			section = header
			info.mypy = info.mypy or header == "tool.mypy"
		elseif section == "project.scripts" and not info.script then
			info.script = line:match([[^%s*["']?([%w%._-]+)["']?%s*=]])
		end
	end
	return info
end

function M.has_root(buf)
	return vim.fs.root(buf, marker_for(vim.bo[buf].filetype)) ~= nil
end

function M.run(action)
	local saved, err = pcall(vim.cmd, "wall")
	if not saved then
		vim.notify("Command cancelled: could not save all files\n" .. tostring(err), vim.log.levels.ERROR)
		return
	end

	local ft = vim.bo.filetype
	local marker = marker_for(ft)
	local root = vim.fs.root(0, marker)
	if not root then
		vim.notify("No " .. marker .. " found for current buffer", vim.log.levels.WARN)
		return
	end

	local cmd, program, title
	if ft == "rust" then
		cmd = { "cargo", action }
	elseif ft == "go" then
		cmd = { "go", action == "check" and "vet" or action, action == "run" and "." or "./..." }
	elseif ft == "python" then
		local pyproject = read_pyproject(root)
		local steps = {
			-- without a [project.scripts] entry, run the current file as a script
			run = { "uv run " .. (pyproject.script or vim.fn.shellescape(vim.api.nvim_buf_get_name(0))) },
			test = { "uv run pytest" },
			build = { "uv build" },
			-- uv run falls back to PATH, so ruff works from the devshell or as a dev dependency
			check = { "uv run ruff check" },
		}
		if pyproject.mypy then
			table.insert(steps.check, "uv run mypy .")
		end
		program = "uv"
		title = table.concat(steps[action], " && ")
		cmd = { "sh", "-c", title }
	else
		local ok, package = pcall(function()
			return vim.json.decode(table.concat(vim.fn.readfile(root .. "/package.json"), "\n"))
		end)
		if not ok or type(package) ~= "table" then
			vim.notify("Cannot read package.json", vim.log.levels.ERROR)
			return
		end
		local scripts = type(package.scripts) == "table" and package.scripts or {}
		local wanted = action == "run" and { scripts.dev and "dev" or "start" }
			or action == "check" and { "check", "lint" }
			or { action }
		local manager = vim.fs.root(root, "pnpm-lock.yaml") and "pnpm" or "npm"
		local steps = {}
		for _, script in ipairs(wanted) do
			if type(scripts[script]) == "string" then
				steps[#steps + 1] = manager .. " run " .. script
			end
		end
		if #steps == 0 then
			vim.notify("No " .. table.concat(wanted, " or ") .. " script in package.json", vim.log.levels.WARN)
			return
		end
		program = manager
		title = table.concat(steps, " && ")
		-- sh so check can chain whichever of its scripts exist
		cmd = { "sh", "-c", title }
	end
	program = program or cmd[1]
	title = title or table.concat(cmd, " ")
	if vim.fn.executable(program) == 0 then
		vim.notify(program .. " is not installed", vim.log.levels.ERROR)
		return
	end

	-- run may prompt for input, so its keys go to the process instead of dismissing the float
	local interactive = action == "run"
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
		title = " " .. title .. " ",
		footer = interactive and " Esc, Ctrl+C or click closes and stops command "
			or " Any key closes and stops command ",
		footer_pos = "center",
	})
	vim.bo[buf].bufhidden = "wipe"
	local ns = vim.api.nvim_create_namespace("project-run-" .. buf)
	local job
	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end
	local function close_on_any_key()
		-- Consume input so dismissal cannot trigger editor mappings or reach the process.
		vim.on_key(function()
			if vim.api.nvim_get_current_win() == win then
				vim.schedule(close)
				return ""
			end
		end, ns)
	end
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
					close_on_any_key()
				end
			end)
		end,
	})
	if job <= 0 then
		vim.api.nvim_win_close(win, true)
		vim.notify("Failed to start " .. program, vim.log.levels.ERROR)
		return
	end
	if interactive then
		for _, key in ipairs({ "<Esc>", "<C-c>", "<LeftMouse>" }) do
			vim.keymap.set({ "t", "n" }, key, close, { buffer = buf, nowait = true })
		end
		vim.cmd.startinsert()
	else
		vim.cmd.stopinsert()
		close_on_any_key()
	end
end

return M
