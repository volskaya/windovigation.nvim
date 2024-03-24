local M = {}

M.state = {} ---@type WindovigationState
M.file_buffer_ids = {} ---@type table<string, integer>
M.buffer_file_ids = {} ---@type table<integer, string>

return M
