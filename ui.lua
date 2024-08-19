Button = {
	buttons = {},
	text_alignment = {
		Center = 0,
		TopLeft = 1
	}
}
Font = {}



function Font:setup()
	self.small = love.graphics.newFont("assets/libertine/LinLibertine_R.ttf", 8)
	self.medium = love.graphics.newFont("assets/libertine/LinLibertine_R.ttf", 14)
	self.large = love.graphics.newFont("assets/libertine/LinLibertine_R.ttf", 30)
end

function Button:new(id, x, y, w, h, label, font, on_click, bg, fg)
	local result = {
		id = id,
		x = x or 0,
		y = y or 0,
		w = w or 100,
		h = h or 100,
		active = true,
		bg = bg or { 0, 0, 0, 1 },
		fg = fg or { 1, 1, 1, 1 },
		on_click = on_click,
	}
	--table.insert(Button.buttons, result)
	Button.buttons[id] = result
	result.label = Label:new("button_" .. id, result.x + w / 2, result.y + h / 2, font, label, result.fg,
		Button.text_alignment.Center)
	setmetatable(result, self)
	self.__index = self
	return result
end

function Button:draw()
	Draw.rect(self.x, self.y, self.w, self.h, self.bg)
end

function Button:set_text(text, alignment)
	local label = Label.labels["button_" .. self.id]
	label.text_obj:set(text)
	label:align(alignment)
end

function Button:try_press(x, y)
	if x < self.x or
		x > self.x + self.w or
		y < self.y or
		y > self.y + self.h then
		return
	end

	self.on_click()
end

Label = {
	labels = {}
}

function Label:align(alignment)
	if alignment then
		if alignment == Button.text_alignment.Center then
			self.x = self.x - self.text_obj:getWidth() / 2
			self.y = self.y - self.text_obj:getHeight() / 2
		end
	end
	self.x = math.floor(self.x)
	self.y = math.floor(self.y)
end

function Label:new(id, x, y, font, text, color, alignment)
	local text_obj = love.graphics.newText(font, text)
	local result = {
		x = x or 0,
		y = y or 0,
		text_obj = text_obj,
		color = color or { 1, 1, 1, 1 },
		font = font,
		visible = true,
	}
	Label.labels[id] = result
	setmetatable(result, self)
	self.__index = self

	result:align(alignment)

	return result
end

function Label:draw()
	if not self.visible then
		return
	end
	love.graphics.setColor(self.color)
	love.graphics.setFont(self.font)
	love.graphics.draw(self.text_obj, self.x, self.y)
end

Progress = {
	bars = {},
	Direction = {
		Vertical = 0,
		Horizontal = 1
	}
}

function Progress:new(id, value_func, x, y, length, thickness, outline, direction, bg, fg)
	local result = {
		value_func = value_func,
		x = x or 0,
		y = y or 0,
		length = length,
		thickness = thickness,
		outline = outline or 0,
		direction = direction or Progress.Direction.Horizontal,
		bg = bg or { 0, 0, 0, 1 },
		fg = fg or { 1, 1, 1, 1 },
		percentage = 0.0
	}
	Progress.bars[id] = result
	setmetatable(result, self)
	self.__index = self
	return result
end

function Progress:update()
	local values = self:value_func()
	self.x = values.x
	self.y = values.y
	self.percentage = values.percentage
end

function Progress:draw()
	love.graphics.setColor(self.bg)
	local length = self.percentage * self.length
	if self.direction == Progress.Direction.Horizontal then
		love.graphics.rectangle(
			"fill",
			self.x - self.outline / 2.0,
			self.y - self.outline / 2.0,
			self.length + self.outline,
			self.thickness + self.outline
		)
		love.graphics.setColor(self.fg)
		love.graphics.rectangle("fill", self.x, self.y, length, self.thickness)
		return
	end
	if self.direction == Progress.Direction.Vertical then
		love.graphics.rectangle(
			"fill",
			self.x - self.outline / 2.0,
			self.y - self.outline / 2.0,
			self.thickness + self.outline,
			self.length + self.outline
		)
		love.graphics.setColor(self.fg)
		love.graphics.rectangle("fill", self.x, (self.y + self.length) - length, self.thickness, length)
		return
	end
end
