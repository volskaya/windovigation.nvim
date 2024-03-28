local actions = require("windovigation.actions")
local default_options = require("windovigation.options")
local handlers = require("windovigation.handlers")

local M = {}
local group = vim.api.nvim_create_augroup("Windovigation", { clear = true })

---@param options WindovigationOptions
local function create_user_commands(options)
	local user_commands = {
		WindovigationPreviousFile = function()
			actions.move_to_file(-1)
		end,
		WindovigationNextFile = function()
			actions.move_to_file(1)
		end,
		WindovigationFirstFile = function()
			actions.move_to_first_file()
		end,
		WindovigationLastFile = function()
			actions.move_to_last_file()
		end,
		WindovigationCloseFile = function()
			actions.close_current_file()
		end,
	}

	for command, fn in pairs(user_commands) do
		vim.api.nvim_create_user_command(command, fn, {})
	end
end

---@param options WindovigationOptions
local function create_auto_commands(options)
	local auto_commands = {
		SessionLoadPost = options.auto_restore_state and function()
			actions.restore_state()
		end or nil,
		VimLeavePre = options.auto_persist_state and function()
			actions.persist_state()
		end or nil,
		WinEnter = function(event)
			handlers.handle_file_entered(event)
		end,
		WinClosed = function(event)
			handlers.handle_win_closed(event, { win = tonumber(event.match) or -1 })
		end,
		WinNew = function(event)
			handlers.handle_win_new(event)
		end,
		TabNew = function(event)
			handlers.handle_tab_new(event, vim.api.nvim_get_current_tabpage())
		end,
		TabClosed = function(event)
			handlers.handle_tab_closed(event, { tab = tonumber(event.match) or -1 })
		end,
		BufCreate = function(event)
			handlers.handle_buf_created({ buf = event.buf, file = event.match })
		end,
		BufWritePost = function(event)
			handlers.handle_file_written({ buf = event.buf, file = event.match })
		end,
		BufEnter = function(event)
			handlers.handle_file_entered({
				buf = event.buf,
				tab = vim.api.nvim_get_current_tabpage(),
				file = event.file,
			})
		end,
		TermOpen = function(event)
			handlers.handle_file_entered({
				buf = event.buf,
				tab = vim.api.nvim_get_current_tabpage(),
				file = event.file,
			})
		end,
		TermEnter = function(event)
			handlers.handle_file_entered({
				buf = event.buf,
				tab = vim.api.nvim_get_current_tabpage(),
				file = event.file,
			})
		end,
	}

	for command, fn in pairs(auto_commands) do
		if fn ~= nil then
			local didSucceed = pcall(vim.api.nvim_create_autocmd, { command }, { group = group, callback = fn })
			if not didSucceed then
				vim.notify(
					string.format("Windovigation failed to create a handler for %s.", command),
					vim.log.levels.WARN
				)
			end
		end
	end
end

---@param options WindovigationOptions
---@return boolean
local function is_options_valid(options)
	local isValid = pcall(vim.validate, {
		auto_persist_state = { options.auto_persist_state, "boolean" },
		auto_restore_state = { options.auto_restore_state, "boolean" },
		keymaps = {
			options.keymaps,
			function(value)
				if value == nil then
					return true
				end

				vim.validate({
					bracket_movement_key = { value.bracket_movement_key, "string" },
					buffer_close_key = { value.buffer_close_key, "string" },
				})

				return true
			end,
			"WindowvigationKeymapOptions",
		},
	})

	return isValid
end

---@param options? WindovigationOptions
M.setup = function(options)
	local effective_options = vim.tbl_deep_extend("force", default_options, options or {})
	local is_effective_options_valid = is_options_valid(effective_options)

	-- Update our options with the user options, if they're valid.
	if is_effective_options_valid then
		for key, value in pairs(effective_options) do
			default_options[key] = value
		end
	else
		vim.notify("Windovigation user options failed validation, proceeding with defaults.", vim.log.levels.WARN)
	end

	create_user_commands(effective_options)
	create_auto_commands(effective_options)
end

return M
