-- a class for levels 
-- and some functions for managing them

local Level = class("Level")

function Level:initialize(name, map, intro, outro)

    self.name = name
    self.map = map

    self.playerX = 1
    self.playerY = 1
    self.playerImage = images.shepherd
    self.playerLookingLeft = true

    self.carrying = ""

    --self.playerSpeed = 30

    -- get map size
    local mapRows = {}

    -- Iterate over lines, including empty lines.
    -- Via https://stackoverflow.com/questions/19326368/iterate-over-lines-including-blank-lines
    function magiclines(s)
        if s:sub(-1)~="\n" then s=s.."\n" end
        return s:gmatch("(.-)\n")
    end

    for line in magiclines(self.map) do
        table.insert(mapRows, line)
        --print(line)
    end
    self.height = #mapRows
    self.width = 0
    for y = 1, self.height do
        if #mapRows[y] > self.width then
            self.width = #mapRows[y]
        end
    end

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
    --print(#mapRows.." rows of content in this map")
    for y = 1, self.height do
        for x = 1, self.width do
            if #mapRows[y] >= x then
                local letter = string.sub(mapRows[y], x, x)
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

    -- make sure nothing is floating in the air:
    for x = 1, self.width do
        self:applyGravity(x)
    end

    -- count sheep
    self.sheepCount = 0
    for x, c in ipairs(self.grid) do
        for y, t in ipairs (self.grid[x]) do
            if t == "a" then
                self.sheepCount = self.sheepCount + 1
            end
        end
    end

    self.sheepToSave = self.sheepCount
    self.sheepSaved = 0

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

    -- initialize level state history
    self.history = {}
    self:saveState()

end

function Level:saveState()
    -- collect relevant data
    local state = {}
    state.grid = deepcopy(self.grid)
    state.playerX = self.playerX
    state.playerY = self.playerY
    state.playerLookingLeft = self.playerLookingLeft
    state.sheepCount = self.sheepCount
    state.sheepSaved = self.sheepSaved
    state.carrying = self.carrying
    -- save frame to history
    table.insert(self.history, state)
    --print(#self.history)
end

function Level:popState(restart)
    restart = restart or false
    -- make sure there is something to pop
    if #self.history < 2 then
        return
    end
    local frame = #self.history-1
    if restart then
        frame = 1
    end
    -- copy data from history
    local state = deepcopy(self.history[frame])
    self.grid = state.grid
    self.playerX = state.playerX
    self.playerY = state.playerY
    self.playerLookingLeft = state.playerLookingLeft
    self.sheepCount = state.sheepCount
    self.sheepSaved = state.sheepSaved
    self.carrying = state.carrying

    if restart then
        -- clear history
        self.history = {}
        self:saveState()
    else
        -- remove last history frame
        table.remove(self.history, #self.history)
    end
end

function Level:nextState()
    -- save state to hostory
    self:saveState()
    -- advance water
    -- TODO
end

function Level:update(dt)
    if self.sheepSaved == self.sheepToSave then
        self.won = true
    end
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
        -- apply gravity in case something was pulled out from under stuff:
        self:applyGravity(self.playerX+side)
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
                if self.carrying == "a" then
                    self.sheepCount = self.sheepCount - 1
                    self.sheepSaved = self.sheepSaved + 1
                    self.carrying = ""
                else
                    self.grid[self.playerX+side][self.playerY+down-1] = self.carrying -- set down object on help
                    self.carrying = ""
                end
            end

        end
    end
end

function Level:applyGravity(x)
    for y = self.height-1, 1, -1 do
        local tile = self.grid[x][y]
        if tile == "a" or tile == "b" then
            local down = 1
            local tile_below = self.grid[x][y+down]
            while (tile_below == "") and (down+y <= self.height) do
                down = down+1
                tile_below = self.grid[x][y+down]
            end
            if down > 1 and (self:isBlocked(x, y+down) or (y+down == self.height+1)) then
                self.grid[x][y+down-1] = tile
                self.grid[x][y] = ""
            end
        end
    end
end


function Level:drawPlayer()
    love.graphics.setColor(1, 1, 1)
    local pos_x = (self.playerX-0.5)*self.tileSize+self.offsetX
    local pos_y = (self.playerY-0.5)*self.tileSize+self.offsetY
    local scalex = 1
    if self.playerLookingLeft == false then
        scalex = -1
    end
    love.graphics.draw(self.playerImage, pos_x, pos_y, 0, scalex*self.tileSize/16, self.tileSize/16, self.playerImage:getWidth()/2, self.playerImage:getHeight()/2)
    if self.carrying ~= "" then
        local sprite = ""
        if self.carrying == "a" then
            sprite = "sheep"
        elseif self.carrying == "b" then
            sprite = "block"
        end
        if sprite ~= "" then
            sprite = sprite.."_mini"
            love.graphics.draw(images[sprite], pos_x, pos_y-(self.tileSize*11/16), 0, self.tileSize/16, self.tileSize/16, images[sprite]:getWidth()/2, images[sprite]:getHeight()/2)
        end
    end
end

function Level:drawGrid()
    -- draw tiles:
    for x, col in ipairs(self.grid) do
        for y, tile in ipairs(col) do
            -- Always draw blue tile background.
            love.graphics.setColor(65/255, 166/255, 246/255) -- Sweetie 16 light blue
            love.graphics.rectangle("fill", self.offsetX+(x-1)*self.tileSize, self.offsetY + (y-1)*self.tileSize, self.tileSize, self.tileSize)
            love.graphics.setColor(1, 1, 1)

            local sprite = ""
            if tile == "w" then
                sprite = "water"
            elseif tile == "g" then
                sprite = "earth"
            elseif tile == "h" then
                sprite = "boat"
            elseif tile == "a" then
                sprite = "sheep"
            elseif tile == "b" then
                sprite = "block"
            end
            if sprite ~= "" then
                love.graphics.draw(images[sprite], self.offsetX + (x - 1) * self.tileSize,
                                   self.offsetY + (y - 1) * self.tileSize, 0, self.tileSize / 16,
                                   self.tileSize / 16)
            end
            -- draw saved sheep on boat
            if tile == "h" and self.sheepSaved > 0 then
                for i = 1, self.sheepSaved do
                    love.graphics.draw(images["sheep_mini"], 2*i*(self.tileSize/16) + self.tileSize*0.3 + self.offsetX + (x - 1) * self.tileSize,
                   2* (i%2)*self.tileSize/16 + self.offsetY + (y - 0.5) * self.tileSize, 0, self.tileSize / 16,
                    self.tileSize / 16, images["sheep_mini"]:getWidth()/2, images["sheep_mini"]:getHeight()/2)
                end
            end
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
