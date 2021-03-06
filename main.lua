require "lib.slam"
require "lib.helpers"
vector = require "lib.hump.vector"
tlfres = require "lib.tlfres"
class = require 'lib.middleclass' -- see https://github.com/kikito/middleclass
libroomy = require 'lib.roomy' -- see https://github.com/tesselode/roomy
Input = require "lib.input.Input"
Cursor = require "cursor"
Level = require "level"
inspect = require('lib.inspect')

CANVAS_WIDTH = 1920
CANVAS_HEIGHT = 1080
roomy = libroomy.new() -- roomy is the manager for all the rooms (scenes) in our game
scenes = {} -- initialize list of scenes

bigfont = nil
smallfont = nil

function love.load()
    -- initialize randomness in two ways:
    love.math.setRandomSeed(os.time())
    math.randomseed(os.time())

    -- set up default drawing options
    love.graphics.setBackgroundColor(0, 0, 0)

    -- load assets
    love.graphics.setDefaultFilter("nearest", "nearest")
    images = {}
    for file in listUsefulFiles("images") do
        images[file.basename] = love.graphics.newImage(file.path)
    end

    sounds = {}
    for file in listUsefulFiles("sounds") do
        sounds[file.basename] = love.audio.newSource(file.path, "static")
        sounds[file.basename]:setVolume(0.7)
    end
    sounds.sheep:setVolume(0.4)

    music = {}
    for file in listUsefulFiles("music") do
        music[file.basename] = love.audio.newSource(file.path, "stream")
        music[file.basename]:setLooping(true)
        music[file.basename]:setVolume(0.5)
    end

    music["bleeping_demo"]:setPitch(0.9)

    fonts = {}
    for file in listUsefulFiles("fonts") do
        fonts[file.basename] = {}
        local sizes = {32, 50, 64, 128}
        for i,fontsize in ipairs(sizes) do
            fonts[file.basename][fontsize] = love.graphics.newFont(file.path, fontsize)
        end
    end

    hugefont = fonts["digitaldisco"][128]
    bigfont = fonts["digitaldisco"][64]
    smallfont = fonts["digitaldisco_thin"][50]
    tinyfont = fonts["digitaldisco_thin"][32]

    love.graphics.setFont(bigfont)

    -- levels
    basenames = {}
    for file in listUsefulFiles("levels") do
        table.insert(basenames, file.basename)
    end
    table.sort(basenames) --sort level filenames in alphabetical order
    for i, level in ipairs(basenames) do
        levels[i] = require ("levels." .. level)
    end

    initLevelManager() -- this must be done after the levels are loaded from the filesystem

    -- scenes
    for file in listUsefulFiles("scenes") do
        scenes[file.basename] = require ("scenes." .. file.basename)
    end
    roomy:hook({exclude = {"draw", "update"}}) --hook roomy in to manage the scenes (with exceptions)

    --roomy:enter(scenes.gameplay)
    --roomy:push(scenes.menu)
    roomy:enter(scenes.title) --start on title screen

    input = Input:new()
end

function love.update(dt)
    input:update(dt)
    handleInput()
    roomy:emit("handleInput")
    roomy:emit("update", dt)
end

--function love.mousemoved(x, y, dx, dy, istouch)
--    input:mouseMoved(dx, dy)
--end

-- not sure if we need this, only makes sense with absolute mouse positions
function love.mouse.getPosition()
    return tlfres.getMousePosition(CANVAS_WIDTH, CANVAS_HEIGHT)
end

function handleInput()
    --if input:isPressed("quit") then
    --    love.window.setFullscreen(false)
    --    love.event.quit()
    --end
    if input:isPressed("fullscreen") then
        isFullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not isFullscreen)
    end
end

function dimRect()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, CANVAS_WIDTH, CANVAS_HEIGHT)
    love.graphics.setColor(1, 1, 1)
end

function love.draw()
    love.graphics.setColor(1, 1, 1) -- white
    tlfres.beginRendering(CANVAS_WIDTH, CANVAS_HEIGHT)

    -- (draw any global stuff here)

    -- draw scene-specific stuff:
    roomy:emit("draw")

    tlfres.endRendering()
end
