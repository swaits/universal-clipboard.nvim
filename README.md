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
  -- If true, prints the chosen clipboard mode/tool at startup
  verbose = false,

  -- A table of tools to check, in order
  tools = {
    {
      name = "wl-clipboard",
      -- Either a string (the executable name) or a function returning boolean
      detect = function()
        local wayland_display = os.getenv("WAYLAND_DISPLAY")
        local wayland_runtime = os.getenv("XDG_RUNTIME_DIR")
        local socket_path = (wayland_runtime or "") .. "/" .. (wayland_display or "")
        return (vim.fn.executable("wl-copy") == 1)
          and (vim.fn.executable("wl-paste") == 1)
          and wayland_display ~= ""
          and (vim.fn.isdirectory(socket_path) == 1)
      end,
      commands = {
        copy = "wl-copy",
        paste = "wl-paste --no-newline",
      },
    },
    {
      name = "xclip",
      detect = "xclip", -- Will check vim.fn.executable("xclip")
      commands = {
        copy = "xclip -selection clipboard",
        paste = "xclip -selection clipboard -o",
      },
    },
    {
      name = "xsel",
      detect = "xsel",
      commands = {
        copy = "xsel --clipboard --input",
        paste = "xsel --clipboard --output",
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
