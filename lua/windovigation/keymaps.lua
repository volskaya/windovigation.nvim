local actions = require("windovigation.actions")
local options = require("windovigation.options")

local M = {}

---@param buf integer?
M.set_default_keymaps = function(buf)
  if options.keymaps == nil then
    return
  end

  local movement_key = options.keymaps.bracket_movement_key or ""
  local movement_key_lwr = string.lower(movement_key)
  local movement_key_upr = string.upper(movement_key)
  local close_key = options.keymaps.buffer_close_key or ""

  local keymaps = movement_key:len() > 0
      and {
        { "n", "[" .. movement_key_lwr, actions.move_to_previous_file, "Previous File" },
        { "n", "]" .. movement_key_lwr, actions.move_to_next_file, "Next File" },
        { "n", "[" .. movement_key_upr, actions.move_to_first_file, "First File" },
        { "n", "]" .. movement_key_upr, actions.move_to_last_file, "Last File" },
      }
    or {}

  if close_key:len() > 0 then
    table.insert(keymaps, { "n", "<leader>b" .. close_key, actions.close_current_file, "Close File" })
  end

  for _, keymap in ipairs(keymaps) do
    local opts = { desc = keymap[4], buffer = buf, noremap = true } ---@type vim.keymap.set.Opts
    vim.keymap.set(keymap[1], keymap[2], keymap[3], opts)
  end
end

return M
