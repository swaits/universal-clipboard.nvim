-- lua/universal-clipboard/init.lua
local M = {}

-- Our default options
local default_opts = {
	verbose = false,
}

-- Pick copy/paste commands for Wayland or X11 if '+clipboard' is missing
local function pick_copy_paste_commands(opts)
	if opts.verbose then
		vim.notify("[universal-clipboard.nvim] looking for wl-copy/xclip/xsel ...")
	end

	-- Check Wayland + wl-copy/wl-paste
	local wayland_display = os.getenv("WAYLAND_DISPLAY")
	local wayland_runtime = os.getenv("XDG_RUNTIME_DIR")
	local wayland_socket_path = (wayland_runtime or "") .. "/" .. (wayland_display or "")

	local has_wlcopy = (vim.fn.executable("wl-copy") == 1)
	local has_wlpaste = (vim.fn.executable("wl-paste") == 1)
	local have_wayland = wayland_display and wayland_display ~= "" and (vim.fn.isdirectory(wayland_socket_path) == 1)

	if has_wlcopy and has_wlpaste and have_wayland then
		if opts.verbose then
			vim.notify("[universal-clipboard.nvim] found wl-copy/wl-paste + Wayland", vim.log.levels.INFO)
		end
		return {
			copy = "wl-copy",
			paste = "wl-paste --no-newline",
		}
	end

	-- Next, try xclip
	if vim.fn.executable("xclip") == 1 then
		if opts.verbose then
			vim.notify("[universal-clipboard.nvim] found xclip", vim.log.levels.INFO)
		end
		return {
			copy = "xclip -selection clipboard",
			paste = "xclip -selection clipboard -o",
		}
	end

	-- Otherwise, try xsel
	if vim.fn.executable("xsel") == 1 then
		if opts.verbose then
			vim.notify("[universal-clipboard.nvim] found xsel", vim.log.levels.INFO)
		end
		return {
			copy = "xsel --clipboard --input",
			paste = "xsel --clipboard --output",
		}
	end

	-- No suitable tool found
	if opts.verbose then
		vim.notify("[universal-clipboard.nvim] none found.")
	end
	return nil
end

-- 4) Actually configure Neovim's clipboard usage
local function configure_clipboard(opts)
	-- Unify normal yanks/pastes to systepm clipboard
	vim.opt.clipboard = "unnamedplus"

	-- Search for custom clipboard provider
	local commands = pick_copy_paste_commands(opts)
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
		return "wl-copy/xclip/xsel"
	else
		-- No tool found
		if opts.verbose then
			vim.notify(
				"[universal-clipboard.nvim] No external clipboard tool found (wl-copy, xclip, xsel).",
				vim.log.levels.WARN
			)
		end
		return "system"
	end
end

-- Setup function (entry point)
function M.setup(user_opts)
	-- Merge defaults with user_opts
	local opts = vim.tbl_deep_extend("force", default_opts, user_opts or {})

	-- Set the clipboard up
	local mode = configure_clipboard(opts)
	if opts.verbose then
		vim.notify(("[universal-clipboard.nvim] Clipboard mode: %s"):format(mode), vim.log.levels.INFO)
	end

	-- Create user commands for debugging / re-init
	vim.api.nvim_create_user_command("UniversalClipboardCheck", function()
		print("=== UniversalClipboardCheck ===")

		local opt_clipboard = vim.opt.clipboard:get()
		print("vim.opt.clipboard = ", vim.inspect(opt_clipboard))

		if vim.g.clipboard then
			print("vim.g.clipboard = ", vim.inspect(vim.g.clipboard))
		else
			print("vim.g.clipboard is not set.")
		end
	end, {})

	vim.api.nvim_create_user_command("UniversalClipboardReinit", function()
		local new_mode = configure_clipboard({ verbose = true })
		print("Reinitialized clipboard mode: " .. new_mode)
		vim.cmd("UniversalClipboardCheck")
	end, {})
end

return M
