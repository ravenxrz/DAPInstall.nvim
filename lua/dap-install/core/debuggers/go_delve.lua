local M = {}

local dbg_path = require("dap-install.config.settings").options["installation_path"] .. "go_delve/"

M.details = {
	dependencies = { "go" },
}

M.dap_info = {
	name_adapter = "go",
	name_configuration = "go",
}

M.config = {
	adapters = function(callback, config)
		local stdout = vim.loop.new_pipe(false)
		local handle
		local pid_or_err
		local port = 38697
		local opts = {
			stdio = { nil, stdout },
			args = { "dap", "--check-go-version=false", "--listen=127.0.0.1:" .. port },
			detached = true,
		}
		handle, pid_or_err = vim.loop.spawn("dlv", opts, function(code)
			stdout:close()
			handle:close()
			if code ~= 0 then
				print("dlv exited with code", code)
			end
		end)
		assert(handle, "Error running dlv: " .. tostring(pid_or_err))
		stdout:read_start(function(err, chunk)
			assert(not err, err)
			if chunk then
				vim.schedule(function()
					require("dap.repl").append(chunk)
				end)
			end
		end)
		-- Wait for delve to start
		vim.defer_fn(function()
			callback({ type = "server", host = "127.0.0.1", port = port })
		end, 300)
	end,
	configurations = {
		{
			type = "go",
			name = "Debug curr file",
			request = "launch",
			program = "${file}",
		},
		{
			type = "go",
			name = "Debug",
			request = "launch",
			program = "${workspaceFolder}",
		},
		{
			type = "go",
			name = "Debug curr test", -- configuration for debugging test files
			request = "launch",
			mode = "test",
			program = "${file}",
		},
		-- works with go.mod packages and sub packages
		{
			type = "go",
			name = "Debug test",
			request = "launch",
			mode = "test",
			program = "${workspaceFolder}",
		},
		{
			type = "go",
			name = "Attach",
			request = "attach",
			processId = require("dap.utils").pick_process,
			program = "${workspaceFolder}",
		},
	},
}

M.installer = {
	before = "",
	install = [[
		git clone https://github.com/go-delve/delve && cd delve
		go install github.com/go-delve/delve/cmd/dlv

	]],
	uninstall = "simple",
}

return M
