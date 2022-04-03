-- a class for levels 
-- and some functions for managing them

local Level = class("Level")

function Level:initialize(name, content, intro, outro)

    self.name = name
    self.content = content

    self.width = self.content.width
    self.height = self.content.height

    self.playerX = 1
    self.playerY = 1
    self.playerImage = images.child_left
    self.playerLookingLeft = true

    self.carrying = ""

    --self.playerSpeed = 30

    -- initialize grid
    self.grid = {}
    for x = 1, self.width do
        self.grid[x] = {}
        for y = 1, self.height do
            self.grid[x][y] = "" -- empty string
        end
    end

    -- initialize grid size
    self.tileSize = math.min(CANVAS_HEIGHT/self.height, CANVAS_WIDTH/self.width)
    self.offsetX = (CANVAS_WIDTH - self.width*self.tileSize)/2
    self.offsetY = (CANVAS_HEIGHT - self.height*self.tileSize)/2

    -- load starting map
    local mapRows = {}
    for line in string.gmatch(self.content.map, "[^%c]+") do
        table.insert(mapRows, line)
    end
    print(#mapRows.." rows of content in this map")
    emptyRows = self.height - #mapRows
    for y = 1, self.height do
        if y > emptyRows then
            for x = 1, self.width do
                local letter = string.sub(mapRows[y-emptyRows], x, x)
                if letter == "w" then     -- water
                    self.grid[x][y] = "w"
                elseif letter == "g" then -- ground
                    self.grid[x][y] = "g"
                elseif letter == "h" then -- help
                    self.grid[x][y] = "h"
                elseif letter == "a" then -- animal
                    self.grid[x][y] = "a"
                elseif letter == "b" then -- bag
                    self.grid[x][y] = "b"
                elseif letter == "p" then -- player
                    self.playerX = x
                    self.playerY = y
                end
            end
        end
    end

    
    -- initialize level state

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

function Level:update(dt)
    -- todo
    
end

function Level:isBlocked(x, y)
    local tile = self.grid[x][y]
    if tile == "w" then
        return true
    elseif tile == "g" then
        return true
    elseif tile == "b" then 
        return true
    elseif tile == "h" then 
        return true
    elseif tile == "a" then 
        return true
    else
        return false
    end
end

function Level:movePlayer(x, y)
    local newX = self.playerX + x
    local newY = self.playerY + y
    -- check for borders:
    if newX > self.width then
        newX = self.width
    elseif newX < 1 then
        newX = 1
    end
    -- check for collisions and stairs:
    local new_tile = self.grid[newX][newY]
    local tile_above = self.grid[newX][newY-1]
    if self:isBlocked(newX, newY) then
        if not self:isBlocked(newX, newY-1) then
            newY = newY-1
        else
            newX = self.playerX
        end
    end

    -- check for gravity:
    if new_tile == "" then
        local tile_below = self.grid[newX][newY+1]
        if tile_below == "w" then
            newX = self.playerX -- don't walk on water
        end
        local look_down = tile_below
        while look_down == "" do
            newY = newY + 1 -- maybe jump down through air
            look_down = self.grid[newX][newY+1]
        end
        if look_down == "w" then -- but don't jump into water
            newX = self.playerX
            newY = self.playerY
        end

    end

    -- set new position
    self.playerX = newX
    self.playerY = newY
end

function Level:liftObject()
    if self.carrying == "" then -- carry only one object at at time
        local side = 1
        if self.playerLookingLeft then
            side = -1
        end
        local view_tile = self.grid[self.playerX+side][self.playerY] 
        if view_tile == "b" then
            self.carrying = "b" --pick up bag from next tile
            self.grid[self.playerX+side][self.playerY]  = ""
        elseif view_tile == "a" then --pick up animal from next tile
            self.carrying = "a"
            self.grid[self.playerX+side][self.playerY]  = ""
        end
    end
end

function Level:setDownObject()
    if self.carrying ~= "" then
        local side = 1
        if self.playerLookingLeft then
            side = -1
        end
        local view_tile = self.grid[self.playerX+side][self.playerY] 
        if view_tile == "" then -- if there is room
            local down = 1
            local view_down = self.grid[self.playerX+side][self.playerY+down]
            while view_down == "" do
                down = down+1
                view_down = self.grid[self.playerX+side][self.playerY+down]
            end
            if self.playerX+down > self.height then
                self.grid[self.playerX+side][self.playerY+down-1] = self.carrying -- set down object on level floor
                self.carrying = ""
            elseif view_down == "g" then
                self.grid[self.playerX+side][self.playerY+down-1] = self.carrying -- set down object on ground
                self.carrying = ""
            elseif view_down == "b" then
                self.grid[self.playerX+side][self.playerY+down-1] = self.carrying -- set down object on bag
                self.carrying = ""
            elseif view_down == "a" then
                self.grid[self.playerX+side][self.playerY+down-1] = self.carrying -- set down object on animal
                self.carrying = ""
            elseif view_down == "h" then
                self.grid[self.playerX+side][self.playerY+down-1] = self.carrying -- set down object on help
                self.carrying = ""
            end

        end
    end
end

function Level:drawPlayer()
    love.graphics.setColor(1, 0.5, 0) --orange
    local pos_x = (self.playerX-0.5)*self.tileSize+self.offsetX
    local pos_y = (self.playerY-0.5)*self.tileSize+self.offsetY
    local scalex = 1
    if self.playerLookingLeft == false then
        scalex = -1
    end
    love.graphics.draw(self.playerImage, pos_x, pos_y, 0, scalex, 1, self.playerImage:getWidth()/2, self.playerImage:getHeight()/2)
    if self.carrying ~= "" then
        if self.carrying == "a" then
            love.graphics.setColor(1.0, 0.8, 0.8) --pink
        elseif self.carrying == "b" then
            love.graphics.setColor(0.8, 0.8, 0.4) --beige
        end
        love.graphics.circle("fill", pos_x, pos_y-(self.tileSize*0.6), self.tileSize*0.3)
    end
end

function Level:drawGrid()
    -- draw tiles:
    for x, col in ipairs(self.grid) do
        for y, tile in ipairs(col) do
            if tile == "w" then
                love.graphics.setColor(0, 0, 1) --blue
            elseif tile == "g" then
                love.graphics.setColor(0.4, 0.4, 0.4) --gray
            elseif tile == "h" then
                love.graphics.setColor(0.5, 0.3, 0.1) --brown
            elseif tile == "a" then
                love.graphics.setColor(1.0, 0.8, 0.8) --pink
            elseif tile == "b" then
                love.graphics.setColor(0.8, 0.8, 0.4) --beige
            else
                love.graphics.setColor(0, 0, 0) --black
            end
            love.graphics.rectangle("fill", self.offsetX+(x-1)*self.tileSize, self.offsetY + (y-1)*self.tileSize, self.tileSize, self.tileSize, 10)
        end
    end

end


function Level:draw()
    if self.won == true then
        love.graphics.printf(self.outro, 0, CANVAS_HEIGHT/2, CANVAS_WIDTH, "center")
    elseif (self.started == false and self.intro ~= nil) then
        love.graphics.printf(self.intro, 0, CANVAS_HEIGHT/2, CANVAS_WIDTH, "center")
    else
        self:drawGrid()
        self:drawPlayer()
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