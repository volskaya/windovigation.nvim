local globals = require("windovigation.globals")
local history = require("windovigation.history")
local layout = require("windovigation.layout")
local utils = require("windovigation.utils")

local M = {}

---Closes the active file and destroys its buffer,
---if no other window has this file open.
M.close_current_file = function()
	local key, win, tab = history.get_current_key()
	local buf = vim.api.nvim_get_current_buf()
	local file = globals.buffer_file_ids[buf]
	local options = { buf = buf, win = win, tab = tab } ---@type WindovigationKeyOptions

	if file == nil then
		pcall(vim.api.nvim_buf_delete, buf, { force = false })
		return -- There's nothing to close.
	end

	-- Move to the next available file, before cleaning up.
	local did_move = M.move_to_file(-1, options)
	if not did_move then
		M.move_to_file(1, options)
	end

	if globals.state[key] ~= nil then
		local entry = globals.state[key]
		local entry_history = entry.history
		local history_after = utils.remove_from_table(entry_history, file)

		globals.state[key] = {
			history = history_after,
			tab = entry.tab,
			page = entry.page,
			win = entry.win,
			pane = entry.pane,
		}

		-- Close the window as there are no more files in this history.
		if #history_after == 0 and file ~= nil then
			pcall(vim.api.nvim_win_close, win, false) -- Closing last window will fail silently.
		end
	else
		-- Proceeding to close a file without state.
	end

	utils.maybe_close_buffer_for_file(file)
end

---@param options? WindovigationKeyOptions
---@return boolean
M.move_to_last_file = function(options)
	return M.move_to_file("last", options)
end

---@param options? WindovigationKeyOptions
---@return boolean
M.move_to_first_file = function(options)
	return M.move_to_file("first", options)
end

---@param options? WindovigationKeyOptions
---@return boolean
M.move_to_previous_file = function(options)
	return M.move_to_file(-1, options)
end

---@param options? WindovigationKeyOptions
---@return boolean
M.move_to_next_file = function(options)
	return M.move_to_file(1, options)
end

---@param delta integer | "first" | "last"
---@param options? WindovigationKeyOptions
---@return boolean
M.move_to_file = function(delta, options)
	local key = history.get_current_key(options)
	local buf = options and options.buf or vim.api.nvim_get_current_buf()
	local file = globals.buffer_file_ids[buf]
	local file_before = file

	local entry_history = globals.state[key] and globals.state[key].history or {}
	local index = nil

	-- Try to find file index in the history.
	if file ~= nil then
		---@param v string
		for i, v in ipairs(entry_history) do
			if v == file then
				index = i
			end
		end
	end

	-- File has no state, there's nothing to move to.
	if globals.state[key] == nil then
		return false
	end

	-- Recalculate the next index.
	if delta == "first" then
		index = 1
	elseif delta == "last" then
		index = #entry_history
	elseif index == nil then
		index = delta <= 0 and #entry_history or 1
	else
		index = index + delta
	end

	-- After recalculating the next index, we should have the next file.
	file = entry_history[index] ---@type string?

	if file ~= nil and file ~= file_before then
		vim.cmd("edit " .. file)
		return true
	end

	return false
end

M.restore_state = function()
	local stored_state = vim.g.WindovigationState
	if stored_state ~= nil then
		globals.state = vim.json.decode(stored_state) ---@type WindovigationState
		layout.handle_layout_change({ is_restoring_state = true })
	end
end

M.persist_state = function()
	vim.g.WindovigationState = vim.json.encode(globals.state)
end

return M
