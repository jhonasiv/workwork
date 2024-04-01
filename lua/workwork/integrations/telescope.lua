if not pcall(require, "telescope") then
	error("nvim-telescope/telescope.nvim must be loaded to use this integration")
end

local default_mappings = require("telescope").mappings
local config = require("telescope.config").values
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewer = require("telescope.previewers")
local make_entry = require("telescope.make_entry")
local log = require("telescope.log")

local core = require("workwork.core")
local wkwk_actions = require("workwork.actions")
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
	opts.initial_mode = opts.initial_mode or "normal"
	pickers
		.new(opts, {
			prompt_title = "Select the active workspace:",
			finder = finders.new_dynamic({
				fn = core._list_workspaces,
			}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					core._select(selection[1])
				end)
				map("n", "o", function(bufnr)
					wkwk_actions.create()
					local picker = action_state.get_current_picker(bufnr)
					picker:refresh(picker.finder, { reset_prompt = true })
				end, { desc = "create_workspace" })
				map("n", "a", function(bufnr)
					local entry = action_state.get_selected_entry()
					wkwk_actions.add_folder(entry[1])
					local picker = action_state.get_current_picker(bufnr)
					picker:refresh(finders.new_dynamic({ fn = core._list_workspaces }), { reset_prompt = true })
				end, { desc = "add_folder_to_workspace" })
				map("n", "r", function(bufnr)
					local entry = action_state.get_selected_entry()
					wkwk_actions.rename(entry[1])
					local picker = action_state.get_current_picker(bufnr)
					picker:refresh(finders.new_dynamic({ fn = core._list_workspaces }), { reset_prompt = true })
				end, { desc = "rename_workspace" })
				return true
			end,
			previewer = workspace_previewer,
			sorter = config.generic_sorter(opts),
		})
		:find()
end

M.delete = function(opts)
	opts = opts or {}
	pickers
		.new({ initial_mode = opts.initial_mode or "normal" }, {
			prompt_title = "Choose which workspaces to delete:",
			finder = finders.new_dynamic({
				fn = core._list_workspaces,
			}),
			previewer = workspace_previewer,
			sorter = config.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					core._delete(selection[1])
				end)
				return true
			end,
		})
		:find()
end

M.remove_folder = function(opts)
	opts = opts or {}
	opts.initial_mode = opts.initial_mode or "normal"
	pickers
		.new(opts, {
			prompt_title = "Choose from which workspace to remove a folder:",
			finder = finders.new_dynamic({
				fn = core._list_workspaces,
			}),
			previewer = workspace_previewer,
			sorter = config.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					local ws = selection[1]
					if not core._possible_to_remove_folder(ws) then
						log.warn(
							"Warning: "
								.. ws
								.. " workspace has a single folder. Removing it would delete the workspace."
								.. " If you want to delete it, do it instead of removing the folder."
						)
						return
					end
					pickers
						.new(opts, {
							prompt_title = "Choose which folder to remove from workspace:",
							finder = finders.new_dynamic({
								fn = function()
									return core._list_folders(ws)
								end,
							}),
							sorter = config.generic_sorter(opts),
							attach_mappings = function(bufnr, _)
								actions.select_default:replace(function()
									actions.close(bufnr)
									local folder_selection = action_state.get_selected_entry()[1]
									core._remove_folder(folder_selection, ws)
								end)
								return true
							end,
						})
						:find()
				end)
				return true
			end,
		})
		:find()
	--
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
		local target_folder = Path:new(folder):find_upwards(".git").filename

		local job = Job:new({
			command = "grep",
			args = { folder_name },
			writer = Job:new({
				command = "git",
				args = { "--git-dir=" .. target_folder, "ls-files" },
				cwd = "/usr/bin",
			}),
		})
		job_metadata[job] = Path:new(target_folder):parent().filename
		job:start()
	end

	local results = {}
	local mapped_entries = {}
	for job, folder in pairs(job_metadata) do
		if vim.wait(1000, function()
			return job.is_shutdown
		end, 10) then
			local job_results = job:result()

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
