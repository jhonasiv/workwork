local M = {}

local core = require("workwork.core")
M.actions = require("workwork.actions")
M.config = require("workwork.config")

M.setup = function(user_opts)
	if not pcall(require, "plenary") then
		error("nvim-lua/plenary.nvim is a required dependency, please install it.")
	end

	_WorkWorkOpts = vim.tbl_deep_extend("force", M.config.default, user_opts)
	user_opts = _WorkWorkOpts

	local file = io.open(user_opts.state_file, "r")
	local create_file_anew = file == nil
	if file then
		file:close()
	else
		error("Could not open file at " .. user_opts.state_file)
	end

	if create_file_anew then
		file = io.open(user_opts.state_file, "w")
		if file then
			file:write(vim.fn.json_encode({}))
			file:close()
		else
			error("Failed trying to write to storage file at " .. user_opts.state_file)
		end
	end

	-- autoload workspace on setup
	core.load()

	if user_opts.integrations.fzf_lua.enabled then
		local integration = require("workwork.integrations.fzf").setup(user_opts)
		M.actions = vim.tbl_deep_extend("force", M.actions, integration)
	elseif user_opts.integrations.telescope then
		local integration = require("workwork.integrations.telescope")
		M.actions = vim.tbl_deep_extend("force", M.actions, integration)
	end
end

return M
