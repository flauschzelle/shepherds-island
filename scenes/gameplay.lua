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
    self.music = music.ambient_starfield
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
    love.graphics.clear(65/255, 166/255, 246/255) -- Sweetie 16 light blue
    love.graphics.setColor(1, 1, 1) --white

    levelManager.currentLevel():draw()
    --self.player:draw()
end

function scene:handleInput()
    if input:isPressed("click") then
        if levelManager.currentLevel().started == false then
            -- start level from intro
            levelManager.currentLevel():start()
        elseif levelManager.currentLevel():isWon() then
            if nextLevel() == false then    -- goes to next level if there is one
                roomy:enter(scenes.credits) -- show credits screen
            end
        else
        -- gameplay stuff
            sounds.meow:setPitch(0.5+math.random())
            sounds.meow:play()
        end
    end

    if input:isPressed("pause") then
        roomy:push(scenes.pause)
    end

    if input:isPressed("menu") then
        roomy:push(scenes.menu)
    end

    -- cheat to win current level
    if input:isPressed("cheat") then
        levelManager.currentLevel().won = true
    end

    -- actual level controls:
    if levelManager.currentLevel().started == true then
        local lvl = levelManager.currentLevel()
        if input:isPressed("left") then
            if lvl.playerLookingLeft then
                --go left
                lvl:movePlayer(-1, 0)
            else 
                lvl.playerLookingLeft = true
            end
        end
        if input: isPressed("right") then
            if lvl.playerLookingLeft then
                lvl.playerLookingLeft = false
            else
                --go right
                lvl:movePlayer(1, 0)
            end
        end
        if input:isPressed("up") then
            -- pick up thing
            lvl:liftObject()
        end
        if input:isPressed("down") then
            -- put down thing
            lvl:setDownObject()
        end
    end

end

return scene
