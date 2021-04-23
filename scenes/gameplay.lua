local scene = {}

function scene:enter()
    -- set up player cursor:
    self.child_rotation = 0
    self.player = Cursor:new("image", "stop")
    self.player:setImage(images.child)
    self.music = music.ambient_starfield
    self.music:play()
end

function scene:pause()
    self.musicPosition = self.music:tell()
    self.music:pause()
end

function scene:resume()
    self.music:stop()
    self.music:play()
    print ("Music position: " .. self.musicPosition)
    self.music:seek(self.musicPosition)
end

function scene:update(dt)
    -- update player cursor:
    self.child_rotation = self.child_rotation+dt*2
    self.player:setImageRotation(self.child_rotation)
    self.player:move()
end

function scene:draw()
    love.graphics.setColor(1, 1, 1) --white

    levelManager.currentLevel():draw()
    self.player:draw()
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
end

return scene
