local scene = {} 

function scene:enter()
    self.child_rotation = 0
    self.child_x = CANVAS_WIDTH / 2
    self.child_y = CANVAS_HEIGHT / 2
end

function scene:update(dt)
    self.child_rotation = self.child_rotation+dt*2
    self.child_x = self.child_x + input:getX() * 10
    self.child_y = self.child_y + input:getY() * 10
end

function scene:draw()
    love.graphics.setColor(1, 1, 1) --white

    love.graphics.draw(images.child, self.child_x, self.child_y, self.child_rotation, 1, 1, images.child:getWidth()/2, images.child:getHeight()/2)
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