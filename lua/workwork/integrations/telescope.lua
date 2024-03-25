if not pcall(require, "telescope") then
	error("nvim-telescope/telescope.nvim must be loaded to use this integration")
end

local config = require("telescope.config").values
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewer = require("telescope.previewers")
local core = require("workwork.core")

_WorkWorkOpts = _WorkWorkOpts or {}

local workspace_previewer = previewer.new_buffer_previewer({
	define_preview = function(self, entry, _)
		local folders = core._list_folders(entry[1])
		vim.api.nvim_buf_set_lines(self.state.bufnr, 0, #folders, false, folders)
	end,
})

M = {}

M.select = function(opts)
	opts = opts or {}
	pickers
		.new(opts, {
			prompt_title = "Select the active workspace:",
			finder = finders.new_dynamic({
				fn = function()
					return core._list_workspaces()
				end,
			}),
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					core._select(selection[1])
				end)
				return true
			end,
			previewer = workspace_previewer,
			sorter = config.generic_sorter(opts),
		})
		:find()
end

M.workspace_files = function(opts)
	opts = opts or {}
	local folders = core._list_folders()
	local folders_str = table.concat(folders, " ")
	local cmd
	if vim.fn.executable("fdfind") then
		cmd = { "fdfind", ".", folders_str, _WorkWorkOpts.integrations.telescope.fd_opts }
	elseif vim.fn.executable("fd") then
		cmd = { "fd", ".", folders_str, _WorkWorkOpts.integrations.telescope.fd_opts }
	else
		cmd = { "find", folders_str, _WorkWorkOpts.integrations.telescope.find_opts }
	end

	cmd = vim.tbl_flatten(cmd)

	pickers
		.new(opts, {
			prompt_title = "Workspace Files:",
			finder = finders.new_oneshot_job(cmd),
			previewer = config.file_previewer(opts),
			sorter = config.file_sorter(opts),
		})
		:find()
end

return M
