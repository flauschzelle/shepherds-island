require "lib.slam"
require "lib.helpers"
vector = require "lib.hump.vector"
tlfres = require "lib.tlfres"
class = require 'lib.middleclass' -- see https://github.com/kikito/middleclass
libroomy = require 'lib.roomy' -- see https://github.com/tesselode/roomy
Input = require "lib.input.Input"
Cursor = require "cursor"
Level = require "level"

CANVAS_WIDTH = 1920
CANVAS_HEIGHT = 1080
roomy = libroomy.new() -- roomy is the manager for all the rooms (scenes) in our game
scenes = {} -- initialize list of scenes

function love.load()
    -- initialize randomness in two ways:
    love.math.setRandomSeed(os.time())
    math.randomseed(os.time())

    -- set up default drawing options
    love.graphics.setBackgroundColor(0, 0, 0)

    -- load assets
    images = {}
    for i,filename in pairs(love.filesystem.getDirectoryItems("images")) do
        if filename ~= ".gitkeep" then
            images[filename:sub(1,-5)] = love.graphics.newImage("images/"..filename)
        end
    end

    sounds = {}
    for i,filename in pairs(love.filesystem.getDirectoryItems("sounds")) do
        if filename ~= ".gitkeep" then
            sounds[filename:sub(1,-5)] = love.audio.newSource("sounds/"..filename, "static")
        end
    end

    music = {}
    for i,filename in pairs(love.filesystem.getDirectoryItems("music")) do
        if filename ~= ".gitkeep" then
            music[filename:sub(1,-5)] = love.audio.newSource("music/"..filename, "stream")
            music[filename:sub(1,-5)]:setLooping(true)
        end
    end

    fonts = {}
    for i,filename in pairs(love.filesystem.getDirectoryItems("fonts")) do
        if filename ~= ".gitkeep" then
            fonts[filename:sub(1,-5)] = {}
            for fontsize=50,100 do
                fonts[filename:sub(1,-5)][fontsize] = love.graphics.newFont("fonts/"..filename, fontsize)
            end
        end
    end

    love.graphics.setNewFont(40) -- initialize default font size

    -- levels
    ind = 0
    for i,filename in pairs(love.filesystem.getDirectoryItems("levels")) do
        -- TODO: the list of filenames should be sorted to ensure the correct order of levels
        if filename ~= ".gitkeep" then
            ind = ind + 1
            local levelName = filename:sub(1, -5)
            levels[ind] = require ("levels."..levelName)
        end
    end

    initLevelManager() -- this must be done after the levels are loaded from the filesystem

    -- scenes
    for i,filename in pairs(love.filesystem.getDirectoryItems("scenes")) do
        if filename ~= ".gitkeep" then
            local sceneName = filename:sub(1, -5)
            scenes[sceneName] = require ("scenes."..sceneName)
        end
    end
    roomy:hook({exclude = {"draw", "update"}}) --hook roomy in to manage the scenes (with exceptions)
    roomy:enter(scenes.title) --start on title screen

    input = Input:new()
end

function love.update(dt)
    input:update(dt)
    handleInput()
    roomy:emit("handleInput")
    roomy:emit("update", dt)
end

function love.mousemoved(x, y, dx, dy, istouch)
    input:mouseMoved(dx, dy)
end

-- not sure if we need this, only makes sense with absolute mouse positions
function love.mouse.getPosition()
    return tlfres.getMousePosition(CANVAS_WIDTH, CANVAS_HEIGHT)
end

function handleInput()
    if input:isPressed("quit") then
        love.window.setFullscreen(false)
        love.event.quit()
    end
    if input:isPressed("fullscreen") then
        isFullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not isFullscreen)
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1) -- white
    tlfres.beginRendering(CANVAS_WIDTH, CANVAS_HEIGHT)

    -- (draw any global stuff here)
    -- Show this somewhere to the user so they know where to configure
    love.graphics.printf("Edit '" .. configFilePath .. "' to configure the input mapping.", 0, 990, CANVAS_WIDTH, "center")

    -- draw scene-specific stuff:
    roomy:emit("draw")

    tlfres.endRendering()
end
