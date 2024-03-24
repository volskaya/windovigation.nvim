local M = {}

---Extends default file-picker select action to also bump
---the picked file to the front of window file history.
M.our_action_select = function(prompt_bufnr, type)
	local action_state = require("telescope.actions.state")
	local action_set = require("telescope.actions.set")
	local command = action_state.select_key_to_edit_key(type)
	local entry = action_state.get_selected_entry()

	if not entry then
		return
	end

	-- Perform the default call before performing post operations.
	local default = action_set.edit(prompt_bufnr, command)

	if entry.path or entry.filename then
		local filename = entry.path or entry.filename

		if command == "edit" or command == "new" or command == "vnew" or command("tabedit") then
			-- When selecting a file, we bump our file history.
			require("windovigation.handlers").handle_file_picked({
				buf = vim.api.nvim_get_current_buf(),
				file = filename,
			})
		end
	end

	return default
end

--- Copied from https://github.com/nvim-telescope/telescope-file-browser.nvim/blob/master/lua/telescope/_extensions/file_browser/actions.lua
local function open_dir_path(finder, path, upward)
	local scan = require("plenary.scandir")
	local Path = require("plenary.path")
	local fb_utils = require("telescope._extensions.file_browser.utils")

	path = vim.loop.fs_realpath(path) or ""
	if path == "" then
		return
	end

	if not vim.loop.fs_access(path, "X") then
		fb_utils.notify("select", { level = "WARN", msg = "Permission denied" })
		return
	end

	if not finder.files or not finder.collapse_dirs then
		return path
	end

	while true do
		local dirs = scan.scan_dir(path, { add_dirs = true, depth = 1, hidden = true })
		if #dirs == 1 and vim.fn.isdirectory(dirs[1]) == 1 then
			path = upward and Path:new(path):parent():absolute() or dirs[1]
		else
			break
		end
	end
	return path
end

---Copied from https://github.com/nvim-telescope/telescope-file-browser.nvim/blob/master/lua/telescope/_extensions/file_browser/actions.lua
M.open_dir_or_file_action = function(prompt_bufnr, _, dir)
	local action_state = require("telescope.actions.state")
	local fb_utils = require("telescope._extensions.file_browser.utils")
	local Path = require("plenary.path")

	local current_picker = action_state.get_current_picker(prompt_bufnr)
	local finder = current_picker.finder
	local entry = action_state.get_selected_entry()

	local path = dir or entry.path
	local is_dir = Path:new(path):is_dir()
	local upward = path == Path:new(finder.path):parent():absolute()

	if is_dir then
		finder.files = true
		finder.path = open_dir_path(finder, path, upward)
		fb_utils.redraw_border_title(current_picker)
		current_picker:refresh(
			finder,
			{ new_prefix = fb_utils.relative_path_prefix(finder), reset_prompt = true, multi = current_picker._multi }
		)
	else
		M.our_action_select(prompt_bufnr, "default")
	end
end

return M
