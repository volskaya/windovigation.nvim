---@type WindovigationOptions
local options = {
	-- Auto restore state on SessionLoadPost.
	--
	-- When using plugins with custom session handling,
	-- use require("windovigation.actions").restore_state().
	auto_restore_state = true,

	-- Auto persist state on VimLeavePre.
	--
	-- This only persists it vim global variables and
	-- does not create the session file for you! It's
	-- expected you have something else actually handle
	-- the session file.
	--
	-- When using plugins with custom session handling,
	-- use require("windovigation.actions").persist_state().
	auto_persist_state = true,

	-- When toggled on, closing a file will switch to the most
	-- recent entered file, not the recently written file.
	after_close_file_switch_to_recent = true,

	-- Options for the built in keymaps that get
	-- reattached to every buffer on enter, to avoid
	-- lazy loaded packages from stealing them.
	--
	-- Set this to nil if you wish to set keymaps by yourself.
	keymaps = {
		bracket_movement_key = "b", -- Like [b, ]b, [B, ]B
		buffer_close_key = "k", -- Like <leader>bk
	},
}

return options
