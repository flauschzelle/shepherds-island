local scene = {}

function scene:enter()
    -- set up player cursor:
    -- self.child_rotation = 0
    -- level_grid_cols = levelManager.currentLevel().width
    -- level_grid_rows = levelManager.currentLevel().height
    -- level_grid_margins_x = levelManager.currentLevel().offsetX
    -- level_grid_margins_y = levelManager.currentLevel().offsetY
    -- self.player = Cursor:new("image", "stop", levelManager.currentLevel().playerX, levelManager.currentLevel().playerY, 50, level_grid_cols, level_grid_rows, {top = level_grid_margins_y, bottom = level_grid_margins_y, left = level_grid_margins_x, right = level_grid_margins_x}, "center", "center")
    -- self.player:setImage(images.child)
    self.muted = false
    self.music = music.bleeping_demo
    self.music:play()
end

function scene:pause()
    self.musicPosition = self.music:tell()
    self.music:pause()
end

function scene:leave()
    self.music:stop()
end

function scene:resume()
    self.music:stop()
    self.music:play()
    print ("Music position: " .. self.musicPosition)
    self.music:seek(self.musicPosition)
end

function scene:update(dt)
    -- update player cursor:
    --self.child_rotation = self.child_rotation+dt*2
    --self.player:setImageRotation(self.child_rotation)
    --self.player:move()
    -- update level:
    levelManager.currentLevel():update(dt)
end

function scene:draw()
    love.graphics.clear(0, 0, 0)
    love.graphics.setColor(1, 1, 1) --white

    levelManager.currentLevel():draw()
    --self.player:draw()
end

function scene:handleInput()
    if input:isPressed("click") then
        if levelManager.currentLevel().started == false then
            -- start level from intro
            levelManager.currentLevel():start()
            return
        elseif levelManager.currentLevel():isWon() then
            local next = nextLevel() -- starts the next level and returns true, or false if there is no next level
            if next then
                return
            else
                roomy:enter(scenes.credits) -- show credits screen
            end
        end
    end

    if input:isPressed("quit") then
        roomy:push(scenes.menu)
    end

    if input:isPressed("mute") then
        self.muted = not self.muted
        if self.muted then
            self.music:pause()
        else
            self.music:play()
        end
    end

    -- cheat to win current level
    if input:isPressed("cheat") then
        levelManager.currentLevel().won = true
    end

    -- actual level controls:
    if levelManager.currentLevel().started == true then
        local lvl = levelManager.currentLevel()
        if lvl.lost == false and lvl.won == false and input:isPressed("left") then
            local didMove = true
            if lvl.playerLookingLeft then
                --go left
                didMove = lvl:movePlayer(-1, 0)
            else 
                lvl.playerLookingLeft = true
            end
            if didMove then
                lvl:nextState()
            end
        end
        if lvl.lost == false and lvl.won == false and input:isPressed("right") then
            local didMove = true
            if lvl.playerLookingLeft then
                lvl.playerLookingLeft = false
            else
                --go right
                didMove = lvl:movePlayer(1, 0)
            end
            if didMove then
                lvl:nextState()
            end
        end
        if input:isPressed("wait") then
             lvl:nextState()
        end
        if lvl.lost == false and lvl.won == false and input:isPressed("pickup") then
            local didMove = true
            if lvl.carrying == "" then
                didMove = lvl:liftObject()
            else 
                didMove = lvl:setDownObject()
            end
            if didMove then
                lvl:nextState()
            end
        end
        if lvl.won == false and input:isPressed("back") then
            lvl:popState()
        end
        if lvl.won == false and input:isPressed("reset") then
            lvl:popState(true) -- restart = true
        end
    end
end

return scene
