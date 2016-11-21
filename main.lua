-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Final project requirements:
--
-- Physics:
-- Bodies: at least 2 different types (e.g. static, dynamic) and 2 different shapes 
-- (e.g. rectangular, circular)
-- Collision event detection and actions (at least 2 different ones)
-- Joints (at least 3 different types)
--
-- Animation
-- Sprite animation or use of image sheets
-- Changing text display (e.g. score readout)
--
-- Touch and Input:
-- Touch events (touch or tap)
--
-- Sound:
-- Sound effects (at least 3 different ones)
-- Background music with an on/off switch or volume slider
-- 
-- Multiple Views:
-- Composer multiscene management (at least 3 scenes)
-- Hide/show UI objects
--
-- Widgets:
-- Button, Slider and/or Switch (any combination 5 points max)
-- Native text field
--
-- Data Model and Files:
-- Load resource data from file
-- User data load/save
--
-- Deploy and Demo:
-- Show deployment on Android or iOS device
-- Demo app and show some source code in front of class (during the last week)

-- Load physics engine
local physics = require("physics")

------------------------------
--Create file local constants
------------------------------

--Create parent table for all parallax scrolling objects
local parallaxObj = {}

-- Create moon
local moon

-- Create array of clouds
local bgClouds

-- Create background
local bg
local bgPaint

--Declare constants for the player
local CONST_PLAYER_WIDTH = 20
local CONST_PLAYER_HEIGHT = 20
local CONST_PLAYER_X_INIT = display.contentWidth / 2
local CONST_PLAYER_Y_INIT = 0
local CONST_PLAYER_Y_ACCEL = 0.8 --Gravity variable
local CONST_PLAYER_JUMP_VEL = -17
local CONST_GROUND_Y = display.contentHeight - display.screenOriginY - CONST_PLAYER_HEIGHT / 2 - 32

--Declare player object
local objPlayer

-- Declare enemy objects
local enemies

------------------------------
--Declare file local variables
------------------------------

--Declare a game timer that triggers various game events
local gameTimer

--Declare variables for the background picture
local bgOriginX, bgOriginY
local bgWidth
local bgHeight

--Declare array for game objects
local objects

local jump = 1
local objRope = nil
local ropeJoint

local isHooked = false

--------------------
--Define functions--
--------------------

--Create an object
local function createObject(obj, options)
	if(options.color ~= nil) then
		obj = display.newRect(options.x, options.y, options.width, options.height)
		obj:setFillColor(unpack(options.color))
	end

	if(options.image ~= nil) then
		obj = display.newImageRect( options.image, options.width, options.height )
		obj.x, obj.y = options.x, options.y
	end

	obj.xVel = options.xVel or 0

	--Return the object
	return obj
end

local function createRopeJoint()
	if(ropeJoint == nil) then
		ropeJoint = physics.newJoint( "rope", objPlayer, objGrapplePt )
		ropeJoint.maxLength = 90
		isHooked = true
		objSpike:removeSelf()
		objSpike = nil
	end
end

local function onLocalCollision( self, event )
	if(event.other ~= objPlayer) then
		timer.performWithDelay( 1, createRopeJoint )
	end
end

--Function for parallax scrolling
local function parallaxScrolling(obj)
	if(obj.xVel ~= nil) then
		obj.x = obj.x + obj.xVel
	end
	if(obj.x < -obj.width - 44) then
		obj.x = display.actualContentWidth
	end
end

--Create function for player tap jump/shoot chain
local function playerJump(event)

	-- At the beginning of the player's tap press
	if(event.phase == "began") then

		-- If the player exists
		if(objPlayer ~= nil) then

			-- If the joint exists between the player and a
			-- grapple point
			if(ropeJoint ~= nil) then

				-- Remove the joint
				ropeJoint:removeSelf()
				ropeJoint = nil

				-- Obtain the player's velocity
				local x, y = objPlayer:getLinearVelocity()

				-- Set the player's velocity to double the 
				-- current value
				objPlayer:setLinearVelocity(2*x, 2*y)

				isHooked = false

				objRope:removeSelf()
				objRope = nil
			end
		
			-- If the player hasn't jumped yet
			if(jump == 0) then

				--Cause the player to jump
				objPlayer:setLinearVelocity(0, -200)

				-- Set the player jump variable to true
				jump = 1

			-- If the player has already jumped
			elseif(jump ==1) then

				-- If the chain doesn't exist yet
				if(objRope == nil) then

					-- Create the chain that the player throws
					objRope = createObject(objRope,{
						x = objPlayer.x,
						y = objPlayer.y,
						width = 1,
						height = 3,
						color = {0.5,0.5,0.5},
					})

					-- Shoot the chain out at a 45 degree angle
					objRope.rotation = 315

					-- Initialize the timer for the chain
					objRope.timer = 0
					
					-- Create the spike attached to the chain
					objSpike = createObject(objSpike,{
						x = objRope.x,
						y = objRope.y,
						width = 12,
						height = 12,
						image = "Spike.png"
					})

					-- Add physics to the spike
					physics.addBody(objSpike, "dynamic", {isSensor = true})

					-- Add collision detection to the spike
					objSpike.collision = onLocalCollision
					objSpike:addEventListener( "collision" )
				end
			end
		end
	end
end

local function updateGrappleHook(rope, spike)

	if(rope ~= nil) then

		-- Initialize the chain's speed and time between phases
		local ropeSpeed = 7
		local ropeTime = 20

		rope.x = objPlayer.x
		rope.y = objPlayer.y
		rope.anchorX = 0
		rope.timer = rope.timer + 1

		--Timer events
		if(rope.timer < ropeTime) then
			rope.width = rope.width + ropeSpeed

		elseif(rope.timer >= ropeTime and rope.timer < ropeTime * 2) then
			rope.width = rope.width - ropeSpeed

		elseif(rope.timer == ropeTime * 2) then
			rope:removeSelf()
			rope = nil
			spike:removeSelf()
			spike = nil
		end

		if(spike ~= nil and rope ~= nil) then
			spike.x = rope.x + (rope.width) / math.sqrt(2)
			spike.y = rope.y - (rope.width) / math.sqrt(2)
		end
	end

	return rope, spike
end

local function updateRopeObject(player, grapplePnt, rope)

	-- Set variables for changes in x and y
	local ropeDx = objGrapplePt.x - objPlayer.x
	local ropeDy = objGrapplePt.y - objPlayer.y

	objRope.x = objPlayer.x
	objRope.y = objPlayer.y
	-- 
	objRope.rotation = 360 * math.atan(ropeDy / ropeDx) / (2 * math.pi) + 180

	if(objPlayer.x < objGrapplePt.x) then
		objRope.anchorX = 1
	else
		objRope.anchorX = 0
	end
	objRope.width = math.sqrt(ropeDx^2 + ropeDy^2)
end

--Update game events
local function updateGameEvents()
	gameTimer = gameTimer + 1
end

-- Keep the player from leaving the bounds of the game
local function keepPlayerInBounds()
	if(objPlayer.x < -44 + 10) then
		objPlayer.x = -44 + 10
	end
	if(objPlayer.x > display.actualContentWidth - 44 - 10) then
		objPlayer.x = display.actualContentWidth - 44 - 10
	end

	if(jump <= 1) then
		if(objPlayer.x < CONST_PLAYER_X_INIT - 10) then
			objPlayer.x = objPlayer.x + 2
		elseif(objPlayer.x > CONST_PLAYER_X_INIT + 10) then
			objPlayer.x = objPlayer.x - 2
		end
	end
end

-- Handle all enter frame events
local function handleEnterFrameEvents(event)

	--Update game events
	updateGameEvents()

	-- Keep the player in the game's boundaries
	keepPlayerInBounds()

	if(objPlayer.y >= CONST_GROUND_Y - 1) then
		jump = 0
	end


	-- Update background clouds
	if(bgClouds ~= nil) then
		for i=1, #bgClouds do
			parallaxScrolling(bgClouds[i])
		end
	end

	parallaxScrolling(objGrapplePt)

	-- Update chain when its shot and not locked onto a
	-- grapple point
	if(objRope ~= nil and isHooked == false) then
		objRope, objSpike = updateGrappleHook(objRope, objSpike)
	end

	-- Update the chain joint if it exists
	if(ropeJoint ~= nil) then
		updateRopeObject()
	end
end

-- Handle all touch events
local function handleTouchEvents(event)
	playerJump(event)
end

--Handle all of the event listeners
local function handleEventListeners()
	Runtime:addEventListener( "enterFrame", handleEnterFrameEvents )
	Runtime:addEventListener( "touch", handleTouchEvents )
end

--Initialize variables and objects
local function initGame()

	-- Initialize the physics engine
	physics.start()

	-- Initialize the game timer
	gameTimer = 0

	-- Create the sky background
	bg = display.newRect(-44 + display.actualContentWidth / 2, display.actualContentHeight / 2,
	 display.actualContentWidth, display.actualContentHeight)
	bg.fill = {0, 0.5, 1}

	-- Create the moon
	moon = createObject(moon,
		{
			x = display.contentWidth - 50 + 22,
			y = 50,
			width = 50,
			height = 50,
			color = {1,1,1}
		}
	) 
	moon.alpha = 0.25

	-- Create background clouds for parallel scrolling
	-- Create 3-4 layers of clouds (different sizes)
	bgClouds = {}
	for i=1, 5 do
		bgClouds[i] = createObject(bgClouds[i],
			{
				x = -44 + 120 * i,
				y = 70,
				width = 40,
				height = 20,
				color = {1, 1, 1},
				xVel = -2
			}
		)
	end

	for i=6, 10 do
		bgClouds[i] = createObject(bgClouds[i],
			{
				x = -44 + 120 * (i-5),
				y = 40,
				width = 20,
				height = 10,
				color = {1, 1, 1},
				xVel = -1
			}
		)
	end

	for i=11, 15 do
		bgClouds[i] = createObject(bgClouds[i],
			{
				x = -44 + 120 * (i-10),
				y = 20,
				width = 10,
				height = 5,
				color = {1, 1, 1},
				xVel = -0.5
			}
		)
	end

	for i=1,15 do
		bgClouds[i].alpha = 0.5
	end

	-- Create background grass for parallel scrolling
	-- Create 3-4 layers of grass (different sizes)
	grass = createObject(grass,
		{
			x = display.contentWidth / 2,
			y = CONST_GROUND_Y + (display.contentHeight - CONST_GROUND_Y) / 2 + CONST_PLAYER_HEIGHT / 2,
			width = display.contentWidth + 88,
			height = display.contentHeight - CONST_GROUND_Y,
			color = {0,1,0}
		}
	) 

	-- Create the player for the player to control
	objPlayer = createObject(objPlayer,
		{
			x = CONST_PLAYER_X_INIT,
			y = CONST_PLAYER_Y_INIT,
			width = CONST_PLAYER_WIDTH,
			height = CONST_PLAYER_HEIGHT,
			color = {1,0,0},
		}
	)

	-- Create the grapple point for the chain spike to
	-- attach to
	objGrapplePt = createObject(objGrapplePt,
		{
			x = 140,
			y = 140,
			width = 20,
			height = 20,
			color = {1,0,1},
			xVel = -2
		}
	)

	-- Add physics to the player
	physics.addBody(objPlayer, "dynamic", { friction=1, bounce=0 })

	-- Add physics to the grass
	physics.addBody(grass, "static", {bounce = 0, friction = 1})

	-- Add physics to the grapple point
	physics.addBody(objGrapplePt, "static", {bounce = 0})

	handleEventListeners()
end

-------------------
--Initialize game--
-------------------

--Function that initializes the game
initGame()