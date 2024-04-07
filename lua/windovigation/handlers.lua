local globals = require("windovigation.globals")
local history = require("windovigation.history")
local keymaps = require("windovigation.keymaps")
local layout = require("windovigation.layout")
local utils = require("windovigation.utils")

local M = {}

---@param event WindovigationEvent
M.handle_file_picked = function(event)
  if not utils.is_event_relevant(event) then
    return
  end

  -- INFO: Should we have some special handling here for relative paths a picker might pass in?
  local file = event.file
  local key_data = history.get_current_key_data()

  history.move_to_front(file, key_data.key)
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
  local key_data = history.get_current_key_data()

  layout.handle_layout_change()

  -- Handle the no_scope_filter before scoping the file.
  for _, value in ipairs(globals.hidden_options.no_scope_filter_patterns or {}) do
    if string.match(file, value) ~= nil then
      return
    end
  end

  history.scope_file(key_data, file)
end

---@param event WindovigationEvent
---@param options? WindovigationKeyOptions
M.handle_file_written = function(event, options)
  if not utils.is_event_relevant(event) then
    return
  end

  local file = event.file
  local key_data = history.get_current_key_data(options)

  if history.is_file_scoped(file, key_data.key) then
    history.move_to_front(file, key_data.key)
  end
end

---@param event WindovigationEvent
---@param tab integer
M.handle_tab_new = function(event, tab)
  local key_data = history.get_current_key_data({ tab = tab })

  -- For some reason the previous buffer registers in the new tab,
  -- and pushes its file to this state entry.
  globals.state[key_data.key] = nil
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
  -- We're not handling anything here anymore.
end

---@param event WindovigationEvent
M.handle_buf_delete = function(event)
  if not utils.is_event_relevant(event) then
    return
  end

  history.unscope_file(event.file)
end

return M
