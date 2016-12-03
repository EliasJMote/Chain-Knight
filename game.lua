-----------------------------------------------------------------------------------------
--
-- game.lua
--
-----------------------------------------------------------------------------------------

-- load global variables
local g = globalVariables

-- Load physics engine
local physics = require("physics")

-- include Corona's "composer" library
local composer = require( "composer" )
local scene = composer.newScene()

-- include Corona's "widget" library
local widget = require "widget"

-- load required Corona modules
local json = require( "json" )

------------------------------
--Create file local constants
------------------------------

--Declare constants for the background
local bgPaint			   -- Color of the background

 -- Coordinates for the background
local bgOriginX, bgOriginY = -44 + display.actualContentWidth / 2,
	 display.actualContentHeight / 2

local bgWidth, bgHeight    -- Dimensions for the background

--Declare constants for the knight
local CONST_KNIGHT_WIDTH = 24
local CONST_KNIGHT_HEIGHT = 32
local CONST_KNIGHT_X_INIT = display.contentWidth / 5
local CONST_KNIGHT_Y_INIT = 0
local CONST_KNIGHT_Y_ACCEL = 0.8 --Gravity variable
local CONST_KNIGHT_JUMP_VEL = -17

local CONST_GROUND_Y = display.contentHeight - display.screenOriginY
 - CONST_KNIGHT_HEIGHT / 2 - 32

local CONST_GRASS_HEIGHT = display.contentHeight - CONST_GROUND_Y
local CONST_GRASS_Y = CONST_GROUND_Y + (display.contentHeight - CONST_GROUND_Y) / 2

local CONST_CHAIN_MAX_LEN = 80

-- Define constants for the crate objects
local crateOptns = 
	{
		x = 500,
		y = 180,
		width = 24,
		height = 24,
		color = {1, 0, 0},
		xVel = -2.5,
	}

local crateOptns2 = 
	{
		x = 500,
		y = 140,
		width = 24,
		height = 24,
		color = {1, 0, 0},
		xVel = -2.5,
	}

local cratePhyOptns = {bounce = 0.5, friction = 0.5, density = 0.01}

-- Define constants for the grapple points
local grppleOptns = {
	x = 500,
	y = 140,
	width = 24,
	height = 24,
	image = "Grapple Point.png",
	xVel = -2.5,
}

local grpplePhyOptns = {bounce = 0, isSensor = true}

local grassOptns = {
	x = display.contentWidth / 2 + 160,
	y = CONST_GROUND_Y + (display.contentHeight - CONST_GROUND_Y) / 2,
	width = display.contentWidth + 88 - 200,
	height = display.contentHeight - CONST_GROUND_Y,
	color = {type = "gradient", color1 = { 0.5,1,0,1 }, color2 = { 0,1,0,1 }},
	xVel = -3,
	scrollObj = scrollObj,
}

local grassPhyOptns = {bounce = 0, friction = 1}

------------------------------
--Declare file local variables
------------------------------

-- Declare a variable for the moon
local moon

-- Declare an array of clouds
local bgClouds

-- Declare an array of boxes
local boxes

--Declare a variable for the background
local bg

local grass

local grassBlocks = {}

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
local tap

-- Declare a variable for the chain that the knight shoots out
local objChain

-- Declare a variable for the joint that is created between the knight and the
-- grapple points (embodied by the chain)
local chainJoint

-- Declare a variable to determine whether the knight is successfully grappled to a
-- grapple point or not
local isHooked

-- Array for all grapple points
local grapplePts

-- Declare a variable to check which grapple point is currently being
-- grappled to
local currentGrapplePt

-- The player's current score
local currentScore = 0

-- Declare boolean for pausing the game
local isPaused

-- Declare menu box to come up when the game is paused
local menuBox

local isGameOver = false

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

	-- Set the object's alpha
	obj.alpha = options.alpha or 1

	-- Set up scroll function if it exists
	obj.scrollObj = options.scrollObj

	-- Set up whether the object should be recycled after scrolling
	-- off screen
	obj.recycle = options.recycle

	--Return the object
	return obj
end

-- Collision checking for detecting if the spike on the end
-- of the chain collides with a grapple point
-- (Check if spike collides with each grapple point)
local function onLocalCollision( self, event )

	-- For each grapple point
	for i in pairs(grapplePts) do

		-- If the spike collides with one of the grapple points
		if(event.other == grapplePts[i]) then

			-- Create a joint for the chain that the knight shoots out
			local function createChainJoint()

				-- Check that the chain joint doesn't already exist
				if(chainJoint == nil) then

					-- Load the scene view
					local sceneGroup = scene.view

					-- Find the change in x and y between where the knight shoots it and
					-- the grappling point
					local chainDx = event.other.x - objKnight.x - 8
					local chainDy = event.other.y - objKnight.y

					-- Calculate the hypotenuse for the chain
					local diagDist = math.sqrt(chainDx^2 + chainDy^2)

					-- Create a joint for the chain between the knight and the grappling
					-- point
					chainJoint = physics.newJoint( "rope", objKnight, event.other )

					-- Set the current grappling point
					currentGrapplePt = event.other

					-- Limit the chain distance so that the player doesn't drag along the
					-- ground (which is unintended behavior)
					if(diagDist > CONST_CHAIN_MAX_LEN) then
						chainJoint.maxLength = CONST_CHAIN_MAX_LEN
					else
						chainJoint.maxLength = diagDist
					end

					-- Set a variable that shows that the player is hooked to a grapple point
					isHooked = true

					sceneGroup:remove(objSpike)

					-- Remove the spike from the chain as it is no longer needed
					objSpike:removeSelf()
					objSpike = nil

					-- Apply linear impulse
					objKnight:applyLinearImpulse( 0.03, 0, objKnight.x + 8, objKnight.y )
				end	
			end

			timer.performWithDelay( 1, createChainJoint )
		end
	end
end

--Function for scrolling objects
function scrollObj(self)

	-- Check to make sure the passed object has an x velocity
	if(self.xVel ~= nil and not isPaused and not isGameOver) then

		-- Scroll the object depending on its velocity
		self.x = self.x + self.xVel
	end

	-- If object is past the left side of the screen
	if(self.x < -self.width - 44) then

		-- If the object is to be recycled (a.k.a. it is moved to
		-- the right side of the screen instead of respawning)
		if self.recycle then

			-- Move the object to the right side of the screen
			self.x = display.actualContentWidth

		-- Otherwise
		else
			-- Destroy the object
			if(currentGrapplePt == self) then
				currentGrapplePt:removeSelf()
				currentGrapplePt = nil
			
				if(chainJoint ~= nil) then
					chainJoint:removeSelf()
					chainJoint = nil
				end
				isHooked = false

				-- Remove the chain as it is no longer needed
				if(objChain ~= nil) then
					objChain:removeSelf()
					objChain = nil
				end

				-- Set the number of taps that the player has done
				-- since the knight has jumped to 1
				tap = 1
			end
			self:removeSelf()
			self = nil
		end
	end

	-- If the object needs to be updated (because it is destroyed),
	-- return it.
	return self
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

				-- Mark that the knight is no longer hooked to
				-- the grapple point
				isHooked = false

				local sceneGroup = scene.view

				sceneGroup:remove(objChain)

				-- Remove the chain as it is no longer needed
				objChain:removeSelf()
				objChain = nil

				-- Remove the current grapple point marker
				currentGrapplePt = nil

				-- Set the number of taps that the player has done
				-- since the knight has jumped to 1 (this allows the
				-- player to shoot the chain out again before hitting
				-- the ground)
				tap = 1

				objKnight:setLinearVelocity( 1.5 * objKnight:getLinearVelocity() )
				
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

					-- Add the chain and spike to the display group
					local sceneGroup = scene.view
					sceneGroup:insert(objChain)
					sceneGroup:insert(objSpike)
				end
			end
		end
	end
end

-- Spawn a scrolling physics object
local function spawnScrlPhyObj(group, creOptns, phyType, phyOptns)

	-- Create a physics object
	local obj = createObject(obj,
		{
			x = creOptns.x,
			y = creOptns.y,
			width = creOptns.width,
			height = creOptns.height,
			image = creOptns.image,
			xVel = creOptns.xVel,
			color = creOptns.color,
			scrollObj = scrollObj
		}
	)

	-- Insert it into the display group
	table.insert(group, obj)

	-- Load in the scene group
	local sceneGroup = scene.view

	-- Put the grapple point into the scene group
	sceneGroup:insert(obj)

	-- Add physics to the grapple point,
	physics.addBody(obj, phyType, phyOptns)	
end

-- Spawn pool for different grapple point configurations
local function grappleObjSpwnPool(num)

	--Configuration 1: 1 grapple point
	if num == 1 then
		spawnScrlPhyObj(grapplePts, grppleOptns, "static", grpplePhyOptns)

	--Configuration 2: 2 grapple point (Vertically spaced)
	elseif num == 2 then

		spawnScrlPhyObj(grapplePts, grppleOptns, "static", grpplePhyOptns)

		grppleOptns.y = grppleOptns.y - 40
		
		spawnScrlPhyObj(grapplePts, grppleOptns, "static", grpplePhyOptns)

		grppleOptns.y = grppleOptns.y + 40
	end
end

local function updateGrappleHook(rope, spike)

	if(rope ~= nil) then

		-- Initialize the chain's speed and time between phases
		local ropeSpeed = 10
		local ropeTime = 13

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

-- Update the chain that the knight holds onto the grapple point with
local function updateChainObject(knight, grapplePnt, chain)

	-- Check that the knight is currently grappled onto a point
	if(currentGrapplePt ~= nil and objKnight ~= nil and objChain ~= nil) then
		-- Set variables for changes in x and y
		local chainDx = currentGrapplePt.x - objKnight.x - 8
		local chainDy = currentGrapplePt.y - objKnight.y

		objChain.x = objKnight.x + 8
		objChain.y = objKnight.y
		-- 
		objChain.rotation = 360 * math.atan(chainDy / chainDx) / (2 * math.pi) + 180

		if(objKnight.x < currentGrapplePt.x - 8) then
			objChain.anchorX = 1
		else
			objChain.anchorX = 0
		end
		objChain.width = math.sqrt(chainDx^2 + chainDy^2)
	end
end

--Update game events
local function updateGameEvents()
	if(not isPaused) then
		gameTimer = gameTimer + 1
	end
end

-- Listener called when releasing the menu button
local function onMenuBtnRelease()
	local sceneGroup = scene.view
	isPaused = not isPaused

	menuBox.isVisible = isPaused
	titleScrBtn.isVisible = isPaused
	exitMenuBtn.isVisible = isPaused
	if(isPaused) then

		physics.pause()
		print("Game paused")

		--Display the pause menu
	else
		physics.start()
		print("Game unpaused")
	end
end

-- Listener called when releasing the title screen button
local function onTitleScrBtnRelease()
	--Clear the game
	composer.removeScene( "game", false )

	-- Load title screen
	composer.gotoScene( "title_screen" )
end

-- Function for scrolling a particular display group
local function scrollGroup(group)
	-- Check to make sure the clouds table exists
	if(type(group) == "table") then

		-- For each cloud in the bg clouds array
		for i in pairs(group) do

			-- Scroll each cloud
			group[i] = group[i]:scrollObj()
		end
	end
end

-- Handle all enter frame events
local function handleEnterFrameEvents(event)

	-- If game isn't paused
	if(not isPaused) then
		--Update game events
		updateGameEvents()

		-- Keep the player in the game's boundaries
		objKnight:keepPlayerInBounds(chainJoint)

		-- Update player score
		objScoreText.text = "Score " .. currentScore

		-- If the knight is on the ground
		if(tap == 0) then

			-- If the chain and the spike exist
			if(objChain ~= nil and objSpike ~= nil) then

				-- Remove both the chain and the spike
				objChain:removeSelf()
				objChain = nil
				objSpike:removeSelf()
				objSpike = nil
			end
		end

		-- Prevent the player from rotating
		objKnight.rotation = 0

		if(objKnight.y >= CONST_GRASS_Y - CONST_GRASS_HEIGHT / 2 - objKnight.height / 2 - 1) then
			tap = 0
		end

		-- Spawn grapple points in and increment the game score
		if(not isGameOver) then
			if(gameTimer % 30 == 0) then

				-- Increment the game score
				currentScore = currentScore + 1

				-- Spawn grapple points
				grappleObjSpwnPool(1)
			end

			if(gameTimer % 180 == 0) then
				spawnScrlPhyObj(grassBlocks, grassOptns, "static", grassPhyOptns)
			end
		end
		if(objKnight.y >= display.actualContentHeight and isGameOver == false) then
			print("Game over")
			isGameOver = true
			gameTimer = 0
		end

		if(isGameOver and gameTimer >= 90) then
			--Update high score
			if(currentScore > g.topScore) then
				g.topScore = currentScore
			end
			print("Top score = " .. g.topScore)

			--Clear the game
			composer.removeScene( "game", false )

			-- Load title screen
			composer.gotoScene( "title_screen" )
		end

		--Scroll background clouds
		scrollGroup(bgClouds)

		--Scroll background clouds
		scrollGroup(grapplePts)

		-- Scroll the grass
		scrollGroup(grassBlocks)

		-- Spawn boxes
		--spawnScrlPhyObj(boxes, crateOptns, "dynamic", cratePhyOptns, 90)

		--spawnScrlPhyObj(boxes, crateOptns2, "dynamic", cratePhyOptns, 90)

		-- Update chain when it's shot and not locked onto a
		-- grapple point
		if(objChain ~= nil and isHooked == false) then
			objChain, objSpike = updateGrappleHook(objChain, objSpike)
		end

		-- Update the chain joint if it exists
		if(chainJoint ~= nil) then
			updateChainObject()
		end
	end
end

-- Handle all screen touch events
local function handleTouchEvents(event)
	playertap(event)
end

--Handle all of the event listeners
local function handleEventListeners()
	Runtime:addEventListener( "enterFrame", handleEnterFrameEvents )
	Runtime:addEventListener( "touch", handleTouchEvents )
end


function scene:create( event )
	local sceneGroup = self.view

	-- Called when the scene's view does not exist.
	-- 
	-- INSERT code here to initialize the scene
	-- e.g. add display objects to 'sceneGroup', add touch listeners, etc.

	------------------------
	--Initialize variables--
	------------------------

	-- Initialize the number of times the player has tapped the screen
	-- since the knight has touched the ground
	tap = 1

	-- Initialize the knight to start ungrappled 
	isHooked = false

	-- Initialize the game timer
	gameTimer = 0

	-- Initialize the cloud background objects
	bgClouds = {}

	-- Initialize the boxes
	boxes = {}

	-- Initialize the group of grapple points
	grapplePts = {}

	-- Initialize the pause state of the game
	isPaused = false

	-- Initialize the menu box that pops up when the game
	-- is paused
	menuBox = createObject(menuBox,
		{
			x = bgOriginX,
			y = bgOriginY,
			width = 240,
			height = 280,
			color = {0.75,0.75,0.75},
		}
	)
	menuBox.isVisible = false

	-- Initialize the menu button that takes the player back
	-- to the title screen
	titleScrBtn = widget.newButton{
		label="Go to title",
		labelColor = { default={255}, over={128} },
		width=120, height=28,
		x = menuBox.x, y = menuBox.y + 14,
		shape = "rect",
		fillColor = { default={ 1, 0.2, 0.5, 0.7 }, over={ 1, 0.2, 0.5, 1 } },
		onRelease = onTitleScrBtnRelease	-- event listener function
	}
	titleScrBtn.isVisible = false

	-- Initialize the menu button that takes the player back
	-- to the game
	exitMenuBtn = widget.newButton{
		label="Return to game",
		labelColor = { default={255}, over={128} },
		width=120, height=28,
		x = menuBox.x, y = menuBox.y + 54,
		shape = "rect",
		fillColor = { default={ 1, 0.2, 0.5, 0.7 }, over={ 1, 0.2, 0.5, 1 } },
		onRelease = onMenuBtnRelease	-- event listener function
	}
	exitMenuBtn.isVisible = false

	-- Start the physics engine
	physics.start()

	-- Create a gradient color for the grass
	--local paint = {type = "gradient", color1 = { 0.5,1,0,1 }, color2 = { 0,1,0,1 },}

	-- Create background grass for parallax scrolling
	-- Create 3-4 layers of grass (different sizes)
	--[[grass = createObject(grass,
		{
			x = display.contentWidth / 2,
			y = CONST_GROUND_Y + (display.contentHeight - CONST_GROUND_Y) / 2,
			width = display.contentWidth + 88 - 40,
			height = display.contentHeight - CONST_GROUND_Y,
			color = paint,
			xVel = -2,
			scrollObj = scrollObj,
		}
	)

	table.insert(grassBlocks, grass)]]
	spawnScrlPhyObj(grassBlocks, grassOptns, "static", grassPhyOptns)

	-- Create the sky background
	bg = display.newRect(-44 + display.actualContentWidth / 2,
	 (display.actualContentHeight - CONST_GRASS_HEIGHT) / 2,
	 display.actualContentWidth, display.actualContentHeight - CONST_GRASS_HEIGHT)
	paint = {
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
			image = "Moon.png",
			alpha = 0.3
		}
	)

	-- Create background clouds for parallel scrolling
	-- Create 3-4 layers of clouds (different sizes)

	-- Create large clouds
	
	for i=1, 5 do
		bgClouds[i] = createObject(bgClouds[i],
			{
				x = -44 + 120 * i,
				y = 40,
				width = 96,
				height = 32,
				image = "Large Cloud.png",
				xVel = -1,
				alpha = 0.6,
				scrollObj = scrollObj,
				recycle = true,
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
				xVel = -0.5,
				alpha = 0.6,
				scrollObj = scrollObj,
				recycle = true,
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
				xVel = -0.25,
				alpha = 0.6,
				scrollObj = scrollObj,
				recycle = true,
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
				xVel = -0.25,
				alpha = 0.6,
				scrollObj = scrollObj,
				recycle = true,
			}
		)
	end

	objScoreBacking = createObject(objScoreBacking, {
			x = 0,
			y = 14,
			width = 88,
			height = 28,
			color = {1, 1, 1}
		}
	)

	objScoreText = display.newText("Score " .. currentScore, 0, 14, native.systemFont )
	objScoreText.fill = {0,0,0}

	menuBtn = widget.newButton{
		label="Menu",
		labelColor = { default={255}, over={128} },
		width=60, height=28,
		x = 74, y = 14,
		shape = "rect",
		fillColor = { default={ 1, 0.2, 0.5, 0.7 }, over={ 1, 0.2, 0.5, 1 } },
		onRelease = onMenuBtnRelease	-- event listener function
	}

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

	-- Set up the knight's functions

	-- Keep the player from leaving the bounds of the game
	function objKnight:keepPlayerInBounds(joint)
		if(self.x < -44 + 10) then
			self.x = -44 + 10
		end
		if(self.x > display.actualContentWidth - 44 - 10) then
			self.x = display.actualContentWidth - 44 - 10
		end

		if joint == nil then
			if(self.x < CONST_KNIGHT_X_INIT - 2) then
				self.x = self.x + 2
			elseif(self.x > CONST_KNIGHT_X_INIT + 2) then
				self.x = self.x - 2
			end
		end
	end

	-- Create the grapple point for the chain spike to
	-- attach to

	-- Add physics to the player
	physics.addBody(objKnight, "dynamic", { friction=1, bounce=0, density = 1.0 })

	-- Add physics to the grass
	--physics.addBody(grass, "static", {bounce = 0, friction = 1})

	handleEventListeners()

	-- all display objects must be inserted into group
	-- Leave the menu objects out of the display group
	-- so that they always stay on top
	-- Remove them manually when done
	sceneGroup:insert(bg)
	sceneGroup:insert(moon)
	for i=1,#bgClouds do
		sceneGroup:insert(bgClouds[i])
	end
	for i=1,#grassBlocks do
		sceneGroup:insert(grassBlocks[i])
	end
	--sceneGroup:insert(grass)
	sceneGroup:insert(objKnight)
	sceneGroup:insert(objScoreBacking)
	sceneGroup:insert(objScoreText)
end

function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		-- Called when the scene is now on screen
		-- 
		-- INSERT code here to make the scene come alive
		-- e.g. start timers, begin animation, play audio, etc.
		physics.start()
	end	
end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if event.phase == "will" then
		-- Called when the scene is on screen and is about to move off screen
		--
		-- INSERT code here to pause the scene
		-- e.g. stop timers, stop animation, unload sounds, etc.)
		physics.pause()
	elseif phase == "did" then
		-- Called when the scene is now off screen
	end	
end

function scene:destroy( event )
	local sceneGroup = self.view
	
	-- Called prior to the removal of scene's "view" (sceneGroup)
	-- 
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.

	-- Stop the physics engine
	physics.stop()

	-- Remove the runtime listeners
	Runtime:removeEventListener( "enterFrame", handleEnterFrameEvents )
	Runtime:removeEventListener( "touch", handleTouchEvents )

	-- Remove the display group
	menuBox:removeSelf()
	menuBox = nil
	menuBtn:removeSelf()
	menuBtn = nil
	titleScrBtn:removeSelf()
	titleScrBtn = nil
	exitMenuBtn:removeSelf()
	exitMenuBtn = nil
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene