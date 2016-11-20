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

--Declare constants for player
local CONST_PLAYER_WIDTH = 20
local CONST_PLAYER_HEIGHT = 20
local CONST_PLAYER_X_INIT = display.contentWidth / 10
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

--------------------
--Define functions--
--------------------

--Function for parallax scrolling buildings
local function parallaxScrolling(obj)
	if(obj.xVel ~= nil) then
		obj.x = obj.x + obj.xVel
	end
	if(obj.x < -obj.width - 44) then
		obj.x = display.actualContentWidth
	end
end

--Create function for player tap jump
local function playerJump(event)

	if(objPlayer ~= nil) then

		if(event.phase == "began") then
			if(jump == 0) then
				--Cause the player to jump
				objPlayer:setLinearVelocity(0, -200)
				jump = jump + 1
			elseif(jump ==1) then
				if(objRope == nil) then
					objRope = createObject(objRope,{
						x = objPlayer.x,
						y = objPlayer.y,
						width = 1,
						height = 1,
						color = {1,1,1},
					})
					objRope.rotation = 315
					objRope.timer = 0
				--if(objSpike == )
				objSpike = createObject(objSpike,{
					x = objRope.x,
					y = objRope.y,
					width = 20,
					height = 20,
					color = {1,1,1},
				})
				end
			end
		end
	end
end

--Create an object
function createObject(obj, options)

	obj = display.newRect(options.x, options.y, options.width, options.height)
	obj:setFillColor(unpack(options.color))

	obj.xVel = options.xVel or 0
	--obj.yVel = 0

	--Return the object
	return obj
end

function updateGrappleHook()

	if(objRope ~= nil) then
		local ropeSpeed = 7
		local ropeTime = 20

		objRope.x = objPlayer.x
		objRope.y = objPlayer.y
		objRope.anchorX = 0
		objRope.timer = objRope.timer + 1
		print(objRope.x + (objRope.width) / math.sqrt(2))

		--Timer events
		if(objRope.timer < ropeTime) then
			objRope.width = objRope.width + ropeSpeed

		elseif(objRope.timer >= ropeTime and objRope.timer < ropeTime * 2) then
			objRope.width = objRope.width - ropeSpeed

		elseif(objRope.timer > ropeTime * 2) then
			objRope:removeSelf()
			objRope = nil
			objSpike:removeSelf()
			objSpike = nil
		end

		if(objSpike ~= nil and objRope ~= nil) then
			objSpike.x = objRope.x + (objRope.width) / math.sqrt(2)
			objSpike.y = objRope.y - (objRope.width) / math.sqrt(2)
		end

	end
end


local function updateRopeObject(player, grapplePnt, rope)

	--[[local ropeX = objGrapplePt.x - objPlayer.x
	local ropeY = objGrapplePt.y - objPlayer.y
	objRope.rotation = 360 * math.atan(ropeY / ropeX) / (2 * math.pi)

	if(objPlayer.x < objGrapplePt.x) then
		objRope.anchorX = 1
	else
		objRope.anchorX = 0
	end
	objRope.width = math.sqrt(ropeX^2 + ropeY^2)]]
end

--Update game events
local function updateGameEvents()
	gameTimer = gameTimer + 1
end

-- Handle all enter frame events
local function handleEnterFrameEvents(event)

	--Update game events
	updateGameEvents()


	if(objPlayer.y >= CONST_GROUND_Y - 1) then
		jump = 0
	end


	-- Update background clouds
	if(bgClouds ~= nil) then
		for i=1, #bgClouds do
			parallaxScrolling(bgClouds[i])
		end
	end

	-- Update rope
	updateGrappleHook()
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

	physics.start()

	gameTimer = 0
	objPlayer = {}

	bg = display.newRect(-44 + display.actualContentWidth / 2, display.actualContentHeight / 2,
	 display.actualContentWidth, display.actualContentHeight)
	bg.fill = {0, 0.5, 1}

	moon = createObject(moon,
		{
			x = display.contentWidth - 50 + 22,
			y = 50,
			width = 50,
			height = 50,
			color = {1,1,1}
		}) 
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
		})
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
		})
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
		})
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
		}) 

	objPlayer = createObject(objPlayer,
		{
			x = CONST_PLAYER_X_INIT,
			y = CONST_PLAYER_Y_INIT,
			width = CONST_PLAYER_WIDTH,
			height = CONST_PLAYER_HEIGHT,
			color = {1,0,0},
		})

	objGrapplePt = createObject(objGrapplePt,
		{
			x = 240,
			y = 120,
			width = 20,
			height = 20,
			color = {1,0,1},
		})

	physics.addBody(objPlayer, "dynamic", { friction=0.5, bounce=0 })
	physics.addBody(grass, "static", {bounce = 0})
	physics.addBody(objGrapplePt, "static")
	--ropeJoint = physics.newJoint( "rope", objPlayer, objGrapplePt )
	--ropeJoint.maxLength = 150

	handleEventListeners()
end

-------------------
--Initialize game--
-------------------

--Function that initializes the game
initGame()