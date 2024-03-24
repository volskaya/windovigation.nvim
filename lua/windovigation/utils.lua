local globals = require("windovigation.globals")
local history = require("windovigation.history")

local M = {}

---@generic T: any
---@param t table<T>
---@param value T
---@return table<T>
---@return boolean
M.remove_from_table = function(t, value)
	local newT = {}
	local didRemove = false

	---@param v any
	for _, v in ipairs(t) do
		if v ~= value then
			table.insert(newT, v)
		else
			didRemove = true
		end
	end
	return newT, didRemove
end

---@param inputstr string
---@param sep string
---@return table<string>
M.mysplit = function(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

---@param event WindovigationEvent
---@return boolean
---@param options? WindovigationEventRelevantOptions
M.is_event_relevant = function(event, options)
	local allow_relative_path = options and options.allow_relative_path or false

	if not allow_relative_path and event.file ~= nil and event.file:len() > 0 then
		if event.file:sub(1, 1) ~= "/" then
			vim.notify("Event file needs an absolute path. " .. event.file, vim.log.levels.WARN)
		end
	end

	return event.buf ~= nil and event.file ~= nil and event.file:len() > 0
end

---@param file string
---@return boolean
M.maybe_close_buffer_for_file = function(file)
	local didSucceed = false
	local buf = globals.file_buffer_ids[file]

	if buf == nil then
		return false
	end

	if not history.is_file_scoped(file) then
		didSucceed = pcall(vim.api.nvim_buf_delete, buf, { force = true })
	end

	return didSucceed
end

return M
