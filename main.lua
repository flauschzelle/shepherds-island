require "lib.slam"
vector = require "lib.hump.vector"
tlfres = require "lib.tlfres"
local class = require 'lib.middleclass' -- see https://github.com/kikito/middleclass
local libroomy = require 'lib.roomy' -- see https://github.com/tesselode/roomy

require "helpers"

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

    -- scenes
    for i,filename in pairs(love.filesystem.getDirectoryItems("scenes")) do
        if filename ~= ".gitkeep" then
            local sceneName = filename:sub(1, -5)
            scenes[sceneName] = require ("scenes."..sceneName)
        end
    end
    roomy:hook({exclude = {"draw"}}) --hook roomy in to manage the scenes (with exceptions)
    roomy:enter(scenes.title) --start on title screen

end

function love.update(dt)
end

function love.mouse.getPosition()
    return tlfres.getMousePosition(CANVAS_WIDTH, CANVAS_HEIGHT)
end

function love.keypressed(key)
    if key == "escape" then
        love.window.setFullscreen(false)
        love.event.quit()
    elseif key == "f" then
        isFullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not isFullscreen)
    end
end

function love.keyreleased(key)
end

function love.draw()
    love.graphics.setColor(1, 1, 1) -- white
    tlfres.beginRendering(CANVAS_WIDTH, CANVAS_HEIGHT)

    -- (draw any global stuff here)

    -- draw scene-specific stuff:
    roomy:emit("draw")

    tlfres.endRendering()
end
