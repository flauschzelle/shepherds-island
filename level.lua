-- a class for levels 
-- and some functions for managing them

local Level = class("Level")

function Level:initialize(name, map, intro, outro)

    self.name = name
    self.map = map

    self.playerX = 1
    self.playerY = 1
    self.playerImage = images.shepherd
    self.playerImageCarrying = images.shepherd_carrying
    self.playerLookingLeft = true

    self.carrying = ""
    self.playerOnBoat = false

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
    self.lost = false

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
    state.lost = self.lost
    state.playerOnBoat = self.playerOnBoat
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
    self.lost = state.lost
    self.playerOnBoat = state.playerOnBoat

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
    -- advance tidal wave
    self:flood()
    if self.grid[self.playerX][self.playerY] == "w" then
        self:loseLevel("Oh no, you got hit by the water!")
    end
    -- save state to history
    self:saveState()
end

function Level:flood()
    --find starting point for flood:
    print("flood:looking for starting point..")
    local startX = 0
    local startY = 0
    for x, c in ipairs(self.grid) do
        for y, t in ipairs (self.grid[x]) do
            if t == "w" then
                    startX = x
                    startY = y
                    goto found_start
            end
        end
    end

    if startX == 0 then -- no water
        return
    end

    ::found_start::
    print("flood: found starting point")
    -- go along the water surface
    local nextX = startX
    local nextY = startY
    while self.grid[nextX][nextY] == "w" and nextX < self.width do
        print("flood:going along water surface")
        if self.grid[nextX+1][nextY] =="w" then
            nextX = nextX+1
        elseif (self.grid[nextX+1][nextY] == "" or self.grid[nextX+1][nextY] == "h") and self.grid[nextX+1][nextY+1] == "w" then
            nextX = nextX+1
            nextY = nextY+1
        elseif (self.grid[nextX+1][nextY] == "" or self.grid[nextX+1][nextY] == "h") and self.grid[nextX][nextY+1] == "w" then
            nextY = nextY + 1
        else
            break
        end
    end
    -- found a gap or the end of the surface
    print("flood: found gap or end of water surface")
    if nextX < self.width and self.grid[nextX+1][nextY] == "" then 
        self.grid[nextX+1][nextY] = "w" -- put water there
        self:applyGravity(nextX+1)      -- let it fall down
        print("flood:successful")
        if self.grid[nextX][nextY-1] == "h" then
            self.grid[nextX+1][nextY-1] = "h" -- move boat
            if self.playerOnBoat then --move player with boat
                self.playerX = nextX+1
                self.playerY = nextY-1
            end 
            self.grid[nextX][nextY-1] = "" -- put air where it was
            self:applyGravity(nextX+1)      -- let it fall down
        end
        return
    elseif nextX == self.width or self.grid[nextX+1][nextY] == "g" or self.grid[nextX+1][nextY] == "b" then
        print("flood: found end of layer")
        -- go one row up
        nextY = nextY-1
        while true do
            -- find last water block in this row
            print("flood: looking for start of next row")
            while self.grid[nextX][nextY] ~= "w" and nextX > 1 do
                nextX = nextX-1
            end
            if self.grid[nextX][nextY] == "w" then
                print("flood: found start of next row at x="..nextX.." , y="..nextY)
                if self.grid[nextX+1][nextY] == "" then
                    self.grid[nextX+1][nextY] = "w"
                    self:applyGravity(nextX+1)
                    print("flood:successful")
                    return
                elseif self.grid[nextX+1][nextY] == "h" then
                    if nextX+1 < self.width and self.grid[nextX+2][nextY] == "" then
                        self.grid[nextX+2][nextY] = "h" -- move boat
                        if self.playerOnBoat then --move player with boat
                            self.playerX = nextX+2
                            self.playerY = nextY
                        end 
                        self.grid[nextX+1][nextY] = "w" -- put water there
                        self:applyGravity(nextX+1)      -- let the water fall down
                        self:applyGravity(nextX+2)      -- let the boat fall down
                        print("flood:successful")
                        return
                    elseif self.grid[nextX+1][nextY-1] == "" then
                        self.grid[nextX+1][nextY-1] = "h" -- move boat 
                        if self.playerOnBoat then --move player with boat
                            self.playerX = nextX+1
                            self.playerY = nextY-1
                        end 
                        self.grid[nextX+1][nextY] = "w" -- put water there
                        print("flood:successful")
                        return
                    else
                        self.grid[nextX+1][nextY] = "w" --replace boat with water
                        self:loseLevel("oh no, you broke your boat!")
                        return
                    end
                else
                    nextY = nextY-1
                    print("flood: going up one row")
                end

            elseif nextY < startY then
                -- reached top level of water
                print("flood: reached top level at x="..nextX.." , y="..nextY)
                break
            else
                -- go up another row
                print("this should never happen! O.o")
                return
            end
        end
    elseif self.grid[nextX+1][nextY] == "h" then
        if nextX+1 < self.width and self.grid[nextX+2][nextY] == "" then
            self.grid[nextX+2][nextY] = "h" -- move boat
            if self.playerOnBoat then --move player with boat
                self.playerX = nextX+2
                self.playerY = nextY
            end 
            self.grid[nextX+1][nextY] = "w" -- put water there
            self:applyGravity(nextX+1)      -- let the water fall down
            self:applyGravity(nextX+2)      -- let the boat fall down
            print("flood:successful")
            return
        elseif self.grid[nextX+1][nextY-1] == "" then
            self.grid[nextX+1][nextY-1] = "h" -- move boat 
            if self.playerOnBoat then --move player with boat
                self.playerX = nextX+1
                self.playerY = nextY-1
            end 
            self.grid[nextX+1][nextY] = "w" -- put water there
            print("flood:successful")
            return
        else
            self:loseLevel("oh no, you broke your boat!")
            return
        end
    elseif self.grid[nextX+1][nextY] == "a" then
        -- flooded a sheep, oh no!
        self.grid[nextX+1][nextY] = "w" -- set water
        self.sheepCount = self.sheepCount - 1 --remove sheep
        self:loseLevel("Don't let your sheep get wet!")
        return
    end

    -- surface is even/full, start new wave
    print("flood:starting new layer")
    if self.grid[startX][startY-1] == "" then
        self.grid[startX][startY-1] = "w"
    else
        startX = 1
        while self.grid[startX][startY-1] ~= "" and startX < self.width do
            startX = startX+1
            if self.grid[startX][startY-1] == "" then
                self.grid[startX][startY-1] = "w"
                print("flood:successful")
                return
            elseif self.grid[startX][startY] ~= "w" then
                return
            end
        end
    end
end

function Level:update(dt)
    if self.sheepSaved == self.sheepToSave then -- have we saved all sheep?
        if self.playerOnBoat then -- are we safe?
            self.won = true
        end
    end
end

function Level:loseLevel(message)
    self.lostMessage = message
    self.lost = true
end

function Level:isBlocked(x, y)
    local tile = self.grid[x][y]
    if tile == "w" then
        return true
    elseif tile == "g" then
        return true
    elseif tile == "b" then 
        return true
    --elseif tile == "h" then 
        --return true
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
        if self.grid[newX][newY] == "w" then
            newX = self.playerX -- don't walk on water
        elseif not self:isBlocked(newX, newY-1) then
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
        elseif look_down == "h" then -- jump into boat
            newY = newY+1
        end

    end

    -- set new position
    self.playerX = newX
    self.playerY = newY
    if self.grid[self.playerX][self.playerY] == "h" then
        self.playerOnBoat = true
    else
        self.playerOnBoat = false
    end
end

function Level:liftObject()
    if self.carrying == "" then -- carry only one object at at time
        local side = 1
        if self.playerLookingLeft then
            side = -1
        end
        if self.playerX+side > self.width or self.playerX+side < 1 then
            return
        end
        local view_tile = self.grid[self.playerX+side][self.playerY] 
        if view_tile == "b" or view_tile == "a" or view_tile == "h" then
            self.carrying = view_tile -- pick up object from the next tile
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
        if self.playerX+side > self.width or self.playerX+side < 1 then
            return
        end
        local view_tile = self.grid[self.playerX+side][self.playerY] 
        if view_tile == "" then -- if there is room
            local down = 1
            local view_down = self.grid[self.playerX+side][self.playerY+down]
            print(view_down)
            while view_down == "" do
                down = down+1
                view_down = self.grid[self.playerX+side][self.playerY+down]
                print(view_down)
            end
            if self.playerY+down > self.height then
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
            elseif view_down == "w" then
                if self.carrying == "h" then
                    self.grid[self.playerX+side][self.playerY+down-1] = self.carrying -- set down object on water
                    self.carrying = ""
                end
            end
        end
    end
end

function Level:applyGravity(x)
    for y = self.height-1, 1, -1 do
        local tile = self.grid[x][y]
        if tile == "a" or tile == "b" or tile == "w" or tile == "h" then
            local down = 1
            local tile_below = self.grid[x][y+down]
            if tile == "w" and tile_below == "h" then
                self.grid[x][y] = ""
                self.grid[x][y+down] = tile
                if self.grid[x+1][y+down] == "" then
                    self.grid[x+1][y+down] = "h" --move boat to the right
                    if self.playerOnBoat then -- move player with boat
                        self.playerX = x+1
                        self.playerY = y+down
                    end
                    self:applyGravity(x+1) -- let boat fall down
                else
                    self.grid[x][(y-1)+down] = "h"
                    if self.playerOnBoat then --move player with boat
                        self.playerX = x
                        self.playerY = (y-1)+down
                    end 
                end
            elseif tile == "w" and tile_below == "a" then
                self.grid[x][y] = ""
                self.grid[x][y+down] = tile
                self.sheepCount = self.sheepCount -1
                self:loseLevel("Don't let your sheep get wet!")
            end
            while (tile_below == "") and (down+y <= self.height) do
                down = down+1
                tile_below = self.grid[x][y+down]
            end
            if down > 1 and (self:isBlocked(x, y+down) or self.grid[x][y+down] == "h" or (y+down == self.height+1)) then
                if tile == "w" and tile_below == "a" then
                    -- flooded a sheep, oh no!
                    self.grid[x][y] = ""
                    self.grid[x][y+down] = tile
                    self.sheepCount = self.sheepCount - 1 --remove sheep
                    self:loseLevel("Don't let your sheep get wet!")
                elseif tile == "w" and tile_below == "h" then
                        self.grid[x][y] = ""
                        self.grid[x][y+down] = tile
                        self.grid[x][(y-1)+down] = "h" 
                        if self.playerOnBoat then --move player with boat
                            self.playerX = x
                            self.playerY = (y-1)+down
                        end 
                elseif tile == "h" and self.playerOnBoat then
                        self.grid[x][y+down-1] = tile
                        self.grid[x][y] = ""
                        self.playerX = x       -- move player with boat
                        self.playerY = y+down-1
                else
                    self.grid[x][y+down-1] = tile
                    self.grid[x][y] = ""
                end
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
    local image = self.carrying == "" and self.playerImage or self.playerImageCarrying
    love.graphics.draw(image, pos_x, pos_y, 0, scalex*self.tileSize/16, self.tileSize/16, self.playerImage:getWidth()/2, self.playerImage:getHeight()/2)
    if self.carrying ~= "" then
        local sprite = ""
        if self.carrying == "a" then
            sprite = "sheep"
        elseif self.carrying == "b" then
            sprite = "block"
        elseif self.carrying == "h" then
            sprite = "boat"
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
        if self.lost then
            local lostMessage = self.lostMessage.."\nPress "..Input:getKeyString("reset").." to restart\nor "..Input:getKeyString("back").." to undo one step."
            love.graphics.printf(lostMessage, 0, CANVAS_HEIGHT/2, CANVAS_WIDTH, "center")
        end
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
