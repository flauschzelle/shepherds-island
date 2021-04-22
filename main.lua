require "lib.slam"
vector = require "lib.hump.vector"
tlfres = require "lib.tlfres"
local class = require 'lib.middleclass' -- see https://github.com/kikito/middleclass

require "helpers"

CANVAS_WIDTH = 1920
CANVAS_HEIGHT = 1080

child_rotation = 0

function love.load()
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

end

function love.update(dt)
    child_rotation = child_rotation+dt*5
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

function love.mousepressed(x, y, button)
    sounds.meow:setPitch(0.5+math.random())
    sounds.meow:play()
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    tlfres.beginRendering(CANVAS_WIDTH, CANVAS_HEIGHT)

    -- Draw the game here!

    x, y = love.mouse.getPosition()

    love.graphics.draw(images.child, x, y, child_rotation, 1, 1, images.child:getWidth()/2, images.child:getHeight()/2)

    tlfres.endRendering()
end
