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

gameGlobals = {
	musicVolume = 50,
	sfxVolume = 50,
}

-- include Corona's "composer" library
local composer = require( "composer" )
local scene = composer.newScene()

-- hide the status bar
display.setStatusBar( display.HiddenStatusBar )

-- load title screen
composer.gotoScene( "title_screen" )