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
	local entry = globals.state[key]
	local options = { buf = buf, win = win, tab = tab } ---@type WindovigationKeyOptions

	if file == nil then
		pcall(vim.api.nvim_buf_delete, buf, { force = false })
		return -- There's nothing to close.
	end

	-- Move to the next available file, before cleaning up.
	-- local did_move = M.move_to_file(1, options)
	-- if not did_move then
	-- 	M.move_to_file(-1, options)
	-- end

	for _, delta in ipairs({ "previous", 1, -1 }) do
		local didMove = M.move_to_file(delta, options)
		if didMove then
			break
		end
	end

	if entry ~= nil then
		local histories = entry.histories
		local histories_after = {
			entered = utils.remove_from_table(histories.entered, file),
			written = utils.remove_from_table(histories.written, file),
		}

		globals.state[key] = {
			tab = entry.tab,
			page = entry.page,
			win = entry.win,
			pane = entry.pane,
			histories = histories_after,
		}

		-- Close the window as there are no more files in this history.
		if #histories_after.written == 0 and file ~= nil then
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

---@param delta integer | "first" | "last" | "previous"
---@param options? WindovigationKeyOptions
---@return boolean
M.move_to_file = function(delta, options)
	local key = history.get_current_key(options)
	local buf = options and options.buf or vim.api.nvim_get_current_buf()
	local buf_type = vim.bo[buf].buftype
	local entry = globals.state[key]

	-- Key has no state, there's nothing to move through.
	if entry == nil then
		return false
	end

	local file = globals.buffer_file_ids[buf]
	local file_before = file
	local entry_histories = entry and entry.histories or { written = {}, entered = {} }
	local index = nil

	-- Try to find the previous file index in the history.
	if file ~= nil then
		index = utils.index_of(entry_histories.written, file)
	end

	local try_previous_first = false
	local did_find_previous_index = false

	-- Buffers of "nofile" aren't meant to be in the history, so it doesn't make
	-- sense to use them as the middle file for backward / forward switch.
	if buf_type == "nofile" then
		try_previous_first = true
	end

	-- Recalculate the next index.
	if delta == "previous" or try_previous_first then
		-- Iterate in reverse and find the last entered file we can switch to.
		for i = #entry.histories.entered, 1, -1 do
			local entered_file = entry.histories.entered[i] ---@type string?
			if entered_file ~= nil and entered_file ~= file then
				-- Find the file in the written history. If it doesn't exist there, don't switch to it.
				index = utils.index_of(entry_histories.written, entered_file)
				did_find_previous_index = true
				break
			end
		end
	end

	if not did_find_previous_index then
		if delta == "previous" then
		-- The "previous" handling above didn't find anything, have this pass through to other cases.
		elseif delta == "first" then
			index = 1
		elseif delta == "last" then
			index = #entry_histories.written
		elseif index == nil then
			index = delta <= 0 and #entry_histories.written or 1
		else
			index = index + delta
		end
	end

	-- After recalculating the next index, we should have the next file.
	file = entry_histories.written[index] ---@type string?

	if file ~= nil and file ~= file_before then
		local buffer = globals.file_buffer_ids[file]
		-- TODO: If our cache returns nil, iterate over all buffers and try to match one by their current file name.

		if buffer ~= nil then
			vim.api.nvim_set_current_buf(buffer)
		else
			-- Fallback to :edit.
			--
			-- This won't be enough to switch to a file in a special buffer
			-- and will open an empty file, but this way the user isn't
			-- blocked from switching due to an unaccounted buffer id.
			vim.cmd("edit " .. file)
		end
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
	local state_clean = {} ---@type WindovigationState
	local filter_term = function(v)
		return not vim.startswith(v, "term://")
	end

	for key, entry in pairs(globals.state) do
		local histories_clean = {
			-- Remove term:// files from history - nvim doesn't restore terminals.
			entered = vim.tbl_filter(filter_term, entry.histories.entered),
			written = vim.tbl_filter(filter_term, entry.histories.written),
		} ---@type WindovigationHistory

		state_clean[key] = {
			tab = entry.tab,
			page = entry.page,
			win = entry.win,
			pane = entry.pane,
			histories = histories_clean,
		} ---@type WindovigationEntry
	end

	vim.g.WindovigationState = vim.json.encode(state_clean)
end

return M
