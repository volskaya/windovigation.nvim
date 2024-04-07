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

  -- Prevents the move actions from working when the current
  -- buffer type is nofile, that's usually on buffers like
  -- the Neotree or git diffs.
  prevent_switching_nofile = true,

  -- The files, where their path contains one of these values,
  -- won't be scoped in our history
  no_scope_filter = {
    -- This is here to workaround git diff for a split second opening some kind
    -- of a normal looking file in /private that shouldn't be scoped.
    "/private/var/folders*",
  },

  -- Prevents the buffer from closing, when there aren't any
  -- of our tracked windows still scoping their file.
  --
  -- This only respects special buffer types.
  --
  -- For example if you wish to stop terminal buffers from
  -- being closed, set this to {"terminal"}.
  no_close_buftype = {},

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
