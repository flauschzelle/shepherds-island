-- The file "inputconfig.lua" serves a dual purpose. It will be parsed and executed by the following "require".
-- If will also be read as a string, and written to a file from that string by "writeConfig".
-- "Require" will try to load if from the save directory, and if the file is missing there, read it from the lib folder.
-- "writeConfig" will always write to the save directory, no matter from where it was read before.

-- If the user shall edit the input config, the have to know the path, like:
-- love.graphics.printf("Edit '" .. configFilePath .. "' to configure the input mapping.", 0, 990, CANVAS_WIDTH, "center")

require("inputconfig")
local configFileName = "inputconfig.lua"
local pathSeparator = package.config:sub(1,1)
configFilePath = love.filesystem.getSaveDirectory() .. pathSeparator .. configFileName

local Input = class("Input")

function Input:initialize()
    self:writeConfig()

    self.down = {}
    self.pressed = {}
    self.released = {}

    for mappingKey, value in pairs (keymapping) do
        self.down[mappingKey] = false
        self.pressed[mappingKey] = false
        self.released[mappingKey] = false
    end

    self.mouseDx = 0
    self.mouseDy = 0
    self.dx = 0
    self.dy = 0

    love.mouse.setRelativeMode(true)
end


function Input:writeConfig() 
    if love.filesystem.getRealDirectory(configFileName) == love.filesystem.getSaveDirectory() then
        -- This file is in the save directory.
        print("Opened custom " .. configFileName  .. " from " .. configFilePath)
        contents, size = love.filesystem.read(configFileName)

        -- If you add new keymappings after releasing the game, you need to patch in the new keymappings here, like this:

        -- if not keymapping.mute then
        --     keymapping.mute = {
        --         mouseButtons = {},
        --         keys = {"m"},
        --         joystickButtons = {}
        --     }
        --     contents = contents:gsub("reload = {", [[mute = {
        --     mouseButtons = {},
        --     keys = {"m"},
        --     joystickButtons = {}
        -- }, 
        -- reload = {]]);
        -- end

        love.filesystem.write(configFileName, contents)
    else
        -- The file is not yet in the save directory and must be created.
        print("Creating custom " .. configFileName .. " in " .. configFilePath)
        contents, size = love.filesystem.read(configFileName)
        love.filesystem.write(configFileName, contents)
    end
end

function Input:update(dt)
    for mappingKey, value in pairs (keymapping) do
        local oldDown = self.down[mappingKey]
        local newDown = false

        for _, number in ipairs(value.mouseButtons) do
            if love.mouse.isDown(number) then
                newDown = true
            end
        end

        for _, key in ipairs(value.keys) do
            if love.keyboard.isDown(key) then
                newDown = true
            end
        end

        local joysticks = love.joystick.getJoysticks()
        for i, joystick in ipairs(joysticks) do
            for _, number in ipairs(value.joystickButtons) do
                if joystick:isDown(number) then
                    newDown = true
                end
            end
        end

        self.down[mappingKey] = newDown
        self.pressed[mappingKey] = newDown and not oldDown
        self.released[mappingKey] = oldDown and not newDown
    end

    -- movement
    local dx = 0
    local dy = 0
    local joysticks = love.joystick.getJoysticks()
    for i, joystick in ipairs(joysticks) do
        for _, i in ipairs(axismapping.xAxes) do
            dx = dx + joystick:getAxis(i)
        end
        for _, i in ipairs(axismapping.yAxes) do
            dy = dy + joystick:getAxis(i)
        end

        local hats = ""
        for i = 1, joystick:getHatCount() do
            local hatDirection = joystick:getHat(i)
            if string.match(hatDirection, "d") then
                dy = dy + 1
            end
            if string.match(hatDirection, "u") then
                dy = dy - 1
            end
            if string.match(hatDirection, "r") then
                dx = dx + 1
            end
            if string.match(hatDirection, "l") then
                dx = dx - 1
            end
        end
    end

    local ks = 0.4 --keyboardSpeed
    if self.down["down"] then
        dy = dy + ks
    end
    if self.down["up"] then
        dy = dy - ks
    end
    if self.down["right"] then
        dx = dx + ks
    end
    if self.down["left"] then
        dx = dx - ks
    end

    dx = dx + self.mouseDx / dt / 2000
    dy = dy + self.mouseDy / dt / 2000

    self.mouseDx = 0
    self.mouseDy = 0

    -- print ("dx: " .. dx .. ", dy: " .. dy)

    -- use motion:
    self.dx = dx
    self.dy = dy
end

function Input:getX()
    return self.dx
end

function Input:getY()
    return self.dy
end

-- if the key is down right now, no matter how long it has already been down
function Input:isDown(name)
    return self.down[name]
end

-- if the key was pressed just now, between the two most recent calls of update
function Input:isPressed(name)
    return self.pressed[name]
end

-- if the key was released just now, between the two most recent calls of update
function Input:isReleased(name)
    return self.released[name]
end

function Input:mouseMoved(dx, dy)
    self.mouseDx = self.mouseDx + dx
    self.mouseDy = self.mouseDy + dy
end

-- This returns a string which describes the keys bound to an envet, suitable do display to the user, as in "Press <getKeyString("pause")> to pause."
function Input:getKeyString(name)
    local retString = ""

    local options = {}

    for _, key in ipairs(keymapping[name].keys) do
        table.insert(options, key)
    end

    for _, number in ipairs(keymapping[name].mouseButtons) do
        table.insert(options, "MB" .. number)
    end

    if love.joystick.getJoystickCount() > 0 then
        for _, number in ipairs(keymapping[name].joystickButtons) do
            table.insert(options, "GP" .. number)
        end
    end

    for i = 1, #options - 2 do
        retString = retString .. options[i] .. ", "
    end

    if #options > 1 then
        retString = retString .. options[#options - 1] .. " or " 
    end

    if #options > 0 then
        retString = retString .. options[#options]
    end

    if #options == 0 then
        retString = "...not configured..."
    end

    return retString
end

return Input