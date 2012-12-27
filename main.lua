-- hump stuff
Gamestate = require("lib/hump.Gamestate")
Timer = require("lib/hump.Timer")
-- animation library
require("lib/AnAl")
-- require gamestate files
require("menu")
require("game")

function love.load()
	-- set up a font to use
	font = love.graphics.newFont(16)
	love.graphics.setFont(font)
	-- initiate gamestate or something
	Gamestate.registerEvents()
	Gamestate.switch(Gamestate.menu)
	-- set up a bunch of colors for who knows what
	colors = {
		WHITE = {255,255,255},
		BLACK = {0,0,0},
		GRAY = {128, 128, 128},
		RED = {200, 0, 0},
		GREEN = {0, 200, 0},
		floor = {204, 255, 51},
		sky = {229, 249, 255}
	}
	-- set background color and color mode
	love.graphics.setBackgroundColor(colors.sky)
	love.graphics.setColorMode("replace")
end

function love.update(dt)
end

function love.draw()
end