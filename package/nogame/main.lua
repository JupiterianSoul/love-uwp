local lines = {}
local font

local function build()
	local h = love.graphics.getHeight()
	font = love.graphics.newFont(math.max(16, math.floor(h / 36)))
	local folder = love.filesystem.getAppdataDirectory()
	lines = {
		"No game found",
		"",
		"Copy your game.love into this app's LocalState folder:",
		folder,
		"",
		"On Xbox: Device Portal > File explorer > LocalAppData > (this app) > LocalState",
		"Then start the app again.",
	}
end

function love.load()
	love.graphics.setBackgroundColor(0.15, 0.13, 0.2)
	build()
end

function love.resize()
	build()
end

function love.draw()
	local w, h = love.graphics.getDimensions()
	local margin = math.floor(w * 0.1)
	local width = w - margin * 2
	local total = 0
	for _, line in ipairs(lines) do
		local _, wrapped = font:getWrap(line, width)
		total = total + math.max(1, #wrapped) * font:getHeight()
	end
	love.graphics.setFont(font)
	love.graphics.setColor(1, 1, 1)
	local y = math.floor((h - total) / 2)
	for _, line in ipairs(lines) do
		local _, wrapped = font:getWrap(line, width)
		love.graphics.printf(line, margin, y, width, "center")
		y = y + math.max(1, #wrapped) * font:getHeight()
	end
end
