-----------------------------------------------------------------------------------------
--
-- options.lua
--
-----------------------------------------------------------------------------------------

-- load global variables
local g = globalVariables

-- include Corona's "composer" library
local composer = require( "composer" )
local scene = composer.newScene()

-- include Corona's "widget" library
local widget = require "widget"

-- load required Corona modules
local json = require( "json" )

local function musicVolumeListener(event)
	g.musicVolume = event.value
	musicVolumeText.text = "Music Volume " .. g.musicVolume
end

local function sfxVolumeListener(event)
	g.sfxVolume = event.value
	sfxVolumeText.text = "SFX Volume " .. g.sfxVolume
end

local function onTitleBtnRelease()
	-- load game screen
	composer.gotoScene( "title_screen" )

	-- Encode the volume settings into json
	local settings = {musicVolume = g.musicVolume, sfxVolume = g.sfxVolume}
	jsonSettings = json.encode( settings )
	print(jsonSettings)
	writeDataFile(jsonSettings, "user_preferences.txt")

	-- Save volume settings in user preference file


	return true
end

function scene:create( event )
	local sceneGroup = self.view

	-- Called when the scene's view does not exist.
	-- 
	-- INSERT code here to initialize the scene
	-- e.g. add display objects to 'sceneGroup', add touch listeners, etc.

	optionsText = display.newText( "Options", display.actualContentWidth / 2 - 44,
	 30, native.systemFont, 16 )

	musicVolumeText = display.newText( "Music Volume " .. g.musicVolume,
	 display.actualContentWidth / 2 - 44, 80, native.systemFont, 16 )

	musicVolumeSlider = widget.newSlider( 
	{
		x = display.actualContentWidth / 2 - 44,
		y = 110,
		listener = musicVolumeListener,
	} )
	musicVolumeSlider:setValue(g.musicVolume)

	sfxVolumeText = display.newText( "SFX Volume " .. g.sfxVolume,
	 display.actualContentWidth / 2 - 44, 140, native.systemFont, 16 )

	sfxVolumeSlider = widget.newSlider( 
	{
		x = display.actualContentWidth / 2 - 44,
		y = 170,
		listener = sfxVolumeListener
	} )
	sfxVolumeSlider:setValue(g.sfxVolume)

	titleBtn = widget.newButton{
		label="Return",
		labelColor = { default={255}, over={128} },
		width=90, height=40,
		x = display.actualContentWidth / 2 - 44, y = 270,
		shape = "rect",
		fillColor = { default={ 1, 0.2, 0.5, 0.7 }, over={ 1, 0.2, 0.5, 1 } },
		onRelease = onTitleBtnRelease	-- event listener function
	}

	sceneGroup:insert(optionsText)
	sceneGroup:insert(titleBtn)
	sceneGroup:insert(musicVolumeText)
	sceneGroup:insert(musicVolumeSlider)
	sceneGroup:insert(sfxVolumeText)
	sceneGroup:insert(sfxVolumeSlider)

	-- all display objects must be inserted into group
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
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene

