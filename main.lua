require "lib.slam"
require "lib.helpers"
vector = require "lib.hump.vector"
tlfres = require "lib.tlfres"
class = require 'lib.middleclass'
Input = require "lib.input.Input"
input = nil

-- boilerplate:
CANVAS_WIDTH = 1920
CANVAS_HEIGHT = 1080

-- game specific:
child_rotation = 0
child_x = CANVAS_WIDTH / 2
child_y = CANVAS_HEIGHT / 2


function love.load()
    -- boilerplate:

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

    input = Input:new()
end

function love.update(dt)
    -- boilerplate:
    input:update(dt)
    handleInput()

    -- game spefific:
    child_rotation = child_rotation+dt*5
    child_x = child_x + input:getX() * 10
    child_y = child_y + input:getY() * 10
end

function love.mousemoved(x, y, dx, dy, istouch)
    -- boilerplate:
    input:mouseMoved(dx, dy)
end

-- not sure if we need this, only makes sense with absolute mouse positions
function love.mouse.getPosition()
    return tlfres.getMousePosition(CANVAS_WIDTH, CANVAS_HEIGHT)
end

function handleInput()
     -- boilerplate:
    if input:isPressed("quit") then
        love.window.setFullscreen(false)
        love.event.quit()
    end
    if input:isPressed("fullscreen") then
        isFullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not isFullscreen)
    end

    -- game spefific:
    if input:isPressed("click") then
        sounds.meow:setPitch(0.5+math.random())
        sounds.meow:play()
    end
end

function love.draw()
    -- boilerplate:
    love.graphics.setColor(1, 1, 1)
    tlfres.beginRendering(CANVAS_WIDTH, CANVAS_HEIGHT)
    -- Show this somewhere to the user so they know where to configure
    love.graphics.printf("Edit '" .. configFilePath .. "' to configure the input mapping.", 0, 990, CANVAS_WIDTH, "center")
    
    -- game specific:
    love.graphics.draw(images.child, child_x, child_y, child_rotation, 1, 1, images.child:getWidth()/2, images.child:getHeight()/2)

    tlfres.endRendering()
end
