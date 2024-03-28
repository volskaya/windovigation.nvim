local globals = require("windovigation.globals")
local history = require("windovigation.history")
local layout = require("windovigation.layout")
local utils = require("windovigation.utils")
local keymaps = require("windovigation.keymaps")

local M = {}

---@param event WindovigationEvent
M.handle_file_picked = function(event)
	if not utils.is_event_relevant(event) then
		return
	end

	-- INFO: Should we have some special handling here for relative paths a picker might pass in?
	local file = event.file
	local key = history.get_current_key()

	history.move_to_front(file, key)
end

---@param event WindovigationEvent
M.handle_file_entered = function(event)
	-- HACK: Always set our keymaps when entering a buffer,
	--  because lazy loaded packages keep overwriting us.
	pcall(keymaps.set_default_keymaps, event.buf)

	if not utils.is_event_relevant(event) then
		return
	end

	local file = event.file
	local key, win, tab, pane, page = history.get_current_key()

	layout.handle_layout_change()

	-- Always keep the buffer id up to date.
	globals.file_buffer_ids[file] = event.buf
	globals.buffer_file_ids[event.buf] = file

	-- Handle the no_scope_filter before scoping the file.
	--
	---@param value string
	for _, value in ipairs(globals.hidden_options.no_scope_filter_patterns or {}) do
		if string.match(file, value) ~= nil then
			return
		end
	end

	local entry = globals.state[key]
	local entry_histories = entry.histories or { entered = {}, written = {} }

	if not history.is_file_scoped(file, key) then
		table.insert(entry_histories.entered, file)
		table.insert(entry_histories.written, file)

		globals.state[key] = {
			tab = tab,
			page = page,
			win = win,
			pane = pane,
			histories = entry_histories,
		}
	elseif file ~= entry_histories.entered[#entry_histories.entered] then
		-- If the file is already scoped, only bump it in the "entered" history.
		globals.state[key] = {
			tab = tab,
			page = page,
			win = win,
			pane = pane,
			histories = {
				entered = utils.append_skipping_existing(entry_histories.entered, file),
				written = entry_histories.written,
			},
		}
	end
end

---@param event WindovigationEvent
---@param options? WindovigationKeyOptions
M.handle_file_written = function(event, options)
	if not utils.is_event_relevant(event) then
		return
	end

	local file = event.file
	local key = history.get_current_key(options)

	if history.is_file_scoped(file, key) then
		history.move_to_front(file, key)
	end
end

---@param event WindovigationEvent
---@param tab integer
M.handle_tab_new = function(event, tab)
	local key = history.get_current_key({ tab = tab })

	-- For some reason the previous buffer registers in the new tab,
	-- and pushes its file to this state entry.
	globals.state[key] = nil
	layout.handle_layout_change()
end

---@param event WindovigationEvent
---@param options? WindovigationKeyOptions
M.handle_tab_closed = function(event, options)
	local tab = (options ~= nil and options.tab ~= nil) and options.tab or nil
	if tab == nil then
		return -- Event wasn't passed the relevant options.
	end

	layout.handle_layout_change()
end

---@param event? WindovigationEvent
---@param options? WindovigationKeyOptions
M.handle_win_new = function(event, options)
	layout.handle_layout_change()
end

---@param event? WindovigationEvent
---@param options? WindovigationKeyOptions
M.handle_win_closed = function(event, options)
	layout.handle_layout_change()
end

---@param event WindovigationEvent
M.handle_buf_created = function(event)
	if not utils.is_event_relevant(event) then
		return
	end

	local buf = event.buf
	local file = event.file

	globals.file_buffer_ids[file] = buf
	globals.buffer_file_ids[buf] = file
end

---@param event WindovigationEvent
M.handle_buf_delete = function(event)
	if not utils.is_event_relevant(event) then
		return
	end

	local buf = event.buf
	local file = event.file

	if globals.file_buffer_ids[file] == buf then
		globals.file_buffer_ids[file] = nil
		globals.buffer_file_ids[buf] = nil
	end

	-- Remove the file from all entries - its buffer is deleted.
	for key, entry in pairs(globals.state) do
		local written_new, did_remove = utils.remove_from_table(entry.histories.written, file)

		if did_remove then
			globals.state[key] = {
				tab = entry.tab,
				page = entry.page,
				win = entry.win,
				pane = entry.pane,
				histories = {
					entered = utils.remove_from_table(entry.histories.entered, file),
					written = written_new,
				},
			}
		end
	end
end

return M
