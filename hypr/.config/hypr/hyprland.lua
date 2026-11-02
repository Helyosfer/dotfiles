-- Hyprland loads this file when it is started without a config, and it prefers
-- it over hyprland.conf. HyDE loads it too, last, as the override layer below.
-- The block keeps the two apart: hyde.lua sets `hyde` on its first line, so it
-- runs only when this file is the entry point and HyDE has not been loaded.
-- Removing it leaves a session with a cursor and nothing else.
if not hyde then
	local share = os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")
	local entry = share .. "/hypr/hyde.lua"
	local handle = io.open(entry, "r")
	if not handle then
		error("HyDE is not installed at " .. entry .. ". Run install.sh -r, or point Hyprland at your own config.")
	end
	handle:close()
	dofile(entry)
end

-- Your Hyprland configuration. HyDE never overwrites this file.
--
-- It loads after HyDE's own binds, so settings here take precedence. Replacing
-- a bind needs more than that: see below. HyDE's defaults live in
-- ~/.local/share/hypr/lua/ and are overwritten on every update, so edits there
-- do not survive.
--
-- Adding a keybind:
--
--     hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(hyde.sh.gamelauncher()), {
--         description = "[Utilities] game launcher",
--     })
--
-- Replacing one of HyDE's: bind the same combination again and yours takes
-- over, but copy its flags across as well. A bind counts as the same one only
-- when its flags match, and `description` is not a flag — miss one and both
-- binds stay live on that combination. Copy the whole options table from
-- ~/.local/share/hypr/lua/key_binds.lua and change only what you need:
--
--     hl.bind("F9", hl.dsp.exec_cmd(hyde.sh.volumecontrol("-o", "m")), {
--         locked = true,
--         description = "[Hardware Controls|Audio] un/mute output",
--     })
--
-- Press SUPER + / to see what is actually loaded, your own binds included.
-- The full reference is KEYBINDINGS.md in the HyDE repository.
--
-- Other Lua files next to this one can be pulled in with require("name").

------------------------------------------------------------------------------
-- Keyboard layout: Turkish Q (HyDE leaves Hyprland's default, which is US)
------------------------------------------------------------------------------
hl.config({
	input = {
		kb_layout = "tr",
	},
})

------------------------------------------------------------------------------
-- CachyOS Hyprland keybinds (cachyos-hyprland-settings, keybinds.conf)
-- translated to Lua. Where a CachyOS bind collides with a HyDE one, the HyDE
-- feature is moved to SUPER+ALT+<same key> (listed in the RELOCATED block).
-- Flags match HyDE's originals so these replace them instead of stacking.
------------------------------------------------------------------------------
do
	local MOD = hyde.config.modifiers.main
	local HOME = os.getenv("HOME")
	local grimblast = HOME .. "/.local/lib/hyde/grimblast"
	local function bind(keys, dsp, desc, extra)
		local o = {description = "[CachyOS] " .. desc}
		for k, v in pairs(extra or {}) do o[k] = v end
		hl.bind(keys, dsp, o)
	end

	-- Apps and session
	bind(MOD .. " + RETURN", hl.dsp.exec_cmd(hyde.config.app.terminal), "terminal")
	bind(MOD .. " + SPACE", hl.dsp.exec_cmd(hyde.sh.menu.apps()), "application launcher")
	bind(MOD .. " + SHIFT + M", hl.dsp.exit(), "exit Hyprland")

	-- ALT+Enter opens the browser. For Brave use "brave" instead of "firefox".
	bind("ALT + RETURN", hl.dsp.exec_cmd("firefox"), "browser (Firefox)")
	bind(MOD .. " + O", hl.dsp.exec_cmd("pkill -SIGUSR2 waybar"), "reload Waybar")

	-- Window actions
	bind(MOD .. " + V", hl.dsp.window.float({action = "toggle"}), "toggle floating")
	bind(MOD .. " + Y", hl.dsp.exec_cmd(hyde.sh.window.pin()), "pin window")
	bind(MOD .. " + K", hl.dsp.group.toggle(), "toggle group")
	bind(MOD .. " + TAB", hl.dsp.group.next(), "next window in group")
	bind(MOD .. " + F", function()
		local w = hl.get_active_window()
		if not w then return end
		local n = ((tonumber(w.fullscreen) or 0) == 0) and 2 or 0
		hl.dispatch(hl.dsp.window.fullscreen_state({internal = n, client = n, window = w}))
	end, "toggle fullscreen")

	-- Gaps
	bind(MOD .. " + G", hl.dsp.exec_cmd("hyprctl eval 'hl.config({general={gaps_in=0,gaps_out=0}})'"), "remove gaps")
	bind(MOD .. " + SHIFT + G", hl.dsp.exec_cmd("hyprctl eval 'hl.config({general={gaps_in=3,gaps_out=5}})'"), "CachyOS default gaps")

	-- Screenshots (copied to clipboard)
	bind("Print", hl.dsp.exec_cmd(grimblast .. " copy area"), "screenshot: area")
	bind("CTRL + Print", hl.dsp.exec_cmd(grimblast .. " copy active"), "screenshot: active window")
	bind("ALT + Print", hl.dsp.exec_cmd(grimblast .. " copy screen"), "screenshot: screen")

	-- Move window: SUPER+SHIFT+arrows (same helper idea as HyDE's move_window)
	local function move_window(dir, pix)
		local lut = {l = {-1, 0}, r = {1, 0}, u = {0, -1}, d = {0, 1}}
		local m = lut[dir]
		return function()
			local w = hl.get_active_window()
			if not w then return end
			local args = w.floating and {x = m[1] * pix, y = m[2] * pix, relative = true} or {direction = dir}
			hl.dispatch(hl.dsp.window.move(args))
		end
	end
	bind(MOD .. " + SHIFT + LEFT", move_window("l", 30), "move window left", {repeating = true})
	bind(MOD .. " + SHIFT + RIGHT", move_window("r", 30), "move window right", {repeating = true})
	bind(MOD .. " + SHIFT + UP", move_window("u", 30), "move window up", {repeating = true})
	bind(MOD .. " + SHIFT + DOWN", move_window("d", 30), "move window down", {repeating = true})

	-- Quick resize: SUPER+CTRL+SHIFT+arrows / h j k l
	local rs = {LEFT = {-15, 0}, RIGHT = {15, 0}, UP = {0, -15}, DOWN = {0, 15}, H = {-15, 0}, L = {15, 0}, K = {0, -15}, J = {0, 15}}
	for key, d in pairs(rs) do
		bind(MOD .. " + CONTROL + SHIFT + " .. key,
			hl.dsp.window.resize({x = d[1], y = d[2], relative = true}), "resize " .. key:lower(), {repeating = true})
	end

	-- Resize mode: SUPER+R, then arrows or h j k l, Escape to leave
	hl.define_submap("resize", function()
		for key, d in pairs(rs) do
			hl.bind(key:lower(), hl.dsp.window.resize({x = d[1], y = d[2], relative = true}), {repeating = true})
		end
		hl.bind("escape", hl.dsp.submap("reset"))
	end)
	bind(MOD .. " + R", hl.dsp.submap("resize"), "resize mode (Escape to leave)")

	-- Workspaces: SUPER+CTRL+n moves and follows, SUPER+SHIFT+n moves silently
	for i = 1, 10 do
		local k = (i == 10) and 0 or i
		bind(MOD .. " + CONTROL + " .. k, hl.dsp.window.move({workspace = i}), "move window to workspace " .. i .. " and follow")
		bind(MOD .. " + SHIFT + " .. k, hl.dsp.window.move({workspace = i, follow = false}), "move window silently to workspace " .. i)
	end
	bind(MOD .. " + PERIOD", hl.dsp.focus({workspace = "e+1"}), "next workspace")
	bind(MOD .. " + COMMA", hl.dsp.focus({workspace = "e-1"}), "previous workspace")
	bind(MOD .. " + SLASH", hl.dsp.focus({workspace = "previous"}), "back to last workspace")
	bind(MOD .. " + MINUS", hl.dsp.window.move({workspace = "special"}), "move window to special workspace")
	bind(MOD .. " + EQUAL", hl.dsp.workspace.toggle_special(), "toggle special workspace")

	-- RELOCATED: HyDE features displaced by the CachyOS binds above
	bind(MOD .. " + ALT + V", hl.dsp.exec_cmd(hyde.sh.menu.clipboard()), "(HyDE) clipboard menu")
	bind(MOD .. " + ALT + K", hl.dsp.exec_cmd(hyde.sh.kb.switch()), "(HyDE) switch keyboard layout")
	bind(MOD .. " + ALT + TAB", hl.dsp.exec_cmd(hyde.sh.menu.windows()), "(HyDE) window switcher menu")
	bind(MOD .. " + ALT + SLASH", hl.dsp.exec_cmd(hyde.sh.menu.binds()), "(HyDE) keybindings hint")
	bind(MOD .. " + ALT + COMMA", hl.dsp.exec_cmd(hyde.sh.menu.emoji()), "(HyDE) emoji picker")
	bind(MOD .. " + ALT + PERIOD", hl.dsp.exec_cmd(hyde.sh.menu.glyph()), "(HyDE) glyph picker")
	bind(MOD .. " + CONTROL + G", hl.dsp.exec_cmd("hyde-shell gamelauncher"), "(HyDE) game launcher")
end
