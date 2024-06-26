local integration = require("workwork.integrations.telescope")

return require("telescope").register_extension({
	setup = function(extension_opts, _)
		local opts = { integrations = { telescope = { opts = extension_opts } } }
		require("workwork").setup(opts)
	end,
	exports = {
		select = integration.select,
		files = integration.files,
		git_files = integration.git_files,
		delete = integration.delete,
		remove_folder = integration.remove_folder,
	},
})
