A plugin for Neovim that lets you switch buffers based on window unique file history like VScode and Evil Emacs, instead of a global buffer list.

# Motivation

By default you can't reliably switch backwards to previous buffers, when working with multiple window splits and tabs, because all of your windows keep ordering the same global buffer history.

For example if you return to an older window, that's showing a file you edited 4 buffers ago, if you'd jump forward to a definition in that file, let's say an enum that you need to add a new value to, then you kill that buffer or switch to the previous buffer, you're now thrown to the last buffer from some other window.

A window unique file history fixes that.

It makes every window track its own file history, so if you would now switch forward to another file from an old window, you can be sure that switching backward will return you to the previous file.

This makes it consistent with how switching is done in vim modes on VSCode and Emacs too.

# Installation

1. Add the plugin to your config with disabled lazy loading, for example LazyVim:

```lua
{
  "volskaya/windovigation.nvim",
  lazy = false,
  opts = {},
}
```

2. If you use a session restoration plugin that provides something like a pre save hook, you should add our `persist_state` to its config.

###### For example LazyVim's default `folke/persistence.nvim`

```lua
{
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {
    pre_save = function()
      require("windovigation.actions").persist_state()
    end,
  },
}
```

3. Add `"buffers", "blank", "help", "terminal", "winsize", "tabpages"` to your global `sessionoptions`. For this plugin to restore state properly, your window layout must match between close and restore.

_If your session restoration plugin isn't wrapped around `:mksession` or ignores `sessionoptions`, refer to their README on how to handle this properly, if needed._

###### Example (place it together with your other global options)

```lua
vim.opt.sessionoptions = {
  -- Windovigation required options.
  "buffers",
  "help",
  "blank",
  "terminal",
  "winsize",
  "tabpages",
  -- Other options.
  "curdir",
  "globals",
  "folds",
}
```

# Options

```lua
{
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
```

# Session Restoration

By default the plugin automatically restores state on `SessionLoadPost`, that's called by Neovim when restoring a session. But you can handle this manually with lua.

```lua
require("windovigation.actions").persist_state()
require("windovigation.actions").restore_state()
```

# Default Keymaps

- `[b` - Switches to the previous file.
- `]b` - Switches to the next file.
- `[B` - Switches to the first file.
- `]B` - Switches to the last file.
- `<leader>bk` - Closes the current file and destroys the buffer, if no other window has this file open.

# Commands

- `:WindovigationPreviousFile` - Switches to the previous file.
- `:WindovigationNextFile` - Switches to the next file.
- `:WindovigationFirstFile` - Switches to the first file.
- `:WindovigationLastFile` - Switches to the last file.
- `:WindovigationCloseFile` - Closes the current file and destroys the buffer, if no other window has this file open.

# Lua Actions

```lua
require("windovigation.actions").move_to_previous_file()
require("windovigation.actions").move_to_next_file()
require("windovigation.actions").move_to_first_file()
require("windovigation.actions").move_to_last_file()

require("windovigation.actions").close_current_file()

require("windovigation.actions").restore_state()
require("windovigation.actions").persist_state()
```

# Custom File Picker Integration

Integrating with your file picker is optional

But it's expected that switching to a file through a file picker or a text search, bumps the file to the front of that windows history.

In Neovim there really isn't a consistent "File Picked" event, so this case needs to be handled manually in your config with `require("windovigation.handlers").handle_file_picked`.

###### Example

```lua
require("windovigation.handlers").handle_file_picked({
  buf = vim.api.nvim_get_current_buf(),
  file = file_name, -- A file name that was provided by your file picker.
})
```

# Telescope Integration Example

I use Telescope, so I've included utilities that you should be able to add out of the box to your config or use it as reference.

###### Telescope bultin picker example by passing `attach_mappings` to their options

```lua
require("telescope.builtin").find_files({
  -- Windovigation mappings that will bump the file in the active history, when selected.
  attach_mappings = require("windovigation.telescope-utils").attach_mappings,
})
```

###### File browser extension by passing actions to telescope opts

```lua
{
  extensions = {
    file_browser = {
      mappings = {
        ["n"] = {
          ["<Enter>"] = require("windovigation.telescope-file-picker-utils").open_dir_or_file_action,
          ["l"] = require("windovigation.telescope-file-picker-utils").open_dir_or_file_action,
        },
      },
    },
  }
}
```
