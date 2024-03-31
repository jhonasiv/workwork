local M = {}

local Path = require("plenary.path")

M.relative_path = function(original_path, reference_path)
	-- Use plenary's make relative to clean paths
	original_path = Path:new(original_path):make_relative(".")
	reference_path = Path:new(reference_path):make_relative(".")
	local path = Path:new(original_path)
	local ref_path = Path:new(reference_path)
	local parents = path:parents()
	local ref_parents = ref_path:parents()

	local path_elements = vim.split(path.filename, "/")
	table.insert(parents, 1, original_path)
	table.insert(ref_parents, 1, reference_path)

	local result = ""
	for i, ref_parent in ipairs(ref_parents) do
		for j, par in ipairs(parents) do
			if ref_parent == par then
				if i == 1 and j == 1 then
					return ""
				end

				result = result .. table.concat(path_elements, "/", #path_elements - j + 2)
				return result
			end
		end

		result = "../" .. result
	end
end

return M
