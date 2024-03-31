if not pcall(require, "telescope") then
	error("nvim-telescope/telescope.nvim must be loaded to use this integration")
end

local config = require("telescope.config").values
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewer = require("telescope.previewers")
local make_entry = require("telescope.make_entry")

local core = require("workwork.core")
local utils = require("workwork.utils")

local Job = require("plenary.job")
local Path = require("plenary.path")

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

M.files = function(opts)
	opts = opts or {}
	local folders = core._list_folders()
	local cmd
	if vim.fn.executable("fdfind") then
		cmd = { "fdfind", ".", folders, _WorkWorkOpts.integrations.telescope.opts.fd_opts }
	elseif vim.fn.executable("fd") then
		cmd = { "fd", ".", folders, _WorkWorkOpts.integrations.telescope.opts.fd_opts }
	else
		cmd = { "find", folders, _WorkWorkOpts.integrations.telescope.opts.find_opts }
	end

	cmd = vim.tbl_flatten(cmd)

	pickers
		.new(opts, {
			prompt_title = "Workspace Files:",
			finder = finders.new_oneshot_job(cmd, {
				entry_maker = make_entry.gen_from_file({
					path_display = function(_, entry)
						if _WorkWorkOpts.integrations.telescope.opts.relative_path_entries then
							return utils.relative_path(entry, vim.fn.getcwd())
						end
						return entry
					end,
				}),
			}),
			previewer = config.file_previewer(opts),
			sorter = config.file_sorter(opts),
		})
		:find()
end

M.git_files = function(opts)
	opts = opts or {}

	local folders = core._list_folders()
	local job_metadata = {}
	for _, folder in ipairs(folders) do
		local folder_lst = vim.split(folder, "/")
		local folder_name = folder_lst[#folder_lst]
		local grep_by = ""
		local target_folder = folder .. "/.git"
		if _WorkWorkOpts.integrations.telescope.opts.support_nongit_folders then
			target_folder = Path:new(folder):find_upwards(".git").filename
			grep_by = folder_name
		end

		local job = Job:new({
			command = "grep",
			args = { grep_by },
			writer = Job:new({
				command = "git",
				args = { "--git-dir=" .. target_folder, "ls-files" },
				cwd = "/usr/bin",
			}),
		})
		vim.list_extend(job_metadata, { { job = job, folder = Path:new(target_folder):parent().filename } })
		job:start()
	end

	local results = {}
	local mapped_entries = {}
	for _, info in ipairs(job_metadata) do
		if vim.wait(1000, function()
			return info.job.is_shutdown
		end, 10) then
			local job_results = info.job:result()
			local folder = info.folder

			for _, result in ipairs(job_results) do
				local entry = folder .. "/" .. result
				table.insert(results, entry)
				mapped_entries[entry] = folder
			end
		end
	end

	pickers
		.new(opts, {
			prompt_title = "Git Files in the Workspace:",
			finder = finders.new_table({
				results = results,
				entry_maker = make_entry.gen_from_file({
					path_display = function(_, entry)
						return utils.relative_path(entry, mapped_entries[entry])
					end,
				}),
			}),
			previewer = config.file_previewer(opts),
			sorter = config.file_sorter(opts),
		})
		:find()
end

return M
