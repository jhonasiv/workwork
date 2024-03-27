if not pcall(require, "telescope") then
	error("nvim-telescope/telescope.nvim must be loaded to use this integration")
end

if not pcall(require, "plenary") then
	error("nvim-lua/plenary must be loaded to use this integration")
end

local config = require("telescope.config").values
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewer = require("telescope.previewers")
local make_entry = require("telescope.make_entry")

local core = require("workwork.core")

local Job = require("plenary.job")

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

M.git_files = function(opts)
	opts = opts or {}

	local folders = core._list_folders()
	local jobs_and_folders = {}
	for _, folder in ipairs(folders) do
		local job = Job:new({
			command = "git",
			args = { "--git-dir=" .. folder .. "/.git", "ls-files" },
			cwd = "/usr/bin",
		})
		vim.list_extend(jobs_and_folders, { { job = job, folder = folder } })
		job:sync()
	end

	local results = {}
	for _, info in ipairs(jobs_and_folders) do
		local job_results = info.job:result()
		for _, result in ipairs(job_results) do
			table.insert(results, info.folder .. "/" .. result)
		end
	end

	pickers
		.new(opts, {
			prompt_title = "Git Files in the Workspace:",
			finder = finders.new_table({
				results = results,
				entry_maker = make_entry.gen_from_file({}),
			}),
			previewer = config.file_previewer(opts),
			sorter = config.file_sorter(opts),
		})
		:find()
end

return M
