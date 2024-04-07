-- telescope-config.lua
local M = {}

---Call this from "attach_mappings" in Telescope options.
---
---This replace extends default select and has windovigation
---bump the picked file to the front of the window file hstory.
M.replace_select = function()
  local action_state = require("telescope.actions.state")
  local action_set = require("telescope.actions.set")
  local select_new = function(prompt_bufnr, type, dir)
    local command = action_state.select_key_to_edit_key(type)
    local entry = action_state.get_selected_entry()

    if not entry then
      return
    end

    -- Perform the default call before performing post operations.
    local default = action_set.edit(prompt_bufnr, command)

    if entry.path or entry.filename then
      local buf = vim.api.nvim_get_current_buf()
      local filename = entry.path or entry.filename

      if prompt_bufnr ~= buf then
        if command == "edit" or command == "new" or command == "vnew" or command == "tabedit" then
          -- When selecting a file, we bump our file history.
          require("windovigation.handlers").handle_file_picked({ buf = buf, file = filename })
        end
      end
    end

    return default
  end

  action_set.select:replace(select_new)
end

---Performs a premade attach_mappings for telescope, to
---replace select action that has window file history
---react to the picked file.
---
---@return boolean
M.attach_mappings = function()
  M.replace_select()
  return true
end

return M
