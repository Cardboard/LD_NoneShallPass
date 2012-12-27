-- hump gamestate crap
Gamestate.menu = Gamestate.new()
local state = Gamestate.menu

function state:init()
	self:load()
end


function state:load()
	menuImage = love.graphics.newImage("img/menu.png")

	menuMusic = love.audio.newSource("audio/menubgm.ogg")
	menuMusic:setVolume(0.5)
	menuMusic:setLooping(true)
	menuMusic:play()
end

function state:update(dt)
	if love.keyboard.isDown(" ") then
		-- stop menu music
		menuMusic:stop()
		-- start the game
		Gamestate.game:load()
		Gamestate.switch(Gamestate.game)
	end
	if love.keyboard.isDown("escape") then
		love.event.push("quit")
	end
end

function state:draw()
	love.graphics.draw(menuImage, 0 ,0)
end