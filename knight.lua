Knight = {}
Knight.sword = {}

function Knight:new()
	local object = {
		-- set starting values
		x = 0,
		y = 0,
		-- image vars
		idle = "",
		run = "",
		jumping = "",
		-- holds current animation
		anim = "",
		width = 0,
		height = 0,
		xvel = 0,
		xvel_max = 3,
		yvel_max = 5,
		yvel = 0,
		runSpeed = 5,
		jumpSpeed = -5,
		canJump = false,
		canSwing = true,
		direction = 1, -- can set to -1 so that goodknights' face and swing the correct way
		obj = nil,
		totalHealth = 1,
		health = 1,

		sword = {
			x = 0,
			y = 0,
			image = "",
			width = 32,
			height = 256,
			end1 = 0,
			end2 = 0,
			rotate = 0,
			obj = nil
		}
	}
	setmetatable(object, { __index = Knight} )
	return object
end


function Knight:collisionObject(collider, group)
	self.obj = collider:addRectangle(self.x, self.y, self.width, self.height)
	self.sword["obj"] = collider:addRectangle(self.sword["x"], self.sword["y"], self.sword["width"], self.sword["height"])
	collider:addToGroup(group, self.obj, self.sword["obj"])
	collider:addToGroup(tostring(group.."andfloor"), self.obj, Floor.obj)
end

function Knight:load()
end

function Knight:update(dt)
	-- get current x and y for drawing images/animations over the collider objects
	local x, y = self.obj:center()
	self.x = x - self.width/2
	self.y = y - self.height/2
	-- update position of the sword
	local swordx, swordy = ( self.sword["height"] * math.sin(self.sword["obj"]:rotation()) ), ( self.sword["height"] * math.cos(self.sword["obj"]:rotation()) ) 
	if self.sword["end1"] ~= 0 then
		self.sword["x"] = (x) + swordx/2
		self.sword["y"] = (y) - swordy/2
		self.sword["obj"]:moveTo(self.sword["x"], self.sword["y"])
	else
		self.sword["x"] = (x)
		self.sword["y"] = (y) - swordy/2
		self.sword["obj"]:moveTo(self.sword["x"], self.sword["y"])
	end

	-- change animation based on current state
	-- airborne!
	if self.yvel > 0 or self.yvel < 0 then
		self.anim = self.jumping
	else
		-- idle
		if self.xvel >= -0.05 or self.xvel <= 0.05 then
			self.anim = self.idle
		end
		-- running
		if self.xvel < -0.05 or self.xvel > 0.05 then
			self.anim = self.run
		end
	end
	-- 
	-- update the animation
	self.anim:update(dt)

end

function Knight:draw()
	-- draw the knight
	self.anim:draw(self.x, self.y)
	-- draw the sword
	local x, y = self.obj:center()
	local swordx, swordy = ( self.sword["height"] * math.sin(self.sword["obj"]:rotation()) ), ( self.sword["height"] * math.cos(self.sword["obj"]:rotation()) ) 
	love.graphics.draw(self.sword["image"],
					(x) - self.sword["width"]/2 + swordx,
					(y) - swordy,
					self.sword["obj"]:rotation())
	-- draw the health bar
	love.graphics.setColor(colors.RED)
	love.graphics.rectangle("fill", (self.x + self.width * (3/2)), self.y, 
							10, self.height)
	-- draw remaining health on health bar
	love.graphics.setColor(colors.GREEN)
	love.graphics.rectangle("fill", (self.x + self.width * (3/2)), self.y, 
							10, self.height * (self.health / self.totalHealth))
end

function Knight:gravity(dt)
	self.yvel = self.yvel + gravity*dt
	-- stop the knight when they reach the floor and set 'canJump' to true
	if self.y >= (Floor.y - self.height) then
		self.yvel = 0
		self.obj:moveTo( (self.x + self.width/2), (Floor.y - self.height/2) )
		self.canJump = true
	end
	-- restrict y velocity
	if self.yvel >= 0 then self.yvel = math.min(self.yvel, self.yvel_max) end
	if self.yvel <= 0 then self.yvel = math.max(self.yvel, -self.yvel_max) end

	-- keep knight on the screen horizontally
	if self.x >= (window.width - self.width) then
		self.x = (window.width - self.width)
	end
	if self.x <= 0 then self.x = 0 end
	-- restrict x velocity
	if self.xvel >= 0 then self.xvel = math.min(self.xvel, self.xvel_max) end
	if self.xvel <= 0 then self.xvel = math.max(self.xvel, -self.xvel_max) end
	-- slowly decrease (relative to direction)
	if self.xvel > 0 then self.xvel = self.xvel - 2*dt end
	if self.xvel < 0 then self.xvel = self.xvel + 2*dt end
	
	-- update position
	self.obj:move(self.xvel, self.yvel)
	self.sword["obj"]:move(self.xvel, self.yvel)
	-- update sword rotation
	self.sword["obj"]:rotate(self.direction * self.sword["rotate"])
end

function Knight:moveLeft(dt)
	self.xvel = self.xvel - self.runSpeed*dt
end

function Knight:moveRight(dt)
	self.xvel = self.xvel + self.runSpeed*dt
end

function Knight:jump()
	if self.canJump == true then
		self.y = self.y - 0.01 -- for some reason the knight must be moved slightly upwards before jumping
		self.yvel = self.jumpSpeed
		self.canJump = false
	end
end

function Knight:swing(dt)
	-- if time left for swing
	if os.clock() < self.sword["end1"] then
		self.sword["rotate"] = -0.03
	end
	if os.clock() > self.sword["end1"] and os.clock() < self.sword["end2"] then
		self.sword["rotate"] = 0.03
	end
	if os.clock() > self.sword["end2"] then
		self.sword["rotate"] = 0
		self.sword["obj"]:setRotation(0)
		self.sword["end1"], self.sword["end2"] = 0, 0
		self.canSwing = true
	end
end

function Knight:reset()
	self.sword["rotate"] = 0
	self.sword["obj"]:setRotation(0)
	self.sword["end1"], self.sword["end2"] = 0, 0
	self.canSwing = true
end


function Knight:startSwing(dt)
	if self.canSwing == true then
		if self.sword["end1"] == 0 then
			self.sword["end1"] = os.clock() + 1
			self.sword["end2"] = self.sword["end1"] + 1
		end
		self.canSwing = false
		self:startPause(1)
	end
end

function Knight:startPause(time)
	-- if no timer has been set
	if self.pauseEnd == nil then
		self.pauseEnd = os.clock() + time
		--print("paused")
	end
end

function Knight:pause()
	if self.pauseEnd ~= nil then
		if os.clock() < self.pauseEnd then
			self.paused = true
		end
		if os.clock() > self.pauseEnd then
			self.paused = false
			self.pauseEnd = nil
			--print("UNpaused")
		end
	end
end

function Knight:startBackUp(time)
	-- if no timer has been set
	if self.moveEnd == nil then
		self.moveEnd = os.clock() + time
	end
end

function Knight:backUp()
	if self.moveEnd ~= nil then
		if os.clock() < self.moveEnd then
			self.moveDist = self.backupDist
		end
		if os.clock() > self.moveEnd then
			self.moveDist = self.normalDist
			self.moveEnd = nil
			return
		end
	end
end