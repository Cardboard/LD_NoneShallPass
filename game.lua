-- collision detector with a poorly-chosen name
local HC = require("lib/HardonCollider")
-- hump gamestate crap
Gamestate.game = Gamestate.new()
local state = Gamestate.game
-- animation library
require("lib/AnAl")
-- the knight class (for the player and 'enemy' knights)
require("knight")

function state:init()
	self:load()
end


function state:load()
	-- start music
	music = love.audio.newSource("audio/bgm.ogg")
	music:setVolume(0.5)
	music:setLooping(true)
	music:play()
	-- setup sfx
	clash = love.audio.newSource("audio/clash.ogg", "static")
	clash:setVolume(0.9)
	knightHit = love.audio.newSource("audio/knightHit.ogg", "static")
	playerHit = love.audio.newSource("audio/playerHit.ogg", "static")
	knightSwing = love.audio.newSource("audio/knightSwing.ogg", "static")
	playerSwing = love.audio.newSource("audio/playerSwing.ogg", "static")
	--death = love.audio.newSource("audio/death.ogg", "static")

	-- set gravity constant
	gravity = 9.8

	-- load collider, set size, and set callback
	Collider = HC(100, on_collide, stop_collide)

	-- store the level's dimensions and stuff and create a floor HC object
	Floor = {}
	Floor.y = 500
	Floor.coords = { 0, Floor.y, window.width, window.height - Floor.y }
	Floor.obj = Collider:addRectangle(Floor.coords[1], Floor.coords[2], Floor.coords[3], Floor.coords[4])
	Floor.image = love.graphics.newImage("img/floor.png")

	-- create player and modify default variables
	Player = Knight:new()
	Player.x = 850
	Player.y = 300
	-- HEIGHT AND WIDTH MUST BE MANUALLY SET
	Player.width = 100
	Player.height = 200
	-- animations
	Player.idle = newAnimation(love.graphics.newImage("img/player_idle.png"), Player.width, Player.height, 0, 0)
	Player.run = newAnimation(love.graphics.newImage("img/player_run.png"), Player.width, Player.height, 0.1, 0)
	Player.jumping = newAnimation(love.graphics.newImage("img/player_jump.png"), Player.width, Player.height, 0, 0)
	Player.anim = Player.idle
	-- not animations

	Player.sword["image"] = love.graphics.newImage("img/sword.png")
	Player.sword["width"] = Player.sword["image"]:getWidth()
	Player.sword["height"] = Player.sword["image"]:getHeight()
	Player:collisionObject(Collider, "player")

	-- create table to hold good knights
	GoodKnights = {}

	-- set starting health
	Player.totalHealth = 10
	Player.health = 10

	-- set starting message
	message = ""

	-- endImage is changed when the game is beaten
	endImage = nil

	-- set starting wave number and starting score
	wave = 0
	kills = 0
end

function state:update(dt)
	-- update collisions
	Collider:update(dt)
	-- update the timer
	Timer.update(dt)

	-- spawn enemies depending on the current wave, and change the wave based on kills
	waveSystem()
	killsSystem()

	-- check for any dead knights, including the player
	checkGameOver(Collider)

	-- update the good knights
	updateKnights(GoodKnights, dt)

	-- update the player
	if love.keyboard.isDown("left") then Player:moveLeft(dt) end
	if love.keyboard.isDown("right") then Player:moveRight(dt) end
	if love.keyboard.isDown("up") then Player:jump() end
	if love.keyboard.isDown(" ") then Player:startSwing(dt) end
	if love.keyboard.isDown("1") then
		createKnight(GoodKnights, "coward")
		endImage = nil
	end
	if love.keyboard.isDown("2") then
		createKnight(GoodKnights, "brave") 
		endImage = nil
	end
	if love.keyboard.isDown("3") then
		createKnight(GoodKnights, "heroic")
		endImage = nil
	end
	Player:gravity(dt)
	Player:update(dt)
	Player:swing(dt)

	-- quit the game
	if love.keyboard.isDown("escape") then love.event.push("quit") end
end

function state:draw()
	-- draw the level
	love.graphics.draw(Floor.image, 0, Floor.y - 120)

	-- draw the knights
	drawKnights(GoodKnights)

	-- draw the player
	Player:draw()

	-- draw speech
	speech(Player, message)

	-- print the score
	love.graphics.setColorMode("modulate")
	love.graphics.setColor(colors.BLACK)
	love.graphics.print("WAVE: "..wave..", KILLS: "..kills, 5, 5)
	love.graphics.setColorMode("replace")

	-- draw the endgame image if game is over
	if endImage ~= nil then	love.graphics.draw(endImage, 0, 0) end

	-- print debuggin' crap
	--[[
	love.graphics.setColorMode("modulate")
	love.graphics.setColor(colors.BLACK)
	love.graphics.print("end1: "..Player.sword["end1"].."end2: "..Player.sword["end2"].." time: "..os.clock(), 0, 0)
	love.graphics.setColorMode("replace")
	]]--
end

-------------------------------------------------------------------------------

function createKnight(knights_table, knight_type)
	local knight
	knight = Knight:new()
	knight.height = 200
	knight.width = 100
	knight.x = -200
	knight.y = 300
	-- animations
	knight.idle = newAnimation(love.graphics.newImage("img/"..knight_type.."_idle.png"), knight.width, knight.height, 0, 0)
	knight.run = newAnimation(love.graphics.newImage("img/"..knight_type.."_run.png"), knight.width, knight.height, 0.1, 0)
	knight.jumping = newAnimation(love.graphics.newImage("img/"..knight_type.."_jump.png"), knight.width, knight.height, 0, 0)
	knight.anim = knight.idle
	knight.xvel_max = 2
	knight.sword["image"] = love.graphics.newImage("img/sword.png")
	knight.sword["width"] = knight.sword["image"]:getWidth()
	knight.sword["height"] = knight.sword["image"]:getHeight()
	knight.direction = -1
	knight:collisionObject(Collider, "goodknights")
	-- AI related properties
	knight.type = knight_type
	knight.backupEnd = nil
	knight.pauseEnd = nil
	knight.paused = false
	if knight.type == "coward" then
		knight.runSpeed = 6
		knight.backupDist = 300
		knight.backupTime = 4
		knight.normalDist = 100
		knight.moveDist = 100
		knight.attackDist = 200	
	end
	if knight.type == "brave" then
		knight.totalHealth = 3
		knight.health = 3
		knight.runSpeed = 4
		knight.backupDist = 200
		knight.backupTime = 2
		knight.normalDist = 150
		knight.moveDist = 150
		knight.attackDist = 225
	end
	if knight.type == "heroic" then
		knight.totalHealth = 4
		knight.health = 4
		knight.runSpeed = 3
		knight.backupDist = 250
		knight.backupTime = 0.5
		knight.normalDist = 200
		knight.moveDist = 200
		knight.attackDist = 250
	end

	table.insert(knights_table, knight)
end

-- update all of the good knights
function updateKnights(knights_table, dt)
	if GoodKnights ~= nil then
		for i,v in ipairs(knights_table) do
			-- retreat if player moves off screen
			if Player.x > window.width and v.x > -v.width*2 then
				v:moveLeft(dt*2)
			end
			-- COWARD
			if v.type == "coward" then
				-- left and right movement
				if v.x <= Player.x - v.moveDist then
						v:moveRight(dt)
				elseif v.x >= Player.x - v.moveDist then
					v:moveLeft(dt)
				end
				-- jump if the player jumps
				if Player.canJump == false then
					Timer.add(0.5, function() v:jump() end)
				end
				-- swing the sword if near the player
				if (Player.x - v.x) <= v.attackDist then
					if v.paused == false then
						v:startSwing(dt)
						v:startPause(2)
					end
					v:startBackUp(v.backupTime)
				end 
			end 
			if v.type == "brave" then
				-- left and right movement
				if v.x <= Player.x - v.moveDist then 
					v:moveRight(dt)
				elseif v.x >= Player.x - v.moveDist then
					v:moveLeft(dt)
				end
				-- jump if the player jumps
				if Player.canJump == false then
					Timer.add(0.5, function() v:jump() end)
				end
				-- swing if the player swings
				if Player.canSwing == false then
					if v.paused == false and (Player.x - v.x) <= v.attackDist+200 then
						Timer.add(0.2, function() v:startSwing(dt) end)
					end
				end
				-- swing the sword if near the player
				if (Player.x - v.x) <= v.attackDist then
					if v.paused == false then
						v:startSwing(dt)
						v:startPause(1)
					end
					v:startBackUp(v.backupTime)
				end  
			end
			if v.type == "heroic" then
				-- left and right movement
				if v.x <= Player.x - v.moveDist then 
					v:moveRight(dt)
				elseif v.x >= Player.x - v.moveDist then
					v:moveLeft(dt)
				end
				-- jump if the player jumps
				if Player.canJump == false then
					Timer.add(0.5, function() v:jump() end)
				end
				-- swing if the player swings
				if Player.canSwing == false then
					if v.paused == false and (Player.x - v.x) <= v.attackDist+100 then
						Timer.add(0.2, function() v:startSwing(dt) end)
					end
				end
				-- swing the sword if near the player
				if (Player.x - v.x) <= v.attackDist then
					if v.paused == false then
						v:startSwing(dt)
						v:startPause(0.7)
					end
					v:startBackUp(v.backupTime)
				end  
			end
			v:backUp()	
			v:pause()	

			-- update gravity and stuff
			v:gravity(dt)
			v:update(dt)
			v:swing(dt)
		end
	end
end

-- draw all good knights
function drawKnights(knights_table)
	if GoodKnights ~= nil then
		for i,v in ipairs(knights_table) do
			--love.graphics.draw(v.image, v.x, v.y)
			v:draw()
		end
	end
end

-- collision callback
function on_collide(dt, shape_a, shape_b)

	for i,v in ipairs(GoodKnights) do
		if Player.sword["obj"]:collidesWith(v.sword["obj"]) then
			if os.clock() < Player.sword["end1"] and os.clock() < v.sword["end1"] then
				Player:reset()
				v:reset()
				v:startPause(1)
				-- make a clash sound
				clash:play()
			elseif os.clock() < Player.sword["end1"] and os.clock() > v.sword["end1"] then
				Player:reset()
				v:reset()
				v.health = v.health - 1
				knightHit:play()
			elseif os.clock() > Player.sword["end1"] and os.clock() < v.sword["end1"] then
				Player:reset()
				v:reset()
				Player.health = Player.health - 1
				playerHit:play()
			end
		end
	end

end

function stop_collide(dt, shape_a, shape_b)
end

function speech(knight, text)
	local offsetx, offsety = 10, 10
	local chars = 200
	local textx, texty = (knight.x + knight.width + offsetx*(3/2)), (knight.y - offsety/2)
	local wrap, lines = font:getWrap(text, chars)
	local textHeight = font:getHeight() * lines
	local bubble = {
		x = knight.x + knight.width + offsetx,
		y = knight.y - offsety,
		width = wrap + offsetx/2,
		height = textHeight + offsety
	}

	love.graphics.setColor(colors.GRAY)
	if text ~= "" then
		if knight.x + knight.width + bubble.width + offsetx >= window.width then
			love.graphics.rectangle("fill", bubble.x - (bubble.width + knight.width + 2*offsetx), bubble.y, bubble.width, bubble.height)
			love.graphics.printf(text, textx - (bubble.width + knight.width + 2*offsetx), texty, chars, "left")
		else
			love.graphics.rectangle("fill", bubble.x, bubble.y, bubble.width, bubble.height)
			love.graphics.printf(text, textx, texty, chars, "left")
		end
	end
end

function checkGameOver(collider)
	if GoodKnights ~= nil then
		for i,v in ipairs(GoodKnights) do
			if v.health == 0 then
				-- remove the knight and his sword from the HC
				collider:remove(v.sword["obj"], v.obj)
				-- remove the knight from the knights group
				GoodKnights[i] = nil
				table.remove(GoodKnights, i)
				kills = kills + 1
			end
		end
	end
	if Player.health == 0 then
		-- game over, go back to menu
		love.audio.stop()
		Gamestate.menu:load()
		Gamestate.switch(Gamestate.menu)
	end
	if Player.heatlh == 7 then
		message = "Tis but a scratch!"
	elseif Player.health == 6 then
		message = "I've had worse!"
	elseif Player.health == 5 then
		message = "Come on you pansy!"
	elseif Player.health == 4 then
		message = "Just a flesh wound!"
	elseif Player.health == 3 then
		message = "I'll do you for that!"
	elseif Player.health == 2 then
		message = "The Black Knight Always triumphs!"
	elseif Player.health == 1 then
		message = "I'M INVINCIBLE!"
	end

	Player.health = math.max( Player.health, 0 )
end

function waveSystem()
	if wave == 0 then
		if #GoodKnights == 0 then
			createKnight(GoodKnights, "coward")
		end
	elseif wave == 1 then
		if #GoodKnights == 0 then
			if kills > 8 then
				createKnight(GoodKnights, "brave")
			else
				createKnight(GoodKnights, "coward")
			end
		end
	elseif wave == 2 then
		if #GoodKnights == 0 then
			if kills > 17 then
				createKnight(GoodKnights, "heroic")
			elseif kills > 14 then
				createKnight(GoodKnights, "brave")
			else
				createKnight(GoodKnights, "coward")
			end
		end
	elseif wave == 3 then
		if #GoodKnights == 0 then
			if kills > 40 then
				createKnight(GoodKnights, "coward")
			elseif kills > 30 then
				createKnight(GoodKnights, "heroic")
			elseif kills > 20 then
				createKnight(GoodKnights, "brave")
			end
		end
		if #GoodKnights == 1 then
			if kills > 40 then
				createKnight(GoodKnights, "coward")
			end
		end
	elseif wave == 4 then
		if #GoodKnights == 0 then
			if kills > 70 then
				createKnight(GoodKnights, "brave")
			elseif kills > 60 then
				createKnight(GoodKnights, "heroic")
			else
				createKnight(GoodKnights, "coward")
			end
		end
		if #GoodKnights == 1 then
			if kills > 70 then
				createKnight(GoodKnights, "coward")
			elseif kills <= 60 then
				createKnight(GoodKnights, "coward")
			end
		end
	elseif wave == 5 then
		if #GoodKnights == 0 then
			if kills > 95 then
				createKnight(GoodKnights, "coward")
			elseif kills > 85 then
				createKnight(GoodKnights, "coward")
			else
				createKnight(GoodKnights, "heroic")
			end
		end
		if #GoodKnights == 1 then
			if kills > 95 then
				createKnight(GoodKnights, "coward")
			elseif kills > 85 then
				createKnight(GoodKnights, "coward")
			else
				createKnight(GoodKnights, "coward")
			end
		end
		if #GoodKnights == 2 then
			if kills > 95 then
				createKnight(GoodKnights, "brave")
			elseif kills > 85 then
				createKnight(GoodKnights, "coward")
			end
		end
	elseif wave == 6 then
		if #GoodKnights == 0 then
			if kills > 144 then
				createKnight(GoodKnights, "heroic")
			elseif kills > 130 then
				createKnight(GoodKnights, "brave")
			else
				createKnight(GoodKnights, "coward")
			end
		end
		if #GoodKnights == 1 then
			if kills > 144 then
				createKnight(GoodKnights, "heroic")
			elseif kills > 130 then
				createKnight(GoodKnights, "brave")
			else
				createKnight(GoodKnights, "brave")
			end
		end
		if #GoodKnights == 2 then
			if kills > 144 then
				createKnight(GoodKnights, "heroic")
			elseif kills > 130 then
				createKnight(GoodKnights, "brave")
			else
				createKnight(GoodKnights, "brave")
			end
		end
	end
end

function killsSystem()
	if kills == 5 then
		wave = 1
	elseif kills == 10 then
		wave = 2
	elseif kills == 20 then
		wave = 3
	elseif kills == 50 then
		wave = 4
	elseif kills == 75 then
		wave = 5
	elseif kills == 100 then
		wave = 6
	elseif kills == 150 then
		wave = 7
		-- ggwp
		endImage = love.graphics.newImage("img/gg.png")
	end
end