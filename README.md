A plugin that has Neovim windows track their open files and allows switching between them.

# Before / After Preview

https://github.com/volskaya/windovigation.nvim/assets/38878482/be0bd579-ac25-4dc0-ad70-4fc362f2c6ce


# Motivation

By default you can't reliably jump backwards to previous buffers, when working with multiple window splits and tabs, because all of your windows keep ordering the same global buffer history.

For example if you return to an older window, that's showing a file you edited 4 buffers ago, if you'd jump forward to a definition in that file, let's say an enum that you need to add a new value to, then you kill that buffer or jump to previous buffer, you're now thrown to the last buffer from some other window.

A window unique file history fixes that.

It makes every window track its own file history, so if you would now jump forward to another file from an old window, you can be sure that jumping backward will return you to the previous file.

This makes it consistent with how switching is done in vim modes on VSCode and Emacs too.

# Behavior

- As you enter a new buffer with a file, it's added to the history of that window.
- Switching between buffers with our movement keys selects the next buffer based on that windows file history.
- When a buffer is written, the associated file is bumped to the front of the history.
- Killing buffers with with our `close_file` action only closes them in the current window and does not change other windows and tabs. The buffer is only really killed when no other window has it in their history.

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

  -- Options for the built in keymaps that get
  -- reattached to every buffer on enter, to avoid
  -- lazy loaded packages from stealing them.
  --
  -- Set this to nil if you wish to set keymaps by yourself.
  keymaps = {
    bracket_movement_key = "b", -- [b, ]b, [B, ]B
    buffer_close_key = "k", -- <leader>bk
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

But it's expected that jumping to a file through a file picker or a text search, bumps the file to the front of that windows history.

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
