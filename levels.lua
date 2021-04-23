-- a class for levels 
-- and also a list of the levels to use in the game

local Level = class("Level")

function Level:initialize(name, content, outro)

    self.name = name
    self.content = content

    if outro ~= nil then
        self.outro = outro
    else
        self.outro = "Congratulations, you won! Click to continue."
    end

    self.won = false
end

function Level:draw()
    if self.won == true then
        love.graphics.printf(self.outro, 0, CANVAS_HEIGHT/2, CANVAS_WIDTH, "center")
    else
        love.graphics.printf(self.content, 0, CANVAS_HEIGHT/2, CANVAS_WIDTH, "center")
    end
end

function Level:isWon()
    return self.won
end

-- go to next level if there is one, return false if not:
function nextLevel()
    if levelManager.current < levelManager.level_count then
        -- got to next level
        levelManager.current = levelManager.current + 1
        -- reset previous level to not won
        levels[levelManager.current - 1].won = false

        return true
    else
        return false
    end
end

-- define levels
first = Level:new("First level", "this is the first level. Press N to win.")
second = Level:new("Second level", "this is the second level. Press N to win.")

-- put all the levels into a list
levels = {
    first,
    second,
}

-- initialize level management:
levelManager = {
    current = 1, 
    level_count = table.getn(levels),
    currentLevel = function ()
        return levels[levelManager.current]
    end,
}

return Level