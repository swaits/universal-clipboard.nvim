# universal-clipboard.nvim

A **minimal** Neovim plugin that automatically sets up sharing your **system
clipboard** across multiple platforms. It addresses this issue:

> **Platform Differences**: On macOS, Neovim appears to behave nicely with the
> system `clipboard`. On others, not so much. External tools can help. For
> example, there’s `wl-copy`/`wl-paste`for Wayland or`xclip`/`xsel` for X11.

With **universal-clipboard.nvim**:

- If we detect an external clipboard tool (`wl-clipboard`, `xclip`, `xsel`),
  we configure the `clipboard` to use it.
- Otherwise, we simply set it to `unnamedplus` with no further configuration.

## Installation

Using [**packer.nvim**](https://github.com/wbthomason/packer.nvim):

```lua
use({
  "swaits/universal-clipboard.nvim",
  config = function()
    require("universal-clipboard").setup({
      verbose = false, -- optional, set true to see a small startup message
    })
  end,
})
```

Or [**lazy.nvim**](https://github.com/folke/lazy.nvim):

```lua
{
  "swaits/universal-clipboard.nvim",
  opts = {
    verbose = true, -- optional, set true to see a small startup message
  },
}
```

> **Note:** If your Neovim lacks `+clipboard`, make sure you have at least one
> of `wl-clipboard`, `xclip`, or `xsel` is installed.

### Default Options

```lua
{
  -- If true, prints the chosen clipboard mode at startup
  verbose = false,
}
```

## Usage

Once installed, **no additional steps** are needed. The plugin configures your
clipboard on startup. Simply copy and paste in Neovim as usual.

### Commands

- `:UniversalClipboardCheck` - Shows the current `clipboard` configuration.
- `:UniversalClipboardReinit` - Re-runs detection. You **do not normally need to
  run this.** It's run automatically on startup.

## License

[MIT License](LICENSE)
