local scene = {} 

function scene:enter()
    self.child_rotation = 0
    self.player = Cursor:new("image", "stop")
    self.player:setImage(images.child)

end

function scene:update(dt)
    self.child_rotation = self.child_rotation+dt*2
    self.player:setImageRotation(self.child_rotation)
    self.player:move()
end

function scene:draw()
    love.graphics.setColor(1, 1, 1) --white

    self.player:draw()
end

function scene:handleInput()
    if input:isPressed("click") then
        sounds.meow:setPitch(0.5+math.random())
        sounds.meow:play()
    end
    if input:isPressed("pause") then
        roomy:push(scenes.pause)
    end
end

return scene