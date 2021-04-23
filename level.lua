-- a class for levels 
-- and some functions for managing them

local Level = class("Level")

function Level:initialize(name, content, intro, outro)

    self.name = name
    self.content = content

    self.started = false
    self.won = false

    -- nil is acceptable as a default value here!
    self.intro = intro
    -- start immediately if the level has no intro
    if self.intro == nil then
        self:start()
    end

    -- default outro text
    if outro ~= nil then
        self.outro = outro
    else
        self.outro = "Congratulations, you won! Click to continue."
    end

end

function Level:draw()
    if self.won == true then
        love.graphics.printf(self.outro, 0, CANVAS_HEIGHT/2, CANVAS_WIDTH, "center")
    elseif (self.started == false and self.intro ~= nil) then
        love.graphics.printf(self.intro, 0, CANVAS_HEIGHT/2, CANVAS_WIDTH, "center")
    else
        love.graphics.printf(self.content, 0, CANVAS_HEIGHT/2, CANVAS_WIDTH, "center")
    end
end

function Level:start()
    self.started = true
end

function Level:isWon()
    return self.won
end

-- go to next level if there is one, return false if not:
function nextLevel()
    if levelManager.current < levelManager.level_count then
        -- got to next level
        levelManager.current = levelManager.current + 1
        -- reset previous level to not won (and not started)
        levels[levelManager.current - 1].won = false
        if levels[levelManager.current - 1].intro ~= nil then
            levels[levelManager.current - 1].started = false
        end

        return true
    else
        return false
    end
end

-- initialize levels list:
levels = {}

-- this must be called once after the levels have been loaded from files:
function initLevelManager()
    levelManager = {
        current = 1, 
        level_count = table.getn(levels),
        currentLevel = function ()
            return levels[levelManager.current]
        end,
    }
end

return Level