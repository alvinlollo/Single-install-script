-- This file will not be overwritten across dots-hyprland updates.
-- The file name is for the sake of organization and does not matter
-- See the corresponding files in ~/.config/hypr/hyprland for examples

--##! Overrides
--# Unbind upstream binds we want to replace
hl.unbind("SUPER + B") -- sidebar toggle -> we use this for browser
hl.unbind("SUPER + T") -- terminal (we don't want this combo)
hl.unbind("CTRL + ALT + T") -- terminal (we don't want this combo)
hl.unbind("SUPER + W") -- browser (we use B instead)
hl.unbind("SUPER + ALT + Page_Up")
hl.unbind("SUPER + ALT + Page_Down")
hl.unbind("SUPER + SHIFT + Page_Up")
hl.unbind("SUPER + SHIFT + Page_Down")
hl.unbind("SUPER + O")

--# Unbind workspace focus with named keys (we use code: keys)
for i = 0, 9 do
	hl.unbind("SUPER + " .. i)
end

--# Rebind browser on B (previously sidebar toggle)
hl.bind("SUPER + B", hl.dsp.exec_cmd(browser), { description = "App: Browser" })

--##! Workspace
--# Switching with raw keycodes (layout-independent)
for i = 1, 10 do
	local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
	hl.bind("SUPER + code:" .. numberkey[i], function()
		hl.dispatch(hl.dsp.focus({ workspace = workspace_in_group(i) }))
	end)
end
--# keypad numbers
for i = 1, 10 do
	local numpadkey = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }
	hl.bind("SUPER + code:" .. numpadkey[i], function()
		hl.dispatch(hl.dsp.focus({ workspace = workspace_in_group(i) }))
	end)
end

--#/# bind = SUPER+CTRL, code:,, -- Send to workspace & switch
for i = 1, 10 do
	local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
	hl.bind("SUPER + CTRL + code:" .. numberkey[i], function()
		hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = true }))
	end)
end
--# keypad numbers
for i = 1, 10 do
	local numpadkey = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }
	hl.bind("SUPER + CTRL + code:" .. numpadkey[i], function()
		hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = true }))
	end)
end

--#/# bind = SUPER+ALT+SHIFT, Page_↑/↓,, -- Send to workspace left/right
for i = 1, 6 do
	local key = { "SUPER + ALT + Page_", "SUPER + SHIFT + Page_", "CTRL + SUPER + SHIFT + " }
	local keycombos =
		{ key[1] .. "down", key[1] .. "up", key[2] .. "down", key[2] .. "up", key[3] .. "Right", key[3] .. "Left" }
	local prefix = { "+", "-", "r+", "r-", "r+", "r-" }
	hl.bind(keycombos[i], hl.dsp.window.move({ workspace = prefix[i] .. "1" })) -- # [hidden]
end
