local globals = require("windovigation.globals")

local M = {}

---@param options? WindovigationKeyOptions
---@return WindovigationKey
---@return integer
---@return integer
---@return integer
---@return integer
M.get_current_key = function(options)
	local win = options and options.win or vim.api.nvim_get_current_win()
	local tab = options and options.tab or vim.api.nvim_win_get_tabpage(win)
	local page = vim.api.nvim_tabpage_get_number(tab)
	local pane = vim.api.nvim_win_get_number(win)

	return page .. "_" .. pane, win, tab, pane, page
end

---@param file string
---@param history WindovigationHistory
---@return boolean
M.is_file_scoped_in_history = function(file, history)
	local is_absolute_path = file:sub(1) == "/"
	local file_length = file:len()

	---@param v string
	for _, v in ipairs(history) do
		local is_match = is_absolute_path and v == file or string.sub(v, -file_length, -1) == file
		if is_match then
			-- if v == file then
			return true
		end
	end
	return false
end

---@param file string
---@param key? WindovigationKey
---@return boolean
M.is_file_scoped = function(file, key)
	-- If there's no key, check if buf is scoped globally instead.
	if key == nil then
		for _, entry in pairs(globals.state) do
			if M.is_file_scoped_in_history(file, entry.histories.written) then
				return true
			end
		end
		return false
	end

	if globals.state[key] == nil then
		return false
	end

	return M.is_file_scoped_in_history(file, globals.state[key].histories.written)
end

---@param file string
---@param key WindovigationKey
M.move_to_front = function(file, key)
	local entry_old = globals.state[key]

	if entry_old == nil then
		vim.notify("Tried to front a file without state: " .. file, vim.log.levels.WARN)
		return -- Not scoped.
	end

	local histories_new = { entered = {}, written = {} } ---@type WindovigationHistory
	local is_absolute_path = file:sub(1) == "/"
	local file_length = file:len()
	local fronted_file_name = nil

	local history_last = entry_old.histories.written[#entry_old.histories.written] ---@type string?
	local file_matches_last = history_last ~= nil
			and (is_absolute_path and history_last == file or string.sub(history_last, -file_length, -1) == file)
		or false

	if file_matches_last then
		return -- No need to rebuild the table - file is already at the front.
	end

	---@param v string
	for _, v in ipairs(entry_old.histories.written) do
		local is_match = is_absolute_path and v == file or string.sub(v, -file_length, -1) == file

		if not is_match then
			table.insert(histories_new.written, v)
		elseif fronted_file_name == nil then
			fronted_file_name = v ---@type string
		end
	end

	if fronted_file_name ~= nil then
		table.insert(histories_new.written, fronted_file_name)
	end

	histories_new.entered = entry_old.histories.entered
	globals.state[key] = {
		tab = entry_old.tab,
		page = entry_old.page,
		win = entry_old.win,
		pane = entry_old.pane,
		histories = histories_new,
	}
end

return M
