require "ui"
require "common"

local drop_shadow_shader = [[

vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {
	return vec4(1.0, 0.0, 0.0, 1.0);
}

]]

Shaders = {
}

Debug = {}
function Debug.tprint(tbl, indent)
	if not indent then indent = 0 end
	local toprint = string.rep(" ", indent) .. "{\r\n"
	indent = indent + 2
	for k, v in pairs(tbl) do
		toprint = toprint .. string.rep(" ", indent)
		if (type(k) == "number") then
			toprint = toprint .. "[" .. k .. "] = "
		elseif (type(k) == "string") then
			toprint = toprint .. k .. "= "
		end
		if (type(v) == "number") then
			toprint = toprint .. v .. ",\r\n"
		elseif (type(v) == "string") then
			toprint = toprint .. "\"" .. v .. "\",\r\n"
		elseif (type(v) == "table") then
			toprint = toprint .. Debug.tprint(v, indent + 2) .. ",\r\n"
		else
			toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
		end
	end
	toprint = toprint .. string.rep(" ", indent - 2) .. "}"
	return toprint
end

GameState = {
	money = 1000,
	metal = 0,
	transported_metal = 0,

	metal_start = 100000,
	metal_left = 0,
	metal_required = 100000,

	miner_price = 100,
	builder_price = 200,
	transport_price = 300,
	ad_price = 500,

	miners = {},
	builders = {},
	transports = {},
	ads = {},

	metal_to_build = 5,
	metal_used = 0,
}

Road = {
	start = 100.0,
	finish = 500.0,
	height = 500.0
}

function GameState.Buy_ad()
	if GameState.money >= GameState.ad_price then
		Ad:new()
		GameState.money = GameState.money - GameState.ad_price
		GameState.ad_price = GameState.ad_price * 1.1
	end
end

function GameState.Buy_miner()
	if GameState.money >= GameState.miner_price then
		Miner:new()
		GameState.money = GameState.money - GameState.miner_price
		GameState.miner_price = GameState.miner_price * 1.1
	end
end

function GameState.Buy_builder()
	if GameState.money >= GameState.builder_price then
		Builder:new()
		GameState.money = GameState.money - GameState.builder_price
		GameState.builder_price = GameState.builder_price * 1.1
	end
end

function GameState.Buy_transport()
	if GameState.money >= GameState.transport_price then
		Transport:new()
		GameState.money = GameState.money - GameState.transport_price
		GameState.transport_price = GameState.transport_price * 1.1
	end
end

UI = {
	stats = {
		{
			label = "money",
			stat = function() return GameState.money end
		},
		-- {
		-- 	label = "metal",
		-- 	stat = function() return GameState.metal end
		-- },
		-- {
		-- 	label = "metal left",
		-- 	label_id = "metal_left",
		-- 	stat = function() return GameState.metal_left end
		-- },
		-- {
		-- 	label = "metal used",
		-- 	label_id = "metal_used",
		-- 	stat = function() return GameState.metal_used end
		-- },
		-- {
		-- 	label = "transported metal",
		-- 	label_id = "transported_metal",
		-- 	stat = function() return GameState.transported_metal end
		-- },
		-- {
		-- 	label = "miners",
		-- 	stat = function() return #GameState.miners end
		-- },
		-- {
		-- 	label = "builders",
		-- 	stat = function() return #GameState.builders end
		-- },
		-- {
		-- 	label = "transports",
		-- 	stat = function() return #GameState.transports end
		-- },
		-- {
		-- 	label = "progress",
		-- 	stat = function() return GameState.metal_used / GameState.metal_required end,
		-- }
	},

	buy_menu = {
		buy_miner = {
			func = GameState.Buy_miner,
			text = "Buy Miner",
			cost = function() return GameState.miner_price end
		},
		buy_builder = {
			func = GameState.Buy_builder,
			text = "Buy Builder",
			cost = function() return GameState.builder_price end
		},
		buy_transport = {
			func = GameState.Buy_transport,
			text = "Buy Transport",
			cost = function() return GameState.transport_price end
		},

		buy_ad = {
			func = GameState.Buy_ad,
			text = "Buy Ad",
			cost = function() return GameState.ad_price end
		},
	}
}

Miner = {
	cooldown = 3.0,
	mine_power = 10,
}
function Miner:new()
	local result = {
		current_cooldown = Miner.cooldown
	}
	table.insert(GameState.miners, result)
	setmetatable(result, self)
	self.__index = self
	return result
end

function Miner:update(dt)
	self.current_cooldown = self.current_cooldown - dt
	if self.current_cooldown <= 0 then
		self.current_cooldown = self.cooldown
		local metal_to_mine = math.clamp(0, Miner.mine_power, GameState.metal_left)
		GameState.metal = GameState.metal + metal_to_mine
		GameState.metal_left = GameState.metal_left - metal_to_mine
	end
end

Builder = {
	cooldown = 1.0,
}
function Builder:new()
	local result = {
		current_cooldown = Builder.cooldown
	}
	table.insert(GameState.builders, result)
	setmetatable(result, self)
	self.__index = self
	return result
end

function Builder:update(dt)
	self.current_cooldown = self.current_cooldown - dt
	local metal_to_use = math.min(GameState.transported_metal, GameState.metal_to_build)
	if metal_to_use <= 0 then
		return
	end
	if self.current_cooldown <= 0.0 then
		self.current_cooldown = self.cooldown
		GameState.metal_used = GameState.metal_used + metal_to_use
		GameState.transported_metal = GameState.transported_metal - metal_to_use
	end
end

Ad = {
	cooldown = 1.0,
	money = 100
}

function Ad:new()
	local result = {
		current_cooldown = Ad.cooldown
	}

	table.insert(GameState.ads, result)
	setmetatable(result, self)
	self.__index = self
	return result
end

function Ad:update(dt)
	self.current_cooldown = self.current_cooldown - dt

	if self.current_cooldown <= 0.0 then
		self.current_cooldown = self.cooldown
		GameState.money = GameState.money + Ad.money
	end
end

function Ad.draw()
	local ad_size = 10 * #GameState.ads
	Draw.line({
		400, 500 + ad_size,
		400, 500 - ad_size / 2
	}, { 0.2, 0.2, 0.2, 1.0 }, 4)

	Draw.rect(400 - ad_size / 2, 500 - ad_size / 2, ad_size, ad_size, {1, 0, 0, 1})
end

Transport = {
	speed = 30.0,
	fill_rate = 20,
	capacity = 100,

	size = 10,
	park_offset = 5,
	park_row_size = 5,

	to_slots = {},
	back_slots = {},

	State = {
		Filling = 0,
		Unloading = 1,
		DrivingTo = 2,
		DrivingBack = 3,
	}
}

function Transport:update_target_positions(is_to)
	local slots
	if is_to then
		slots = Transport.to_slots
	else
		slots = Transport.back_slots
	end
	slots[self.current_slot] = nil
	self.current_slot = self:find_first_empty_slot(is_to)
	slots[self.current_slot] = self

	local offset = self:get_offset_pos()
	print(Debug.tprint(self))

	self.start_pos.x = self.target_pos.x
	self.start_pos.y = self.target_pos.y

	if is_to then
		self.target_pos.x = Road.finish + offset.x
		self.target_pos.y = Road.height + offset.y
	else
		self.target_pos.x = Road.start + offset.x
		self.target_pos.y = Road.height + offset.y
	end
	Debug.tprint(self)
end

function Transport:new()
	local result = {
		progress = 0.0,
		load = 0.0,
		current_state = Transport.State.Filling,
		start_pos = { x = 0, y = 0 },
		target_pos = { x = 0, y = 0 },
		current_slot = 0
	}
	table.insert(GameState.transports, result)
	setmetatable(result, self)
	self.__index = self

	result.current_slot = self:find_first_empty_slot(false)
	local offset = result:get_offset_pos()
	result.start_pos.x = Road.start + offset.x
	result.start_pos.y = Road.height + offset.y
	result.target_pos.x = result.start_pos.x
	result.target_pos.y = result.start_pos.y
	result:update_target_positions(false)

	Progress:new(
		"transport_" .. #GameState.transports,
		function()
			local pos = result:get_position()
			return {
				percentage = result.load / self.capacity,
				x = pos.x,
				y = pos.y - 10.0
			}
		end,
		result.start_pos.x,
		result.start_pos.y,
		6,
		3,
		0,
		Progress.Direction.Horizontal,
		{ 0, 0, 0, 1 },
		{ 1, 1, 1, 1 }
	)
	return result
end

function Transport:find_first_empty_slot(is_to)
	local slots
	if is_to then
		slots = Transport.to_slots
	else
		slots = Transport.back_slots
	end
	for i = 1, #GameState.transports do
		if slots[i] == nil then
			return i
		end
	end
end

function Transport:get_offset_pos()
	local shift_amount = self.current_slot

	local col = shift_amount % Transport.park_row_size
	local row = math.floor(shift_amount / Transport.park_row_size)
	print(shift_amount, col, row)
	return {
		x = col * (Transport.size + Transport.park_offset),
		y = row * (Transport.size + Transport.park_offset),
	}
end

function Transport:update(dt)
	if self.current_state == Transport.State.Filling then
		local space_left = self.capacity - self.load
		local metal_to_move = math.clamp(0.0, dt * Transport.fill_rate, space_left)
		metal_to_move = math.min(GameState.metal, metal_to_move)
		self.load = self.load + metal_to_move
		GameState.metal = GameState.metal - metal_to_move

		if self.load >= Transport.capacity or
			(GameState.metal <= 0 and GameState.metal_left <= 0 and self.current_state == Transport.State.Filling) then
			self.current_state = Transport.State.DrivingTo
			self:update_target_positions(true)
			self.progress = 0.0
		end
		return
	end
	if self.current_state == Transport.State.Unloading then
		local metal_to_move = math.min(dt * Transport.fill_rate, self.load)
		self.load = self.load - metal_to_move
		GameState.transported_metal = GameState.transported_metal + metal_to_move

		if self.load <= 0 and (GameState.metal_left > 0 or GameState.metal > 0) then
			self.current_state = Transport.State.DrivingBack
			self:update_target_positions(false)
			self.progress = 0.0
		end
		return
	end
	if self.current_state == Transport.State.DrivingTo then
		self.progress = self.progress + (Transport.speed / 100.0) * dt
		self.progress = math.clamp(0, self.progress, 1.0)
		if self.progress >= 1.0 then
			self.current_state = Transport.State.Unloading
		end
		return
	end
	if self.current_state == Transport.State.DrivingBack then
		self.progress = math.clamp(0.0, self.progress, 1.0)
		self.progress = self.progress + (Transport.speed / 100.0) * dt
		if self.progress >= 1.0 then
			self.current_state = Transport.State.Filling
		end
	end
end

function Transport:get_position()
	return {
		x = ((self.target_pos.x - self.start_pos.x) * self.progress) + self.start_pos.x,
		y = ((self.target_pos.y - self.start_pos.y) * self.progress) + self.start_pos.y,
	}
end

function Transport:draw()
	local position = self:get_position()
	Draw.rect(position.x, position.y, Transport.size, Transport.size, { 0.6, 0.6, 0.6, 1.0 })
end

function Load_UI()
	local index = 0
	for k, v in pairs(UI.buy_menu) do
		Button:new(k, 100 + 150 * index, 40, 100, 64, v.text .. '\nPrice: ' .. v.cost(), Font.medium, v.func)
		index = index + 1
	end

	index = 0
	for _, v in pairs(UI.stats) do
		Label:new((v.label_id or v.label), 10, 32 * index, v.font or Font.large, v.label .. ": " .. v.stat())
		index = index + 1
	end
end

function love.load()
	Font:setup()
	Load_UI()

	Shaders.drop_shadow = love.graphics.newShader(drop_shadow_shader)

	GameState.metal_left = GameState.metal_start

	local width, height = love.graphics.getDimensions()
	local label = Label:new("win_screen", width / 2, height / 2, Font.large, "You win!", { 1, 1, 1, 1 })
	label.visible = false

	-- for i = 1, 200 do
	-- 	GameState.Buy_miner()
	-- end
	-- for i = 1, 100 do
	-- 	GameState.Buy_builder()
	-- 	GameState.Buy_transport()
	-- end
end

function love.mousepressed(x, y, mouse_button)
	if mouse_button ~= 1 then
		return
	end

	for _, v in pairs(Button.buttons) do
		v:try_press(x, y)
	end
end

function love.update(dt)
	for _, v in ipairs(UI.stats) do
		local to_print = string.format("%.2f", v.stat())
		local label_id = v.label_id or v.label
		Label.labels[label_id].text_obj:set(v.label .. ": " .. to_print)
	end

	for k, v in pairs(UI.buy_menu) do
		local price = string.format("%.0f", v.cost())
		Button.buttons[k]:set_text(v.text .. '\nPrice: ' .. price)
	end

	for _, v in pairs(GameState.miners) do
		v:update(dt)
	end
	for _, v in pairs(GameState.builders) do
		v:update(dt)
	end
	for _, v in pairs(GameState.transports) do
		v:update(dt)
	end
	for _, v in pairs(GameState.ads) do
		v:update(dt)
	end
	for _, v in pairs(Progress.bars) do
		v:update(dt)
	end

	local progress = GameState.metal_used / GameState.metal_required
	if progress >= 0.9999 then
		Label.labels.win_screen.visible = true
	end
end

Draw = {}

function Draw.rect(x, y, w, h, color)
	love.graphics.setColor({ 0.3, 0.3, 0.3, 1.0 })
	love.graphics.rectangle("fill", x + 2.0, y + 2.0, w, h)
	love.graphics.setColor(color)
	love.graphics.rectangle("fill", x, y, w, h)
end

function Draw.polygon(polygons, color)
	local shadow = {}
	for k, v in pairs(polygons) do
		shadow[k] = v + 2.0
	end
	love.graphics.setColor({ 0.3, 0.3, 0.3, 1.0 })
	love.graphics.polygon("fill", shadow)

	love.graphics.setColor(color)
	love.graphics.polygon("fill", polygons)
end

function Draw.line(line, color, width)
	local shadow = {}
	for k, v in pairs(line) do
		shadow[k] = v + 2.0
	end

	love.graphics.setColor({ 0.3, 0.3, 0.3, 1.0 })
	love.graphics.setLineWidth(width)
	love.graphics.line(shadow)

	love.graphics.setColor(color)
	love.graphics.line(line)
end

function Draw_mountains()
	local from_mountain = {
		100, 500,
		300, 500,
		200, 100 + (1 - (GameState.metal_left / GameState.metal_start)) * 400
	}

	local to_mountain = {
		500, 500,
		700, 500,
		600, 100
	}
	love.graphics.setColor({ 0.7, 0.7, 0.7, 1.0 })

	Draw.polygon(from_mountain, { 0.7, 0.7, 0.7, 1.0 })
	Draw.polygon(to_mountain, { 0.7, 0.7, 0.7, 1.0 })
	--love.graphics.polygon("fill", from_mountain)
	--love.graphics.polygon("fill", to_mountain)
end

function Draw_metal_pile(amount, position)
	--metal pile
	local metal_to_draw = math.floor(amount / 10)
	local row_size = 40
	local square_size = 2
	local spacing = 1
	local metal_pile_pos = position
	local metal_color = { 0.6, 0.6, 0.6, 1 }
	for i = 1, metal_to_draw do
		local col = (i - 1) % row_size
		local row = math.floor((i - 1) / row_size)
		Draw.rect(metal_pile_pos[1] + col * (square_size + spacing),
			metal_pile_pos[2] - row * (square_size + spacing),
			square_size,
			square_size,
			metal_color)
	end
end

function love.draw()
	love.graphics.clear(99 / 255, 155 / 255, 255 / 255, 1)

	Draw.rect(0, 450, 1000, 1000, { 0, 0.5, 0, 1 })

	Draw_mountains()
	Draw_metal_pile(GameState.metal, { 30, 450 })
	Draw_metal_pile(GameState.transported_metal, { 500, 450 })

	Ad.draw()

	--escalator
	local progress = GameState.metal_used / GameState.metal_required
	Draw.line({
		530, 500,
		600, 100 + (400 - progress * 400)
	}, { 0.2, 0.2, 0.2, 1.0 }, 4)



	--love.graphics.setShader(Shaders.drop_shadow)
	for _, v in pairs(GameState.transports) do
		v:draw()
		--local transport_table = Debug.tprint(v)
		--love.graphics.print(transport_table, 400, 400)
	end
	--love.graphics.setShader(Shaders.drop_shadow)

	for _, v in pairs(Button.buttons) do
		v:draw()
	end

	for _, v in pairs(Progress.bars) do
		v:draw()
	end

	for _, v in pairs(Label.labels) do
		v:draw()
	end
end
