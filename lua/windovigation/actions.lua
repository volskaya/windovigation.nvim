local globals = require("windovigation.globals")
local options = require("windovigation.options")
local history = require("windovigation.history")
local layout = require("windovigation.layout")
local utils = require("windovigation.utils")

local M = {}

---@param key_options? WindovigationKeyOptions
---@return boolean
local function is_user_move_action_allowed(key_options)
	local buf = key_options and key_options.buf or vim.api.nvim_get_current_buf()
	local buftype = vim.bo[buf].buftype
	if options.prevent_switching_nofile and buftype == "nofile" then
		return false
	end
	return true
end

---Closes the active file and destroys its buffer,
---if no other window has this file open.
M.close_current_file = function()
	local key, win, tab = history.get_current_key()
	local buf = vim.api.nvim_get_current_buf()
	local buftype = vim.bo[buf].buftype
	local file = globals.buffer_file_ids[buf]
	local entry = globals.state[key]
	local key_options = { buf = buf, win = win, tab = tab } ---@type WindovigationKeyOptions

	-- TODO: Ask to save changes before killing the buffer.

	-- Move to the next available file, before cleaning up.
	--
	-- Skip this for nofile buffers, since they usually have their own
	-- behavior for when :bdelete happens. Keep an eye on this though for weird behavior.
	if buftype ~= "nofile" then
		for _, delta in ipairs({ "previous", 1, -1 }) do
			if M.move_to_file(delta, key_options) then
				break -- Did move.
			end
		end
	end

	-- This action can be used on buffers we don't manage with our file histories.
	if file == nil or buftype == "nofile" then
		if not pcall(vim.cmd.bdelete, { buf, bang = false }) then
			-- Make sure we're back on buf, if bdelete didn't close any buffers.
			vim.api.nvim_win_set_buf(win, buf)
		end
		return
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

---@param key_options? WindovigationKeyOptions
---@return boolean
M.move_to_last_file = function(key_options)
	return is_user_move_action_allowed(key_options) and M.move_to_file("last", key_options) or false
end

---@param key_options? WindovigationKeyOptions
---@return boolean
M.move_to_first_file = function(key_options)
	return is_user_move_action_allowed(key_options) and M.move_to_file("first", key_options) or false
end

---@param key_options? WindovigationKeyOptions
---@return boolean
M.move_to_previous_file = function(key_options)
	return is_user_move_action_allowed(key_options) and M.move_to_file(-1, key_options) or false
end

---@param key_options? WindovigationKeyOptions
---@return boolean
M.move_to_next_file = function(key_options)
	return is_user_move_action_allowed(key_options) and M.move_to_file(1, key_options) or false
end

---Moves to the next file in the active history.
---
---Unlike the other "move_" actions, this call intentionally
---ignores is_user_move_action_allowed.
---
---@param delta integer | "first" | "last" | "previous"
---@param key_options? WindovigationKeyOptions
---@return boolean
M.move_to_file = function(delta, key_options)
	local key = history.get_current_key(key_options)
	local buf = key_options and key_options.buf or vim.api.nvim_get_current_buf()
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
	vim.g.WindovigationState = vim.json.encode(globals.state)
end

return M
