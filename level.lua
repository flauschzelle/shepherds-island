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
                if letter == "l" then -- only for title screen!
                    self.grid[x][y] = "l"
                elseif letter == "d" then -- only for title screen!
                    self.grid[x][y] = "d"
                elseif letter == "w" then     -- water
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
    -- for x = 1, self.width do
    --     self:applyGravity(x)
    -- end

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

    -- initialize boat indexing
    self.boatCount = 0
    self.boatIndex = {}
    for x, c in ipairs(self.grid) do
        for y, t in ipairs (self.grid[x]) do
            if t == "h" then
                self.boatCount = self.boatCount + 1
                self.boatIndex[self.boatCount] = {}
                self.boatIndex[self.boatCount]["x"] = x
                self.boatIndex[self.boatCount]["y"] = y
                self.boatIndex[self.boatCount]["sheep"] = 0
            end
        end
    end

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
        self.outro = "You're safe, for now!\n\nPress Enter to go to the next island."
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
    state.won = self.won
    state.playerOnBoat = self.playerOnBoat
    state.boatCount = self.boatCount
    state.boatIndex = deepcopy(self.boatIndex)
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
    self.won = state.won
    self.playerOnBoat = state.playerOnBoat
    self.boatCount = state.boatCount
    self.boatIndex = state.boatIndex

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
    -- check if player is on boat
    if self.grid[self.playerX][self.playerY] == "h" then
        self.playerOnBoat = true
        -- automatically set down sheep on boat
        if self.carrying == "a" then
            self.carrying = ""
            self.sheepSaved = self.sheepSaved + 1
            self.sheepCount = self.sheepCount - 1
        end
    end
    if self.grid[self.playerX][self.playerY] == "w" then
        sounds.splash:setPitch(0.8+0.4*math.random())
        sounds.splash:play()
        self:loseLevel("Oh no, you got hit by the water!")
    end
    -- save state to history
    self:saveState()
end

function Level:floodFrom(x, y)
    print("trying to flood from x="..x..", y="..y)
    -- make sure we actually start from water:
    if x > 0 and y > 0 and self.grid[x][y] ~= "w" then
        print("No water here, this should not happen!")
        return
    end
    if x == self.width then
        -- go up one layer:
        local newX, newY = self:findWavefrontBefore(x, y-1)
        self:floodFrom(newX, newY)
        return
    end

    local right = self.grid[x+1][y]
    if right == "" then
        self.grid[x+1][y] = "w"
        self:applyGravity(x+1)
        if self.playerX == x+1 and self.playerY == y then
            sounds.splash:setPitch(0.8+0.4*math.random())
            sounds.splash:play()
            self:loseLevel("Oh no, you got hit by the water!")
        end
    elseif right == "a" then
        self.grid[x+1][y] = "w"
        self:applyGravity(x+1)
        self.sheepCount = self.sheepCount - 1 --remove sheep

        sounds.sheep_unhappy:setPitch(0.8+0.4*math.random())
        sounds.sheep_unhappy:play()
        self:loseLevel("Don't let your sheep get wet!")
    elseif right == "h" then
        local boat = self:getBoatIndex(x+1, y)
        if boat == 0 then
            print("boat index not found, this should not happen!")
            return
        end
        if self:moveBoat(boat, x+2, y) then
            self.grid[x+1][y] = "w"
            self:applyGravity(x+2)
        elseif self:moveBoat(boat, x+1, y-1) then
            self.grid[x+1][y] = "w"
            self:applyGravity(x+1)
        elseif x <= self.width-3 and self.grid[x+2][y] == "h" then --and self.grid[x+3][y] == "" then
            local other_boat = self:getBoatIndex(x+2, y)
            if other_boat == 0 then
                print("boat index not found, this should not happen!")
                return
            end
            if self:moveBoat(other_boat, x+3, y) then
                self:moveBoat(boat, x+2, y)
                self.grid[x+1][y] = "w"
                self:applyGravity(x+3)
                self:applyGravity(x+2)
                self:applyGravity(x+1)
            else
                self.grid[x+1][y] = "w"
                self:loseLevel("oh no, your boat got crushed by the water!")
            end
        else
            sounds.ship_breaks:setPitch(0.8+0.4*math.random())
            sounds.ship_breaks:play()
            self.grid[x+1][y] = "w"
            self:loseLevel("oh no, your boat got crushed by the water!")
        end
        self:applyGravity(x+1)
    elseif (right == "g" or right == "b") and y > 1 then
        -- go up one layer:
        local newX, newY = self:findWavefrontBefore(x, y-1)
        self:floodFrom(newX, newY)
        return
    end
    print("flooded from x="..x..", y="..y)
end

function Level:findWavefrontBefore(x,y)
    print("looking for wavefront from x="..x..", y="..y)
    local newX = x
    local newY = y
    if newX > 0 and newY > 0 and self.grid[x][y] == "w" then
        return newX, newY
    elseif newX > 0 then
        local lookat = self.grid[newX][newY]
        while newX > 1 and lookat ~= "w" do
            newX = newX-1
            lookat = self.grid[newX][newY]
        end
        if self.grid[newX][newY] == "w" then
            return newX, newY
        elseif newX > 1 and y > 1 then
            return self:findWavefrontBefore(x, y-1)
        elseif newX == 1 and newY > 1 then
            local up = self.grid[newX][newY-1]
            newY = newY-1
            if up == "" or up == "h" then
                print("No current wavefront found, starting new flood layer at y="..newY)
                return 0, newY
            end
        elseif newX == 1 and newY == 1 then
             return 0, 1
        else
            print("No water here, this should not happen!")
            return
        end
    elseif newX == 0 and newY > 0 then
        print("No current wavefront found, starting new flood layer at y="..newY)
        return newX, newY
    end
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
    print("flood: found starting point at x="..startX.." , y="..startY)
    -- go along the water surface
    local nextX = startX
    local nextY = startY
    while self.grid[nextX][nextY] == "w" and nextX < self.width and nextY <= self.height do
        print("flood:going along water surface")
        if self.grid[nextX+1][nextY] =="w" then
            nextX = nextX+1
        elseif (self.grid[nextX+1][nextY] == "" or self.grid[nextX+1][nextY] == "h") and nextY < self.height and self.grid[nextX+1][nextY+1] == "w" then
            nextX = nextX+1
            nextY = nextY+1
        elseif nextY < self.height and self.grid[nextX][nextY+1] == "w" then
            nextY = nextY + 1
        else
            break
        end
    end
    -- found a gap or the end of the surface
    print("flood: found end of water surface at x="..nextX.." , y="..nextY)
    -- flood from there
    self:floodFrom(nextX, nextY)
end

function Level:update(dt)
    if self.sheepSaved == self.sheepToSave then -- have we saved all sheep?
        if self.playerOnBoat then -- are we safe?
            if not self.won then
                sounds.win:play()
                self.won = true
            end
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

function Level:getBoatIndex(x, y)
    local index = 0
    for i, boat in pairs(self.boatIndex) do
        if boat["x"] == x and boat["y"] == y then
            index = i
        end
    end
    return index
end

function Level:playerIsOnBoat(index)
    return self.playerOnBoat and self.boatIndex[index]["x"] == self.playerX and self.boatIndex[index]["y"] == self.playerY
end

function Level:moveBoat(index, newX, newY)
    local oldX = self.boatIndex[index]["x"]
    local oldY = self.boatIndex[index]["y"]
    if newX > self.width or newX < 1 or newY > self.height or newY < 1 or self.grid[newX][newY] ~= "" then
        return false
    else
        self.grid[oldX][oldY] = ""
        if self:playerIsOnBoat(index) then
            self.playerX = newX
            self.playerY = newY
        end
        self.grid[newX][newY] = "h"
        self.boatIndex[index]["x"] = newX
        self.boatIndex[index]["y"] = newY    
        return true
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

    local didMove = self.playerX ~= newX or self.playerY ~= newY

    -- set new position

    self.playerX = newX
    self.playerY = newY
    if self.grid[self.playerX][self.playerY] == "h" then
        self.playerOnBoat = true
    else
        self.playerOnBoat = false
    end

    if didMove then
        sounds.step:setPitch(0.5+math.random())
        sounds.step:play()
    end

    return didMove
end

function Level:liftObject()
    if self.carrying == "" then -- carry only one object at at time
        local side = 1
        if self.playerLookingLeft then
            side = -1
        end
        if self.playerX+side > self.width or self.playerX+side < 1 then
            return false
        end
        local view_tile = self.grid[self.playerX+side][self.playerY] 
        if view_tile == "b" or view_tile == "a" or view_tile == "h" then
            self.carrying = view_tile -- pick up object from the next tile
            if self.carrying == "h" then
                local boat = self:getBoatIndex(self.playerX+side, self.playerY)
                if boat == 0 then
                    print("boat index not found, this should not happen!")
                    return
                end
                -- set boat position to 0,0 while carrying it
                self.boatIndex[boat]["x"] = 0
                self.boatIndex[boat]["y"] = 0
            end
            self.grid[self.playerX+side][self.playerY]  = ""
            if view_tile == "b" or view_tile == "h" then
                sounds.stone_pickup:setPitch(0.8+0.4*math.random())
                sounds.stone_pickup:play()
            elseif view_tile == "a" then
                sounds.sheep:setPitch(0.8+0.4*math.random())
                sounds.sheep:play()
            end
        end
        -- apply gravity in case something was pulled out from under stuff:
        self:applyGravity(self.playerX+side)

        if self.carrying ~= "" then
            return true
        end
    end
    return false
end

function Level:setDownObject()
    if self.carrying ~= "" then
        local whatDidWeCarry = self.carrying
        local side = 1
        local down = 0
        if self.playerLookingLeft then
            side = -1
        end
        if self.playerX+side > self.width or self.playerX+side < 1 then
            return false
        end
        local view_tile = self.grid[self.playerX+side][self.playerY] 
        if not self:isBlocked(self.playerX+side, self.playerY) then -- if there is room
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
                    local boat = self:getBoatIndex(self.playerX+side, self.playerY+down)
                    if boat == 0 then
                        print("boat index not found, this should not happen!")
                        return
                    end
                    local old_sheep_in_boat = self.boatIndex[boat]["sheep"]
                    self.boatIndex[boat]["sheep"] = old_sheep_in_boat + 1 
                    self.sheepCount = self.sheepCount - 1
                    self.sheepSaved = self.sheepSaved + 1
                    self.carrying = ""

                    sounds.sheep_happy:setPitch(0.5+math.random())
                    sounds.sheep_happy:play()

                else
                    -- don't put anything else on boat
                    return false
                    --self.grid[self.playerX+side][self.playerY+down-1] = self.carrying -- set down object on help
                    --self.carrying = ""
                end
            elseif view_down == "w" then
                if self.carrying == "h" then
                    self.grid[self.playerX+side][self.playerY+down-1] = self.carrying -- set down object on water
                    self.carrying = ""
                end
            end

            -- Play sound if we dropped something.
            if whatDidWeCarry == "b" or whatDidWeCarry == "h" then
                sounds.stone_put:setPitch(0.5+math.random())
                sounds.stone_put:play()
            elseif whatDidWeCarry == "a" then
                sounds.sheep_put:setPitch(0.5+math.random())
                sounds.sheep_put:play()
            end

        end
        if whatDidWeCarry == "h" and self.carrying == "" then
            local boat = self:getBoatIndex(0, 0)
            if boat == 0 then
                print("boat index not found, this should not happen!")
                return
            end
            -- update boat position in index
            self.boatIndex[boat]["x"] = self.playerX+side
            self.boatIndex[boat]["y"] = self.playerY+down-1
        end
        if self.carrying == "" then
            return true
        end
    end
    return false
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
                local boat = self:getBoatIndex(x, y+down)
                if boat == 0 then
                    print("boat index not found, this should not happen!")
                    return
                end
                if self:moveBoat(boat, x+1, y+down) then
                    self.grid[x][y+down] = "w"
                    self:applyGravity(x+1) -- let boat fall down
                elseif self:moveBoat(boat, x, (y-1)+down) then
                    self.grid[x][y+down] = "w"
                    self:applyGravity(x+1) -- let boat fall down
                end
            elseif tile == "w" and tile_below == "a" then
                self.grid[x][y] = ""
                self.grid[x][y+down] = tile
                self.sheepCount = self.sheepCount -1
                sounds.sheep_unhappy:setPitch(0.8+0.4*math.random())
                sounds.sheep_unhappy:play()
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

                    sounds.sheep_unhappy:setPitch(0.8+0.4*math.random())
                    sounds.sheep_unhappy:play()
                    self:loseLevel("Don't let your sheep get wet!")
                elseif tile == "w" and tile_below == "h" then
                    local boat = self:getBoatIndex(x, y+down)
                    if boat == 0 then
                        print("boat index not found, this should not happen!")
                        return
                    end
                    self.grid[x][y+down] = ""
                    self:moveBoat(boat, x, (y-1)+down)
                    self.grid[x][y] = ""
                    self.grid[x][y+down] = "w"
                elseif tile == "h" then
                    local boat = self:getBoatIndex(x, y)
                    if boat == 0 then
                        print("boat index not found, this should not happen!")
                        return
                    end
                    self.grid[x][y] = ""
                    self:moveBoat(boat, x, y+down-1)
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
            love.graphics.draw(images[sprite], pos_x, pos_y+(self.tileSize*0/16), 0, self.tileSize/16, self.tileSize/16, images[sprite]:getWidth()/2, images[sprite]:getHeight()/2)
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
            if tile == "l" then
                sprite = "water_wave_left"
            elseif tile == "d" then
                sprite = "water_overhang_down"
            elseif tile == "w" then
                local left = "w"
                local right = "w"
                local above = ""
                local below = "w"
                if x > 1 then
                    left = self.grid[x-1][y]
                end
                if x < self.width then
                    right = self.grid[x+1][y]
                end
                if y > 1 then
                    above = self.grid[x][y-1]
                end
                if y < self.height then
                    below = self.grid [x][y+1]
                end
                if (above == "" or above == "h") and (below == "" or below =="h") and (right == "" or right == "h") then
                    sprite = "water_wave_over"
                elseif (above == "" or above == "h") and (right == "" or right == "h") then
                    sprite = "water_wave"
                elseif (above == "" or above == "h") and (left == "" or left == "h") then
                    sprite = "water_wave_left"
                elseif (above == "" or above == "h") and right ~= "" and right ~= "h" then
                    sprite = "water_surface"
                elseif above ~= "" and above ~= "h" and (below == "" or below =="h") and (right == "" or right == "h" or right == "d") then
                    sprite = "water_overhang_right"
                elseif above ~= "" and above ~= "h" and (right == "" or right == "h") then
                    sprite = "water_side_right"
                elseif above ~= "" and above ~= "h" and (left == "" or left == "h") then
                    sprite = "water_side_left"
                else
                    sprite = "water"
                end
            elseif tile == "g" then
                local above = ""
                if y > 1 then
                     above = self.grid[x][y-1]
                end
                if above == "" or above == "a" or above == "h" or above == "b" then
                    sprite = "earth_surface"
                else
                    sprite = "earth"
                end
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
            if tile == "h" then
                local boat = self:getBoatIndex(x, y)
                if boat == 0 then
                    print("boat index not found, this should not happen!")
                    return
                end
                local sheep_on_boat = self.boatIndex[boat]["sheep"]
                if sheep_on_boat > 0 then
                    for i = 1, sheep_on_boat do
                        love.graphics.draw(images["sheep_mini"], 2*i*(self.tileSize/16) + self.tileSize*0.3 + self.offsetX + (x - 1) * self.tileSize,
                        2* (i%2)*self.tileSize/16 + self.offsetY + (y - 0.5) * self.tileSize, 0, self.tileSize / 16,
                        self.tileSize / 16, images["sheep_mini"]:getWidth()/2, images["sheep_mini"]:getHeight()/2)
                    end
                end
            end
        end
    end
end


function Level:draw(includeTitle)
    if includeTitle == nil then
        includeTitle = true
    end

    self:drawGrid()
    self:drawPlayer()
    if self.lost then
        local lostMessage = self.lostMessage.."\nPress "..Input:getKeyString("reset").." to restart\nor "..Input:getKeyString("back").." to undo one step."
        dimRect()
        love.graphics.printf(lostMessage, 0, CANVAS_HEIGHT/2, CANVAS_WIDTH, "center")
    end

    if includeTitle then
        local gap = CANVAS_HEIGHT/16
        love.graphics.setFont(bigfont)
        love.graphics.printf(self.name, gap, gap, CANVAS_WIDTH-2*gap, "right")
    end

    if (self.started == false and self.intro ~= nil) then
        dimRect()
        love.graphics.printf(self.intro, CANVAS_WIDTH/8, CANVAS_HEIGHT*1/4, CANVAS_WIDTH-CANVAS_WIDTH/4, "center")
    elseif self.won == true then
        dimRect()
        love.graphics.printf(self.outro, 0, CANVAS_HEIGHT/2, CANVAS_WIDTH, "center")
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
        --levels[levelManager.current - 1].won = false
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
