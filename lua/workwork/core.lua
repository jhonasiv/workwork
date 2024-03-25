local M = {}

_WorkWorkWorkspaces = _WorkWorkWorkspaces or {}

M._add_folder_to_workspace = function(root_path, ws)
	ws = ws or M._currently_selected()
	if _WorkWorkWorkspaces[ws] == nil then
		error("No workspace named " .. ws)
	end
	table.insert(_WorkWorkWorkspaces[ws], root_path)

	M._save()
end

M._create = function(root_path, ws)
	local opts = _WorkWorkOpts or {}

	if _WorkWorkWorkspaces[ws] ~= nil then
		error("An workspace named " .. ws .. " already exists")
	end

	_WorkWorkWorkspaces[ws] = { root_path }

	if opts.autoselect_on_create then
		M.current_workspace = ws
	end

	if opts.autosave == true or opts.autosave.on_create then
		M.save()
	end
end

M._delete = function(ws)
	_WorkWorkWorkspaces[ws] = nil
end

M._select = function(ws)
	if _WorkWorkWorkspaces[ws] == nil then
		error("There is no workspace named " .. ws)
	end

	M.current_workspace = ws
end

M._currently_selected = function()
	if M.current_workspace == nil then
		error("No workspace currently selected.")
	end

	return M.current_workspace
end

M._list_workspaces = function()
	return vim.tbl_keys(_WorkWorkWorkspaces) or {}
end

M._list_folders = function(ws)
	ws = ws or M._currently_selected()
	return vim.tbl_values(_WorkWorkWorkspaces[ws] or {})
end

M._remove_folder = function(root_path, ws)
	ws = ws or M._currently_selected()

	local folders = _WorkWorkWorkspaces[ws]

	for index, value in ipairs(_WorkWorkWorkspaces[ws]) do
		if value == root_path then
			table.remove(folders, index)
		end
	end
	_WorkWorkWorkspaces[ws] = folders
end

M.save = function()
	local opts = _WorkWorkOpts or {}

	if vim.tbl_isempty(_WorkWorkWorkspaces) then
		print("No workspace registered...Aborting save.")
		return
	end

	local json_data = vim.fn.json_encode({ workspaces = _WorkWorkWorkspaces, selected = M.current_workspace })
	local file = io.open(opts.state_file, "w+")
	if file then
		file:write(json_data)
		file:close()
		return
	end

	error("Could not save workspace since the storage file cannot be opened at " .. opts.state_file)
end

M.load = function()
	local opts = _WorkWorkOpts or {}

	local file = io.open(opts.state_file, "r")
	if file then
		local json_data = file:read("*a")
		local workwork_data = vim.fn.json_decode(json_data) or {}
		_WorkWorkWorkspaces = workwork_data.workspaces or {}
		if opts.autoload_selected == "last" then
			M.current_workspace = workwork_data.selected or nil
		end
		file:close()
		return
	end

	error("Could not load workspace because workwork state file cannot be opened at " .. opts.state_file)
end

return M
