local globals = require("windovigation.globals")
local utils = require("windovigation.utils")

local M = {}

---@param options? WindovigationKeyOptions
---@return WindovigationKeyData
M.get_current_key_data = function(options)
  local win = options and options.win or vim.api.nvim_get_current_win()
  local tab = options and options.tab or vim.api.nvim_win_get_tabpage(win)
  local page = vim.api.nvim_tabpage_get_number(tab)
  local pane = vim.api.nvim_win_get_number(win)

  return {
    key = page .. "_" .. pane,
    win = win,
    tab = tab,
    pane = pane,
    page = page,
  }
end

---@param file string
---@param history string[]
---@return boolean
M.is_file_scoped_in_history = function(file, history)
  local is_absolute_path = vim.startswith(file, "/")

  for _, v in ipairs(history) do
    local is_match = is_absolute_path and v == file or vim.endswith(v, file)
    if is_match then
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

  for _, v in ipairs(entry_old.histories.written) do
    local is_match = is_absolute_path and v == file or string.sub(v, -file_length, -1) == file

    if not is_match then
      table.insert(histories_new.written, v)
    elseif fronted_file_name == nil then
      fronted_file_name = v
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

---Scopes the file under the relevant entry for this key.
---
---If the entry doesn't exist, it is created.
---
---@param key_data WindovigationKeyData
---@param file string
M.scope_file = function(key_data, file)
  local entry = globals.state[key_data.key]
  local entry_histories = entry.histories or { entered = {}, written = {} }

  -- TODO: Exract this before putting it in move_to_file.
  if not M.is_file_scoped(file, key_data.key) then
    table.insert(entry_histories.entered, file)
    table.insert(entry_histories.written, file)

    globals.state[key_data.key] = {
      tab = key_data.tab,
      page = key_data.page,
      win = key_data.win,
      pane = key_data.pane,
      histories = entry_histories,
    }
  elseif file ~= entry_histories.entered[#entry_histories.entered] then
    -- If the file is already scoped, only bump it in the "entered" history.
    globals.state[key_data.key] = {
      tab = key_data.tab,
      page = key_data.page,
      win = key_data.win,
      pane = key_data.pane,
      histories = {
        entered = utils.append_skipping_existing(entry_histories.entered, file),
        written = entry_histories.written,
      },
    }
  end
end

--- Removes the file from all entries.
--
---@param file string
---@return boolean
M.unscope_file = function(file)
  local did_remove_something = false

  -- Remove the file from all entries.
  for key, entry in pairs(globals.state) do
    local written_new, did_remove = utils.remove_from_table(entry.histories.written, file)

    if did_remove then
      did_remove_something = true
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

  return did_remove_something
end

---This call will respect options.
---
---If the buffer isn't closed, because the options
---prevent the buftype from closing, but it's the
---last buffer in the window, close the window
---instead.
---
---@param id string | integer -- If passing string, assume it's a file, if integer - buffer id.
---@param force? boolean
---@return boolean -- True if buffer or window got closed.
M.maybe_close_buffer_for_file = function(id, force)
  local file = type(id) == "string" and id or nil
  local buf = type(id) == "number" and id or nil

  if file and M.is_file_scoped(file) then
    return false
  end

  local effective_buf = buf or (file and utils.find_buf_by_name(file) or nil)
  if effective_buf then
    local buftype = vim.bo[effective_buf].buftype
    local prevent_close = globals.hidden_options.no_close_buftype_map[buftype] ~= nil

    if prevent_close then
      return false
    end
  end

  return pcall(vim.cmd.bdelete, { id, bang = force or false })
end

return M
