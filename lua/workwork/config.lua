local M = {}

M.default = {
	state_file = vim.fn.stdpath("state") .. "/workwork.json",
	autoselect_on_create = true,
	autoload_selected_workspace = true,
	autosave = {
		on_create = false,
		on_new_folder = false,
	},
	integrations = {
		telescope = {
			enable = false,
			find_opts = { "-type", "f", "-not", "-path", "'*/\\.git/*'", "-printf", "'%P\n'" },
			fd_opts = { "--color=never", "--type", "f", "--hidden", "--follow" },
		},
		fzf_lua = {
			enable = false,
			find_opts = [["-type f -not -path '*/\.git/*' -printf '%P\n'"]],
			fd_opts = "--color=never --type f --hidden --follow --exclude .git",
		},
	},
}

M.merge_config = function(user_opts)
	return vim.tbl_deep_extend("keep", user_opts, M.default)
end

return M
