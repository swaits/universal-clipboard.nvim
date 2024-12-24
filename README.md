# universal-clipboard.nvim

A **minimal** Neovim plugin that automatically sets up sharing your **system
clipboard** across multiple platforms. It addresses two common issues:

1. **Platform Differences**: On macOS, `pbcopy/pbpaste` is native; on Linux,
   there’s `wl-copy`/`wl-paste` for Wayland or `xclip`/`xsel` for X11.
2. **Missing `+clipboard`**: Many distro packages ship Neovim **without**
   built-in clipboard support.

With **universal-clipboard.nvim**:

- If Neovim **has** `+clipboard`, we simply use `unnamedplus`.
- If **not**, we detect which clipboard tool (`wl-clipboard`, `xclip`, `xsel`)
  is available, and configure a fallback automatically.

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

> **Note:** If your Neovim lacks `+clipboard`, make sure you have at least one
> of `wl-clipboard`, `xclip`, or `xsel` is installed.

### Commands

- `:UniversalClipboardCheck` - Shows whether Neovim has `+clipboard` and the
  current fallback configuration, if any.
- `:UniversalClipboardReinit` - Re-runs detection. You **do not need to run
  this.** It's run automatically on startup.

## License

[MIT License](LICENSE)
