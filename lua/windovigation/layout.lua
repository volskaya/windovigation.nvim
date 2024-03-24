local globals = require("windovigation.globals")
local utils = require("windovigation.utils")

local M = {}

---@param options WindovigationLayoutChangeOptions?
M.handle_layout_change = function(options)
	local is_restoring_state = options and options.is_restoring_state == true or false
	local wins = vim.api.nvim_list_wins()

	local state_before = globals.state
	local state_after = {} ---@type WindovigationState
	local window_panes_before = {} ---@type table<integer, integer>
	local tab_pages_before = {} ---@type table<integer, integer>

	-- Any history that remains in this table will be dropped at the end of this call.
	local histories_before = {} ---@type table<WindovigationKey, WindovigationHistory>

	for _, entry in pairs(state_before) do
		local key = entry.page .. "_" .. entry.pane

		window_panes_before[entry.win] = entry.pane
		tab_pages_before[entry.tab] = entry.page
		histories_before[key] = entry.history
	end

	for _, win in ipairs(wins) do
		local tab = vim.api.nvim_win_get_tabpage(win)
		local page = vim.api.nvim_tabpage_get_number(tab)
		local pane = vim.api.nvim_win_get_number(win)
		local key = page .. "_" .. pane
		local history = {} ---@type WindovigationHistory
		local key_old = nil ---@type WindovigationKey?

		if not is_restoring_state then
			-- When not restoring state, get old state with window / tab ids.
			local pane_old = window_panes_before[win]
			local page_old = tab_pages_before[tab]

			if page_old ~= nil and pane_old ~= nil then
				key_old = page_old .. "_" .. pane_old
			end
		else
			-- State restored, assume panes and pages match their old positions.
			key_old = key
		end

		if key_old ~= nil then
			local entry_old = state_before[key_old] or nil ---@type WindovigationEntry?

			-- Reusing old history if possible and removing it from
			-- histories_before, so it doesn't get dropped.
			if entry_old ~= nil and histories_before[key_old] ~= nil then
				history = histories_before[key_old]
				histories_before[key_old] = nil
			end
		end

		--- @type WindovigationEntry
		state_after[key] = {
			tab = tab,
			page = page,
			win = win,
			pane = pane,
			history = history,
		}
	end

	globals.state = state_after

	local files_dropped = {} ---@type table<string,boolean>
	for _, history in pairs(histories_before) do
		---@param file string
		for _, file in ipairs(history) do
			if files_dropped[file] ~= true then
				local did_close = utils.maybe_close_buffer_for_file(file)
				if did_close then
					files_dropped[file] = true
				end
			end
		end
	end
end

return M
