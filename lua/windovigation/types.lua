---Where the value is the file name.
---@alias WindovigationHistory table<string>
---@alias WindovigationKey string
---@alias WindovigationBufferTable table<integer, string>
---@alias WindovigationState table<WindovigationKey, WindovigationEntry>

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
---@field history WindovigationHistory

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
---@field keymaps? WindovigationKeymapOptions
