local Path = require("plenary.path")
local uv = require("luv")

local core = require("workwork.core")

local M = {}

M.select = function()
	vim.ui.select(core.list_workspaces(), { prompt = "Select workspace: " }, function(choice)
		core._select_workspace(choice)
	end)
end

M.no_integration_select = M.select

M.create = function()
	vim.ui.input({ prompt = "Name your new workspace: " }, function(ws)
		if ws == nil then
			return
		end
		vim.ui.input(
			{ prompt = "Add a directory to your workspace: ", default = uv.cwd(), completion = "file" },
			function(folder)
				core._create(folder, ws)
			end
		)
	end)
end

M.delete = function()
	vim.ui.select(core.list_workspaces(), { prompt = "Name the workspace you want to delete: " }, function(ws)
		if ws == nil then
			return
		end
		core._delete(ws)
	end)
end

M.list = function()
	print(vim.inspect(core._list_workspaces()))
end

M.add_folder = function(ws)
	ws = ws or core._currently_selected()
	vim.ui.input({ prompt = "Add folder to workspace: ", default = uv.cwd(), completion = "file" }, function(folder)
		if folder == nil then
			return
		end

		local folder_path = Path:new(folder)
		local abs_folder_path = folder_path:absolute()
		core._add_folder_to_workspace(abs_folder_path, ws)
	end)
end

M.remove_folder = function(ws)
	ws = ws or core._currently_selected()
	vim.ui.select(core.list_workspaces(), { prompt = "Folder to remove: " }, function(folder)
		if folder == nil then
			return
		end
		core._remove_folder(folder, ws)
	end)
end

return M
