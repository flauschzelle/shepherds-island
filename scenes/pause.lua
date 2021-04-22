local scene = {} 

function scene:draw()
    love.graphics.setColor(1, 1, 1) --white
    love.graphics.printf("PAUSED", 0, CANVAS_HEIGHT/2, CANVAS_WIDTH, "center")
end

function scene:handleInput()
    if input:isPressed("pause") then
        roomy:pop()
    end
end

function scene:enter()
    love.mouse.setRelativeMode(false)
end

function scene:leave()
    love.mouse.setRelativeMode(true)
end

return scene