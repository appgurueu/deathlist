local colorspec_new = modlib.minetest.colorspec.new
modlib.log.create_channel"deathlist"
-- Create modlib.log channel
local coordinate = {
	type = "table",
	children = { x = { type = "number" }, y = { type = "number" } }
}
local component = { type = "number", interval = { 0, 255 }, int = true }
local color = { type = "table", children = { r = component, g = component, b = component } }
local node_caused = {
	children = {
		color = color,
		method = { type = "string" },
		nodes = {
			type = "table",
			keys = { type = "string" },
			values = {
				type = "table",
				keys = {
					possible_values = { name = true, color = true, method = true }
				}
			}
		}
	}
}
local name_color_method = {
	children = { name = { type = "string" }, color = color, method = { type = "string" } }
}
local config = modlib.conf.import("deathlist", {
	type = "table",
	children = {
		max_messages = { type = "number", interval = { 1 } },
		mode = { type = "string", possible_values = { list = true, stack = true } },
		autoremove_interval = {
			func = function(interval)
				if type(interval) ~= "number" and interval ~= false then
					return "Wrong type: Expected number or false, found " .. type(interval)
				end
				if interval <= 0 then return "Too small: Interval has to be > 0" end
			end
		},
		hud_pos = coordinate,
		hud_base_offset = coordinate,
		enable_environmental = { type = "boolean" },
		enable_unknown = { type = "boolean" },
		enable_forbidden_playernames = { type = "boolean" },
		environmental_reasons = {
			children = {
				falling = name_color_method,
				unknown = name_color_method,
				drowning = node_caused,
				node_damage = node_caused
			}
		}
	}
})
modlib.table.add_all(getfenv(1), config)
if enable_forbidden_playernames then
	modlib.player.register_forbidden_name(environmental_reasons.falling.name)
	if enable_unknown then
		modlib.player.register_forbidden_name(environmental_reasons.unknown.name)
	end
	for name, node in pairs(minetest.registered_nodes) do
		if (node.drowning or 0) > 0 then
			local title = (environmental_reasons.drowning.nodes[name] or {}).name or node.description
			modlib.player.register_forbidden_name(title)
		end
		if (node.damage_per_second or 0) > 0 then
			local title = (environmental_reasons.node_damage.nodes[name] or {}).name or node.description
			modlib.player.register_forbidden_name(title)
		end
	end
end
for _, table in pairs{ environmental_reasons, environmental_reasons.drowning.nodes, environmental_reasons.node_damage.nodes } do
	for _, value in pairs(table) do
		if value.color then
			value.color = colorspec_new(value.color):to_number_rgb()
		end
	end
end
hud_channels = {}
minetest.register_on_joinplayer(function(player)
	hud_channels[player:get_player_name()] = { killers = {}, items = {}, victims = {} }
end)
minetest.register_on_leaveplayer(function(player) hud_channels[player:get_player_name()] = nil end)

function remove_last_kill_message()
	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local hud_channels = hud_channels[name]
		for hud_ids, x_offset in pairs{ [hud_channels.killers] = -20, [hud_channels.victims] = 20, [hud_channels.items] = 0 } do
			local last = #hud_ids
			if last > 0 then
				if mode == "list" then
					player:hud_remove(hud_ids[last])
					hud_ids[last] = nil
				else
					player:hud_remove(hud_ids[1])
					-- Will be replaced
					for j = 2, last do
						local new = { x = hud_base_offset.x + x_offset, y = hud_base_offset.y - (j - 2) * 20 }
						player:hud_change(hud_ids[j], "offset", new)
						-- Perform index shift
						hud_ids[j - 1] = hud_ids[j]
					end
					hud_ids[last] = nil
				end
			end
		end
	end
end

local last_message = 0
if autoremove_interval then
	minetest.register_globalstep(function(dtime)
		last_message = last_message + dtime
		if last_message > autoremove_interval then
			remove_last_kill_message()
			last_message = 0
		end
	end)
end

local function add_kill_msg_to_hud(msg, listname, hud_def, x_offset)
	hud_def.text = msg
	hud_def.offset = { x = x_offset + hud_base_offset.x }
	for _, player in pairs(minetest.get_connected_players()) do
		local hud_ids = hud_channels[player:get_player_name()][listname] or {}
		local i = #hud_ids
		if i == max_messages then
			-- Have to remove
			if mode == "list" then player:hud_remove(hud_ids[i])
			else
				player:hud_remove(hud_ids[1])
				-- Will be replaced
				for j = 2, i do
					local new = { x = hud_def.offset.x, y = hud_base_offset.y - (j - 2) * 20 }
					player:hud_change(hud_ids[j], "offset", new)
					-- Perform index shift
					hud_ids[j - 1] = hud_ids[j]
				end
			end
			i = i - 1
		end
		if mode == "list" then
			for j = i, 1, -1 do
				local new = { x = hud_def.offset.x, y = hud_base_offset.y - j * 20 }
				player:hud_change(hud_ids[j], "offset", new)
				-- Perform index shift
				hud_ids[j + 1] = hud_ids[j]
			end
			hud_def.offset.y = hud_base_offset.y
			hud_ids[1] = player:hud_add(hud_def)
		else
			hud_def.offset.y = hud_base_offset.y - i * 20
			hud_ids[i + 1] = player:hud_add(hud_def)
		end
	end
end

function add_kill_message(killer, tool_image, victim)
	add_kill_msg_to_hud(killer.name, "killers", {
		hud_elem_type = "text",
		position = hud_pos,
		scale = { x = 100, y = 100 },
		number = killer.color or 0xFFFFFF,
		alignment = { x = -1, y = 0 }
	}, -20)
	add_kill_msg_to_hud(victim.name, "victims", {
		hud_elem_type = "text",
		position = hud_pos,
		number = victim.color or 0xFFFFFF,
		alignment = { x = 1, y = 0 }
	}, 20)
	add_kill_msg_to_hud((tool_image or "deathlist_tombstone.png") .. "^[resize:16x16", "items", {
		hud_elem_type = "image",
		position = hud_pos,
		scale = { x = 1, y = 1 },
		alignment = { x = 0, y = 0 }
	}, 0)
end

function add_environmental_kill_message(cause, victim)
	-- Falling & Unknown
	add_kill_message({ name = environmental_reasons[cause].name, color = environmental_reasons[cause].color }, environmental_reasons[cause].method, victim)
end

function add_node_kill_message(killing_node, cause, victim)
	-- Drowning & Node Damage
	local override = environmental_reasons[cause].nodes[killing_node.name] or {}
	local method = override.method or environmental_reasons[cause].method
	if method == "generate" then
		method = modlib.minetest.get_node_inventory_image(killing_node.name)
	end
	add_kill_message({ name = override.name or killing_node.description, color = override.color or environmental_reasons[cause].color }, method, victim)
end

function on_player_hpchange(player, hp_change, reason)
	local type = reason.type
	if type == "punch" then
		return
		-- punches are handled by on_punchplayer
	end
	if player:get_hp() > 0 and player:get_hp() + hp_change <= 0 then
		local victim = { name = player:get_player_name(), color = modlib.player.get_color_int(player) }
		if type == "set_hp" and reason.killer and reason.method then
			if reason.victim then
				victim.name = reason.victim.name or victim.name
				victim.color = reason.victim.color or victim.color
			end
			local killer = { name = reason.killer.name, color = reason.killer.color }
			if not killer.color then
				local killer_obj = minetest.get_player_by_name(killer.name)
				if killer_obj then killer.color = modlib.player.get_color_int(killer_obj) end
			end
			add_kill_message(killer, reason.method.image, victim)
			modlib.log.write("deathlist", "Player " .. killer.name .. " killed " .. victim.name .. " using " .. (reason.method.name or reason.method.image))
			return
		end
		if enable_environmental then
			if type == "fall" then
				add_environmental_kill_message("falling", victim)
				modlib.log.write("deathlist", "Player " .. victim.name .. " died due to falling")
				return
			end
			if type == "drown" then
				local eye_pos = vector.add(player:get_pos(), { x = 0, z = 0, y = player:get_properties().eye_height })
				local drowning_node = minetest.registered_nodes[minetest.get_node(eye_pos).name]
				add_node_kill_message(drowning_node, "drowning", victim)
				modlib.log.write("deathlist", "Player " .. victim.name .. " died due to drowning in " .. drowning_node.name)
				return
			end
			if type == "node_damage" then
				local killing_node_feet = minetest.registered_nodes[minetest.get_node(player:get_pos()).name]
				local eye_pos = vector.add(player:get_pos(), { x = 0, z = 0, y = player:get_properties().eye_height })
				local killing_node_head = minetest.registered_nodes[minetest.get_node(eye_pos).name]
				local killing_node = killing_node_feet
				if (killing_node_head.node_damage or 0) > (killing_node_feet.node_damage or 0) then killing_node = killing_node_head end
				add_node_kill_message(killing_node, "node_damage", victim)
				modlib.log.write("deathlist", "Player " .. victim.name .. " died due to node damage of " .. killing_node.name)
				return
			end
		end
		if enable_unknown then
			add_environmental_kill_message("unknown", victim)
			modlib.log.write("deathlist", "Player " .. victim.name .. " died for unknown reasons.")
		end
	end
end

function on_punchplayer(player, hitter, _time_from_last_punch, _tool_capabilities, _dir, damage)
	if player:get_hp() > 0 and player:get_hp() - damage <= 0 and hitter then
		local wielded_item_name = hitter:get_wielded_item():get_name()
		local tool
		if minetest.registered_nodes[wielded_item_name] then
			tool = modlib.minetest.get_node_inventory_image(wielded_item_name)
		else
			tool = (minetest.registered_items[wielded_item_name] or { inventory_image = "deathlist_gravestone.png" }).inventory_image
		end
		local killer = { name = hitter:get_player_name(), color = modlib.player.get_color_int(hitter) }
		local victim = { name = player:get_player_name(), color = modlib.player.get_color_int(player) }
		add_kill_message(killer, tool, victim)
		modlib.log.write("deathlist", "Player " .. killer.name .. " killed " .. victim.name .. " using " .. wielded_item_name)
	end
end

minetest.register_on_mods_loaded(function()
	minetest.register_on_player_hpchange(on_player_hpchange)
	minetest.register_on_punchplayer(on_punchplayer)
end)