# universal-clipboard.nvim

A **minimal** Neovim plugin that automatically sets up sharing your **system
clipboard** across multiple platforms. It addresses this issue:

> **Platform Differences**: On macOS, Neovim appears to behave nicely with the
> system `clipboard`. On others, not so much. External tools can help. For
> example, there’s `wl-copy`/`wl-paste` for Wayland or `xclip`/`xsel` for X11.

With **universal-clipboard.nvim**:

- If we detect an external clipboard tool (`wl-clipboard`, `xclip`, `xsel`),
  we configure Neovim’s `clipboard` to use it.
- Otherwise, we simply set `clipboard` to `unnamedplus` with no further
  configuration needed.

## Installation

Using [**packer.nvim**](https://github.com/wbthomason/packer.nvim):

```lua
use({
  "swaits/universal-clipboard.nvim",
  config = function()
    require("universal-clipboard").setup({
      verbose = false, -- optional: set true to log detection details
    })
  end,
})
```

Or [**lazy.nvim**](https://github.com/folke/lazy.nvim):

```lua
{
  "swaits/universal-clipboard.nvim",
  opts = {
    verbose = true, -- optional: set true to log detection details
  },
}
```

> **Note**: If your Neovim lacks `+clipboard`, make sure you have at least one
> of `wl-clipboard`, `xclip`, or `xsel` installed. Or you may customize the
> tools searched -- see below.

---

## Default Options

```lua
{
  -- Whether to log stuff to the vim console
  verbose = false,

  -- Copy/paste tools to check for
  tools = {
   -- macOS clipboard
   {
    name = "pbcopy",
    detect = function()
     return vim.fn.executable("pbcopy") == 1 and vim.fn.executable("pbpaste") == 1
    end,
    commands = {
     copy = "pbcopy",
     paste = "pbpaste",
    },
   },
   -- Wayland and wl-copy/wl-paste
   {
    name = "wl-clipboard",
    detect = function()
     local wayland_display = os.getenv("WAYLAND_DISPLAY")
     local wayland_runtime = os.getenv("XDG_RUNTIME_DIR")
     local socket_path = (wayland_runtime or "") .. "/" .. (wayland_display or "")
     return (vim.fn.executable("wl-copy") == 1)
      and (vim.fn.executable("wl-paste") == 1)
      and wayland_display ~= ""
      and (vim.fn.filereadable(socket_path) == 1)
    end,
    commands = {
     copy = "wl-copy",
     paste = "wl-paste --no-newline",
    },
   },
   -- Alternative Wayland tools
   {
    name = "waycopy",
    detect = function()
     local wayland_display = os.getenv("WAYLAND_DISPLAY")
     return vim.fn.executable("waycopy") == 1
      and vim.fn.executable("waypaste") == 1
      and wayland_display ~= nil
    end,
    commands = {
     copy = "waycopy",
     paste = "waypaste --no-newline",
    },
   },
   -- X11 and xclip
   {
    name = "xclip",
    detect = "xclip", -- Just a string, means "check if `xclip` is executable"
    commands = {
     copy = "xclip -selection clipboard",
     paste = "xclip -selection clipboard -o",
    },
   },
   -- X11 and xsel
   {
    name = "xsel",
    detect = "xsel",
    commands = {
     copy = "xsel --clipboard --input",
     paste = "xsel --clipboard --output",
    },
   },
   -- tmux clipboard
   {
    name = "tmux",
    detect = function()
     return os.getenv("TMUX") ~= nil and vim.fn.executable("tmux") == 1
    end,
    commands = {
     copy = "tmux load-buffer -",
     paste = "tmux save-buffer -",
    },
   },
   -- Lemonade (SSH)
   {
    name = "lemonade",
    detect = "lemonade",
    commands = {
     copy = "lemonade copy",
     paste = "lemonade paste",
    },
   },
   -- DoIt client (SSH)
   {
    name = "doitclient",
    detect = "doitclient",
    commands = {
     copy = "doitclient wclip",
     paste = "doitclient rclip",
    },
   },
   -- Windows win32yank
   {
    name = "win32yank",
    detect = "win32yank.exe",
    commands = {
     copy = "win32yank.exe -i --crlf",
     paste = "win32yank.exe -o --lf",
    },
   },
  },
 }
```

### Customizing Tools

If you want to add or remove tools, you can override the `tools` table in your
`setup()` call. For example:

```lua
require("universal-clipboard").setup({
  verbose = true,
  tools = {
    -- If you only want xclip, for instance:
    {
      name = "xclip-only",
      detect = "xclip",
      commands = {
        copy = "xclip -selection clipboard",
        paste = "xclip -selection clipboard -o",
      },
    },
    -- Or add more custom entries
  },
})
```

The plugin will iterate over `tools` in order and select the first one that is
“available.”

---

## Usage

Once installed, **no additional steps** are required. The plugin configures your
clipboard on startup. Simply copy and paste in Neovim as usual.

### Commands

- **`:UniversalClipboardCheck`**
  Prints the current `clipboard` configuration to the command line, showing what
  `vim.opt.clipboard` and `vim.g.clipboard` are set to.

- **`:UniversalClipboardReinit`**
  Re-runs the detection logic, forcing `verbose` mode for that run to help
  troubleshoot. You normally do **not** need this, but it can be helpful if you
  install a new system tool _after_ starting Neovim and want to see if it’s
  detected.

---

## License

[MIT License](LICENSE)
