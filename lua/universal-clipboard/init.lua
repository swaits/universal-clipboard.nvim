-- lua/universal-clipboard/init.lua
local M = {}

-- 1) Default options
local default_opts = {
	verbose = false,
}

-- 2) Check if Neovim has '+clipboard'
local function has_builtin_clipboard()
	return vim.fn.has("clipboard") == 1
end

-- 3) Pick copy/paste commands for Wayland or X11 if '+clipboard' is missing
local function pick_copy_paste_commands()
	-- Check Wayland + wl-copy/wl-paste
	local wayland_display = os.getenv("WAYLAND_DISPLAY")
	local wayland_runtime = os.getenv("XDG_RUNTIME_DIR")
	local wayland_socket_path = (wayland_runtime or "") .. "/" .. (wayland_display or "")

	local has_wlcopy = (vim.fn.executable("wl-copy") == 1)
	local has_wlpaste = (vim.fn.executable("wl-paste") == 1)
	local have_wayland = wayland_display and wayland_display ~= "" and (vim.fn.isdirectory(wayland_socket_path) == 1)

	if has_wlcopy and has_wlpaste and have_wayland then
		return {
			copy = "wl-copy",
			paste = "wl-paste --no-newline",
		}
	end

	-- Otherwise, try xclip
	if vim.fn.executable("xclip") == 1 then
		return {
			copy = "xclip -selection clipboard",
			paste = "xclip -selection clipboard -o",
		}
	end

	-- Otherwise, try xsel
	if vim.fn.executable("xsel") == 1 then
		return {
			copy = "xsel --clipboard --input",
			paste = "xsel --clipboard --output",
		}
	end

	-- No suitable tool found
	return nil
end

-- 4) Actually configure Neovim's clipboard usage
local function configure_clipboard()
	if has_builtin_clipboard() then
		-- Neovim has native +clipboard
		vim.opt.clipboard = "unnamedplus"
		return "builtin"
	else
		-- Fall back to custom clipboard provider
		local commands = pick_copy_paste_commands()
		if commands then
			vim.g.clipboard = {
				name = "UniversalClipboard",
				copy = {
					["+"] = commands.copy,
					["*"] = commands.copy,
				},
				paste = {
					["+"] = commands.paste,
					["*"] = commands.paste,
				},
				cache_enabled = 0,
			}
			-- Also unify normal yanks/pastes to system clipboard
			vim.opt.clipboard = "unnamedplus"
			return "fallback"
		else
			-- No tool found
			vim.notify(
				"[universal-clipboard.nvim] No suitable clipboard tool found (wl-copy, xclip, xsel).",
				vim.log.levels.WARN
			)
			return "none"
		end
	end
end

-- 5) Setup function (entry point)
function M.setup(user_opts)
	-- Merge defaults with user_opts
	local opts = vim.tbl_deep_extend("force", default_opts, user_opts or {})

	local mode = configure_clipboard()
	if opts.verbose then
		vim.notify(("[universal-clipboard.nvim] Clipboard mode: %s"):format(mode), vim.log.levels.INFO)
	end

	-- Create user commands for debugging / re-init
	vim.api.nvim_create_user_command("UniversalClipboardCheck", function()
		if has_builtin_clipboard() then
			print("Neovim has +clipboard. Current setting:")
			print(vim.inspect(vim.opt.clipboard:get()))
		else
			print("Neovim lacks +clipboard. Using fallback if available.")
			if vim.g.clipboard then
				print("Fallback config: " .. vim.inspect(vim.g.clipboard))
			else
				print("No fallback is set (no suitable tool found?).")
			end
		end
	end, {})

	vim.api.nvim_create_user_command("UniversalClipboardReinit", function()
		local new_mode = configure_clipboard()
		print("Reinitialized clipboard mode: " .. new_mode)
	end, {})
end

return M
