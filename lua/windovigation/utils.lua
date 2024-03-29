-- local globals = require("windovigation.globals")
-- local history = require("windovigation.history")

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
	local allow_relative_path = options and options.allow_relative_path or true
	local buftype = event.buf and vim.bo[event.buf].buftype or nil

	if not allow_relative_path and event.file ~= nil and event.file:len() > 0 then
		if event.file:sub(1, 1) ~= "/" then
			return false
		end
	end

	return event.buf ~= nil and buftype ~= "nofile" and event.file ~= nil and event.file:len() > 0
end


---@return integer?
M.find_buf_by_name = function(name)
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_name(buf) == name then
			return buf
		end
	end
	return nil
end

---@param buf integer
---@return string
M.buf_get_name_or_empty = function(buf)
	-- Not sure if this can throw, just being careful here in case a buffer has no name.
	local did_succeed, name = pcall(vim.api.nvim_buf_get_name, buf)
	if did_succeed then
		return name or ""
	end
	return ""
end

---@param path string
---@return string
M.absolute_path = function(path)
	local resolved = vim.fn.resolve(path)
	return vim.fn.expand(resolved)
end

---@generic T
---@param list table<T>
---@param value T
---@return integer?
M.index_of = function(list, value)
	local index = vim.fn.index(list, value)
	return index >= 0 and index + 1 or nil
end

---@generic T
---@param list table<T>
---@param value T
---@return table<T>
M.append_skipping_existing = function(list, value)
	local newList = {}
	---@diagnostic disable-next-line: no-unknown
	for _, v in ipairs(list) do
		if v ~= value then
			table.insert(newList, v)
		end
	end
	table.insert(newList, value)
	return newList
end

return M
