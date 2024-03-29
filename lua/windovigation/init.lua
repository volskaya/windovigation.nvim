local actions = require("windovigation.actions")
local options = require("windovigation.options")
local globals = require("windovigation.globals")
local handlers = require("windovigation.handlers")
local utils = require("windovigation.utils")

local M = {}
local group = vim.api.nvim_create_augroup("Windovigation", { clear = true })

local function create_user_commands()
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

local function create_auto_commands()
	local auto_commands = {
		SessionLoadPost = options.auto_restore_state and function()
			actions.restore_state()
		end or nil,
		VimLeavePre = options.auto_persist_state and function()
			actions.persist_state()
		end or nil,
		WinEnter = function(event)
			handlers.handle_file_entered({ buf = event.buf, file = utils.buf_get_name_or_empty(event.buf) })
		end,
		WinClosed = function(event)
			handlers.handle_win_closed(
				{ buf = event.buf, file = utils.buf_get_name_or_empty(event.buf) },
				{ win = tonumber(event.match) or -1 }
			)
		end,
		WinNew = function(event)
			handlers.handle_win_new({ buf = event.buf, file = utils.buf_get_name_or_empty(event.buf) })
		end,
		TabNew = function(event)
			handlers.handle_tab_new({
				buf = event.buf,
				file = utils.buf_get_name_or_empty(event.buf),
			}, vim.api.nvim_get_current_tabpage())
		end,
		TabClosed = function(event)
			handlers.handle_tab_closed({
				buf = event.buf,
				file = utils.buf_get_name_or_empty(event.buf),
			}, {
				tab = tonumber(event.match) or -1,
			})
		end,
		BufCreate = function(event)
			handlers.handle_buf_created({ buf = event.buf, file = utils.buf_get_name_or_empty(event.buf) })
		end,
		BufWritePost = function(event)
			handlers.handle_file_written({ buf = event.buf, file = utils.buf_get_name_or_empty(event.buf) })
		end,
		BufEnter = function(event)
			handlers.handle_file_entered({
				buf = event.buf,
				tab = vim.api.nvim_get_current_tabpage(),
				file = utils.buf_get_name_or_empty(event.buf),
			})
		end,
		TermOpen = function(event)
			handlers.handle_file_entered({
				buf = event.buf,
				tab = vim.api.nvim_get_current_tabpage(),
				file = utils.buf_get_name_or_empty(event.buf),
			})
		end,
		TermEnter = function(event)
			handlers.handle_file_entered({
				buf = event.buf,
				tab = vim.api.nvim_get_current_tabpage(),
				file = utils.buf_get_name_or_empty(event.buf),
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

---@param user_options WindovigationOptions
---@return boolean
local function is_options_valid(user_options)
	local isValid = pcall(vim.validate, {
		auto_persist_state = { user_options.auto_persist_state, "boolean" },
		auto_restore_state = { user_options.auto_restore_state, "boolean" },
		prevent_switching_nofile = { user_options.prevent_switching_nofile, "boolean" },
		keymaps = {
			user_options.keymaps,
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
		no_scope_filter = {
			user_options.no_scope_filter,
			function(value)
				if type(value) ~= "table" then
					return false
				end

				---@diagnostic disable-next-line: no-unknown
				for i, v in ipairs(value) do
					if type(i) ~= "number" or type(v) ~= "string" then
						return false
					end
				end

				return true
			end,
			"WindowvigationKeymapOptions",
		},
		no_close_buftype = {
			user_options.no_close_buftype,
			function(value)
				if type(value) ~= "table" then
					return false
				end

				local allowed_values = {
					acwrite = true,
					help = true,
					nofile = true,
					nowrite = true,
					quickfix = true,
					terminal = true,
					prompt = true,
				} ---@type table<SpecialBufferType>

				---@diagnostic disable-next-line: no-unknown
				for i, v in ipairs(value) do
					if type(i) ~= "number" or type(v) ~= "string" then
						return false
					end

					if not allowed_values[v] then
						return false
					end
				end

				return true
			end,
			"WindowvigationKeymapOptions",
		},
	})

	return isValid
end

---@param opts? WindovigationOptions
M.setup = function(opts)
	local effective_options = vim.tbl_deep_extend("force", options, opts or {})
	local is_effective_options_valid = is_options_valid(effective_options)

	-- Update our options with the user options, if they're valid.
	if is_effective_options_valid then
		for key, value in pairs(effective_options) do
			options[key] = value
		end
	else
		vim.notify("Windovigation user options failed validation, proceeding with defaults.", vim.log.levels.WARN)
	end

	-- Add hidden options.
	globals.hidden_options.no_scope_filter_patterns = vim.tbl_map(vim.fn.glob2regpat, effective_options.no_scope_filter)
	globals.hidden_options.no_close_buftype_map = utils.list_to_set(effective_options.no_close_buftype)

	create_user_commands()
	create_auto_commands()
end

return M
