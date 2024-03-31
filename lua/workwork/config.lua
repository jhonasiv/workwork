local M = {}

M.default = {
	state_file = vim.fn.stdpath("state") .. "/workwork.json",
	autoload_selected = "last",
	autoselect_on_create = true,
	integrations = {
		telescope = {
			enable = false,
			opts = {
				find_opts = { "-type", "f", "-not", "-path", "'*/\\.git/*'", "-printf", "'%P\n'" },
				fd_opts = { "--color=never", "--type", "f", "--hidden", "--follow", "--exclude", ".git" },
				relative_path_entries = false,
			},
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
