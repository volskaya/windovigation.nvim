---@alias WindovigationKey string
---@alias WindovigationBufferTable table<integer, string>
---@alias WindovigationState table<WindovigationKey, WindovigationEntry>

---The history class holding 2 lists, one ordered by file entered, and the other by file written.
---
---Written history counts as the more important one, that the plugin uses to check if files are
---scoped or need to be fronted, etc.
---
---Entered history are used to determine the next file to switch when closing a file.
---@class WindovigationHistory
---@field entered table<string>
---@field written table<string>

---@class WindovigationKeyOptions
---@field isResursive? boolean
---@field tab? integer
---@field win? integer
---@field buf? integer

---@class WindovigationEntry
---@field tab integer
---@field page integer ---Tab number.
---@field win integer
---@field pane integer ---Window number.
---@field histories WindovigationHistory

---@class WindovigationEvent
---@field buf integer
---@field file string

---@class WindovigationEventRelevantOptions
---@field allow_relative_path? boolean

---@class WindovigationLayoutChangeOptions
---@field is_restoring_state? boolean

---@class WindovigationKeymapOptions
---@field bracket_movement_key? string
---@field buffer_close_key? string

---@class WindovigationOptions
---@field auto_restore_state boolean
---@field auto_persist_state boolean
---@field after_close_file_switch_to_recent boolean
---@field prevent_switching_nofile boolean
---@field keymaps? WindovigationKeymapOptions
