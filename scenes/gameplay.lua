local scene = {} 

function scene:enter()
    self.child_rotation = 0
end

function scene:update(dt)
    self.child_rotation = self.child_rotation+dt*2
end

function scene:draw()
    love.graphics.setColor(1, 1, 1) --white

    x, y = love.mouse.getPosition()

    love.graphics.draw(images.child, x, y, self.child_rotation, 1, 1, images.child:getWidth()/2, images.child:getHeight()/2)
end

function scene:mousepressed(x, y, button)
    sounds.meow:setPitch(0.5+math.random())
    sounds.meow:play()
end

function scene:keypressed(key)
    if key == "p" then
        roomy:push(scenes.pause)
    end
end

return scene