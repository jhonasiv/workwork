local integration = require("workwork.integrations.telescope")

return require("telescope").register_extension({
	setup = function(_, user_opts)
		require("workwork").setup(user_opts)
	end,
	exports = {
		select = integration.select,
		workspace_files = integration.workspace_files,
	},
})
