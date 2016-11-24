-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Endless runner game with grappling hook mechanics
--
-- In this game, a knight runs along an endless strip to land (simulated by
-- having objects scroll from right to left). Background objects will utilize
-- parallax scrolling to create an illusion of depth. There will be a few layers of
-- clouds scrolling by, as well as a distant moon that will stay still. 
--
-- During the game, spikes will appear along the ground that will kill the knight (player)
-- if he touches them. In addition, small walls made of blocks will appear to block the
-- knights path. To get past these obstacles, the player must tap the screen at particular
-- times to avoid these traps. 
--
-- The first time the player taps the screen, the knight will perform a short jump. The
-- second time the player taps the screen (before the knight hits the ground), the knight
-- will shoot out a chain at a 45 degree angle with a small spike attached to the end of it.
--
-- When the spike at the end of the chain hits certain grapple points (such as small floating
-- rings, for instance), the knight will swing from the grapple point utilizing a rope joint.
-- This keeps the player at a max distance from the point but still allow the knight to have
-- some momentum so that they player can launch the knight pass the obstacles.
--
-- Grapple joints in the game will vary. Some will be simple static objects that scroll slowly
-- to the left, while others may be more complicated, such as points attached to one another
-- with pulley joints. This will force the player to use different strategies to overcome
-- each obstacle.
-- 
-- As the game is an endless runner, there is no "winning" the game so to speak. Instead,
-- the farther along in the game the player gets, the greater his/her score will be. The
-- score will increase constantly over time. These scores may be saved in a high score
-- table that the player can access in a different view.
--
-- The game will have a few different screens: at minimum, a title screen, a gameplay screen,
-- and an options screen. If time permits, I will also implement a high score screen.


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

--Declare constants for the background
local bgPaint			   -- Color of the background
local bgOriginX, bgOriginY -- Coordinates for the background
local bgWidth, bgHeight    -- Dimensions for the background

--Declare constants for the knight
local CONST_KNIGHT_WIDTH = 24
local CONST_KNIGHT_HEIGHT = 32
local CONST_KNIGHT_X_INIT = display.contentWidth / 2
local CONST_KNIGHT_Y_INIT = 0
local CONST_KNIGHT_Y_ACCEL = 0.8 --Gravity variable
local CONST_KNIGHT_tap_VEL = -17
local CONST_GROUND_Y = display.contentHeight - display.screenOriginY
 - CONST_KNIGHT_HEIGHT / 2 - 32



------------------------------
--Declare file local variables
------------------------------

--Declare array for game objects
local objects

--Create parent table for all parallax scrolling objects
local parallaxObj = {}

-- Declare a variable for the moon
local moon

-- Declare an array of clouds
local bgClouds

--Declare a variable for the background
local bg

-- Declare player object
local objKnight

-- Declare an array of spike objects
local objSpikes

--Declare a game timer that triggers various game events
local gameTimer

-- Number of taps the player has done since landing
-- The first tap will cause the knight to jump.
-- The first tap will cause the knight to shoot a chain with a spike on the end of it
-- at a 45 degree angle.
local tap = 1

-- Declare a variable for the chain that the knight shoots out
local objChain = nil

-- Declare a variable for the joint that is created between the knight and the
-- grapple points (embodied by the chain)
local chainJoint

-- Declare a variable to determine whether the knight is successfully grappled to a
-- grapple point or not
local isHooked = false

--------------------
--Define functions--
--------------------

--Create an object
local function createObject(obj, options)

	-- If the object has a color (e.g. a shape filled with a color)
	if(options.color ~= nil) then
		obj = display.newRect(options.x, options.y, options.width, options.height)
		obj.fill = options.color
	end

	-- If the object has an associated image path string
	if(options.image ~= nil) then
		obj = display.newImageRect( options.image, options.width, options.height )
		obj.x, obj.y = options.x, options.y
	end

	-- If the object is moving (generally for parallax scrolling)
	obj.xVel = options.xVel or 0

	--Return the object
	return obj
end

-- Create a joint for the chain that the knight shoots out
local function createChainJoint()

	-- Check that the chain joint doesn't already exist
	if(chainJoint == nil) then

		-- Find the change in x and y between where the knight shoots it and
		-- the grappling point
		local chainDx = objGrapplePt.x - objKnight.x - 8
		local chainDy = objGrapplePt.y - objKnight.y

		-- Calculate the hypotenuse for the chain
		local diagDist = math.sqrt(chainDx^2 + chainDy^2)

		-- Create a joint for the chain between the knight and the grappling
		-- point
		chainJoint = physics.newJoint( "rope", objKnight, objGrapplePt )

		-- Limit the chain distance so that the player doesn't drag along the
		-- ground (which is unintended behavior)
		if(diagDist > 100) then
			chainJoint.maxLength = 100
		else
			chainJoint.maxLength = diagDist
		end

		-- Set a variable that shows that the player is hooked to a grapple point
		isHooked = true

		-- Remove the spike from the chain as it is no longer needed
		objSpike:removeSelf()
		objSpike = nil
	end
end

-- Collision checking for detecting if the spike on the end
-- of the chain collides with a grapple point
-- (Check if spike collides with each grapple point)
local function onLocalCollision( self, event )
	if(event.other ~= objKnight) then
		timer.performWithDelay( 1, createChainJoint )
	end
end

--Function for parallax scrolling
local function parallaxScrolling(obj)

	-- Check to make sure the passed object has an x velocity
	if(obj.xVel ~= nil) then

		-- Scroll the object depending on its velocity
		obj.x = obj.x + obj.xVel
	end

	-- If the object is to be recycled (a.k.a. it is moved to
	-- the right side of the screen instead of respawning)
	if(obj.x < -obj.width - 44) then
		-- Move the object to the right side of the screen
		obj.x = display.actualContentWidth
	end
end

-- Create function for player to cause the knight
-- to jump and/or shoot a chain during a screen tap
local function playertap(event)

	-- At the beginning of the player's tap press
	if(event.phase == "began") then

		-- If the knight exists
		if(objKnight ~= nil) then

			-- If the joint exists between the knight and a
			-- grapple point
			if(chainJoint ~= nil) then

				-- Remove the joint
				chainJoint:removeSelf()
				chainJoint = nil

				-- Obtain the knight's velocity
				local x, y = objKnight:getLinearVelocity()

				-- Set the knight's velocity to double the 
				-- current value
				objKnight:setLinearVelocity(1.5*x, 1.5*y)

				-- Mark that the knight is no longer hooked to
				-- the grapple point
				isHooked = false

				-- Remove the chain as it is no longer needed
				objChain:removeSelf()
				objChain = nil

				-- Set the number of taps that the player has done
				-- since the knight has jumped to 1 (this allows the
				-- player to shoot the chain out again before hitting
				-- the ground)
				tap = 1
			end
		
			-- If the player hasn't tapped the screen yet
			if(tap == 0) then

				--Cause the knight to jump
				objKnight:setLinearVelocity(0, -150)

				-- Set the player tap variable to true
				tap = 1

			-- If the player has already tapped the screen once since
			-- the knight last touched the ground
			elseif(tap == 1) then

				-- Mark the tap variable to 2 so that the player can't shoot
				-- the chain out and/or jump again until the knight touches
				-- the ground (unless the player gets the knight to successfully
				-- grab onto a grapple point, in which case, the player will be
				-- able to shoot the chain out again)
				tap = 2

				-- If the chain doesn't exist yet
				if(objChain == nil) then

					-- Create the chain that the knight throws
					objChain = createObject(objChain,{
						x = objKnight.x + 8,
						y = objKnight.y,
						width = 1,
						height = 3,
						color = {0.5,0.5,0.5},
					})

					-- Shoot the chain out at a 45 degree angle
					objChain.rotation = 315

					-- Initialize the timer for the chain
					objChain.timer = 0
					
					-- Create the spike attached to the chain
					objSpike = createObject(objSpike,{
						x = objChain.x,
						y = objChain.y,
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

		rope.x = objKnight.x + 8
		rope.y = objKnight.y
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

			tap = 1
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
	local chainDx = objGrapplePt.x - objKnight.x - 8
	local chainDy = objGrapplePt.y - objKnight.y

	objChain.x = objKnight.x + 8
	objChain.y = objKnight.y
	-- 
	objChain.rotation = 360 * math.atan(chainDy / chainDx) / (2 * math.pi) + 180

	if(objKnight.x < objGrapplePt.x - 8) then
		objChain.anchorX = 1
	else
		objChain.anchorX = 0
	end
	objChain.width = math.sqrt(chainDx^2 + chainDy^2)
end

--Update game events
local function updateGameEvents()
	gameTimer = gameTimer + 1
end

-- Keep the player from leaving the bounds of the game
local function keepPlayerInBounds()
	if(objKnight.x < -44 + 10) then
		objKnight.x = -44 + 10
	end
	if(objKnight.x > display.actualContentWidth - 44 - 10) then
		objKnight.x = display.actualContentWidth - 44 - 10
	end

	--if(tap <= 1) then
		if(objKnight.x < CONST_KNIGHT_X_INIT - 10) then
			objKnight.x = objKnight.x + 2
		elseif(objKnight.x > CONST_KNIGHT_X_INIT + 10) then
			objKnight.x = objKnight.x - 2
		end
	--end
end

-- Handle all enter frame events
local function handleEnterFrameEvents(event)

	--Update game events
	updateGameEvents()

	-- Keep the player in the game's boundaries
	keepPlayerInBounds()

	if(tap == 0) then
		if(objChain ~= nil and objSpike ~= nil) then
			objChain:removeSelf()
			objChain = nil
			objSpike:removeSelf()
			objSpike = nil
		end
	end

	-- Prevent the player from rotating
	objKnight.rotation = 0

	if(objKnight.y >= grass.y - grass.height / 2 - objKnight.height / 2 - 1) then
		tap = 0
	end


	-- Update background clouds
	if(bgClouds ~= nil) then
		for i=1, #bgClouds do
			parallaxScrolling(bgClouds[i])
		end
	end

	obj = parallaxScrolling(objGrapplePt)

	-- Update chain when its shot and not locked onto a
	-- grapple point
	if(objChain ~= nil and isHooked == false) then
		objChain, objSpike = updateGrappleHook(objChain, objSpike)
	end

	-- Update the chain joint if it exists
	if(chainJoint ~= nil) then
		updateRopeObject()
	end
end

-- Handle all touch events
local function handleTouchEvents(event)
	playertap(event)
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
	local paint = {
    	type = "gradient",
    	color1 = { 0,0.5,1,1 },
    	color2 = { 0.75,0,1,1 },
	}
	bg.fill = paint
	-- Create the moon
	moon = createObject(moon,
		{
			x = display.contentWidth - 50 + 22,
			y = 50,
			width = 50,
			height = 50,
			image = "Moon.png"
		}
	) 
	moon.alpha = 0.3

	-- Create background clouds for parallel scrolling
	-- Create 3-4 layers of clouds (different sizes)

	-- Create large clouds
	bgClouds = {}
	for i=1, 5 do
		bgClouds[i] = createObject(bgClouds[i],
			{
				x = -44 + 120 * i,
				y = 40,
				width = 96,
				height = 32,
				image = "Large Cloud.png",
				xVel = -1
			}
		)
	end

	-- Create medium clouds
	for i=6, 10 do
		bgClouds[i] = createObject(bgClouds[i],
			{
				x = -44 + 120 * (i-5),
				y = 80,
				width = 40,
				height = 20,
				image = "Medium Cloud.png",
				xVel = -0.5
			}
		)
	end

	-- Create small clouds
	for i=11, 15 do
		bgClouds[i] = createObject(bgClouds[i],
			{
				x = -44 + 120 * (i-10),
				y = 100,
				width = 20,
				height = 10,
				image = "Small Cloud.png",
				xVel = -0.25
			}
		)
	end

	for i=16, 20 do
		bgClouds[i] = createObject(bgClouds[i],
			{
				x = -44 + 100 * (i-15),
				y = 100 + 10,
				width = 10,
				height = 5,
				image = "Small Cloud.png",
				xVel = -0.25
			}
		)
	end

	for i=1,#bgClouds do
		bgClouds[i].alpha = 0.6
	end

	-- Create background grass for parallel scrolling
	-- Create 3-4 layers of grass (different sizes)
	local paint = {
    	type = "gradient",
    	color1 = { 0.5,1,0,1 },
    	color2 = { 0,1,0,1 },
	}
	grass = createObject(grass,
		{
			x = display.contentWidth / 2,
			y = CONST_GROUND_Y + (display.contentHeight - CONST_GROUND_Y) / 2,
			width = display.contentWidth + 88,
			height = display.contentHeight - CONST_GROUND_Y,
			color = paint
		}
	) 

	-- Create the player for the player to control
	objKnight = createObject(objKnight,
		{
			x = CONST_KNIGHT_X_INIT,
			y = CONST_KNIGHT_Y_INIT,
			width = CONST_KNIGHT_WIDTH,
			height = CONST_KNIGHT_HEIGHT,
			image = "Knight.png"
		}
	)

	-- Create the grapple point for the chain spike to
	-- attach to
	objGrapplePt = createObject(objGrapplePt,
		{
			x = 140,
			y = 140,
			width = 16,
			height = 16,
			image = "Grapple Point.png",
			xVel = -2,
			recycle = false
		}
	)

	-- Add physics to the player
	physics.addBody(objKnight, "dynamic", { friction=1, bounce=0 })

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