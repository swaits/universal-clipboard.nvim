-- lua/universal-clipboard/init.lua
local M = {
	-- Our default options
	opts = {
		-- Whether to log stuff to the vim console
		verbose = false,

		-- Copy/paste tools to check for
		tools = {
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
		},
	},
}

-- Utils for logging
local function log(msg, level)
	if M.opts.verbose then
		vim.notify(msg, level or vim.log.levels.INFO)
	end
end

local function info(msg)
	log(msg, vim.log.levels.INFO)
end

local function warn(msg)
	log(msg, vim.log.levels.WARN)
end

-- Pick copy/paste commands from the list in opts.tools
local function pick_copy_paste_tool()
	info("[universal-clipboard.nvim] looking for copy/paste tool ...")

	local function check_detect(tool)
		if type(tool.detect) == "function" then
			info("[universal-clipboard.nvim]: running detect function for " .. tool.name)
			return tool.detect()
		elseif type(tool.detect) == "string" then
			info("[universal-clipboard.nvim]: checking for executable " .. tool.detect)
			return vim.fn.executable(tool.detect) == 1
		else
			vim.notify(
				"[universal-clipboard.nvim] tool.detect is not a string or function: " .. vim.inspect(tool),
				vim.log.levels.ERROR
			)
		end
		-- Fallback for unexpected types
		return false
	end

	for _, tool in ipairs(M.opts.tools) do
		info("[universal-clipboard.nvim] checking for " .. tool.name)
		if check_detect(tool) then
			info("[universal-clipboard.nvim] found " .. tool.name)
			return tool
		end
	end

	info("[universal-clipboard.nvim] none found.")
	return nil
end

-- Configure Neovim's clipboard usage
local function configure_clipboard()
	-- Unify normal yanks/pastes to systepm clipboard
	vim.opt.clipboard = "unnamedplus"

	-- Search for custom clipboard provider
	local tool = pick_copy_paste_tool()
	if tool then
		vim.g.clipboard = {
			name = "UniversalClipboard(" .. tool.name .. ")",
			copy = {
				["+"] = tool.commands.copy,
				["*"] = tool.commands.copy,
			},
			paste = {
				["+"] = tool.commands.paste,
				["*"] = tool.commands.paste,
			},
			cache_enabled = 0,
		}
		return tool.name
	else
		-- No tool found
		warn("[universal-clipboard.nvim] No external clipboard tool found.")
		return "(none)"
	end
end

-- Setup function (entry point)
function M.setup(opts)
	-- Merge defaults with opts
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})

	-- Set the clipboard up
	local tool_name = configure_clipboard()
	info(("[universal-clipboard.nvim] Clipboard tool: %s"):format(tool_name))

	-- Command for viewing results
	vim.api.nvim_create_user_command("UniversalClipboardCheck", function()
		print("=== UniversalClipboardCheck ===")
		local opt_clipboard = vim.opt.clipboard:get()
		print("vim.opt.clipboard = ", vim.inspect(opt_clipboard))
		print("vim.g.clipboard = ", vim.inspect(vim.g.clipboard))
	end, {})

	-- Command for re-running checks
	vim.api.nvim_create_user_command("UniversalClipboardReinit", function()
		print("=== UniversalClipboardReinit ===")
		local original_verbose = M.opts.verbose
		M.opts.verbose = true
		local new_tool_name = configure_clipboard()
		print("Reinitialized external clipboard tool: " .. new_tool_name)
		vim.cmd("UniversalClipboardCheck")
		M.opts.verbose = original_verbose
	end, {})
end

return M
